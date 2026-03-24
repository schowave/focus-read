# Focus Read — Flutter App Design Spec

## Overview

Native Flutter app that wraps the existing Focus Read concept (photograph a book page, OCR it, read word-by-word with highlighting and TTS) into a standalone mobile app for iOS and Android, publishable in both stores.

**Key decisions:**
- Completely on-device — no backend server required
- Google ML Kit for OCR (replaces docTR)
- Start as a private/personal app, built cleanly enough to go public later
- Designed for children ages 4-10, with age-adaptive UI

## Screen Flow

```
Splash → Home (Library)
            ├── Create/Open Book → Book Detail (Page List)
            │                         ├── Add Page (Camera / Gallery)
            │                         └── Open Page → Reader Screen
            │                                          ├── Word Navigation (Tap/Swipe)
            │                                          ├── TTS Read-Aloud
            │                                          └── Back to Page List
            └── Settings
                 ├── App Language
                 ├── TTS Speed / Voice
                 ├── Age Group
                 └── OCR Language
```

## Architecture

### Project Structure

```
lib/
├── app/                    # App shell, routing, theme
├── features/
│   ├── library/            # Library (book list grid)
│   ├── book/               # Book detail (page list grid)
│   ├── capture/            # Camera & gallery, OCR processing
│   ├── reader/             # Reader screen, word navigation, highlighting
│   └── settings/           # Settings screen
├── core/
│   ├── ocr/                # ML Kit integration + post-processing
│   ├── tts/                # Text-to-speech abstraction
│   ├── storage/            # Local database (Drift/SQLite)
│   └── l10n/               # Localization (arb files)
```

### Tech Stack

| Concern | Choice |
|---|---|
| Framework | Flutter (stable channel) |
| State Management | Riverpod |
| Database | Drift (SQLite) |
| Camera | `camera` (official plugin) |
| OCR | `google_mlkit_text_recognition` |
| TTS | `flutter_tts` |
| Routing | `go_router` |
| Min iOS | 16.0 |
| Min Android | API 24 (Android 7.0) |

## Data Model

### Book

| Field | Type | Description |
|---|---|---|
| id | String (UUID) | Primary key |
| title | String | Book title |
| language | String | OCR/TTS language code (e.g. "de", "en") |
| coverImagePath | String? | Path to cover image (first page or custom) |
| createdAt | DateTime | |
| updatedAt | DateTime | |

### Page

| Field | Type | Description |
|---|---|---|
| id | String (UUID) | Primary key |
| bookId | String | Foreign key to Book |
| pageNumber | int | Order within book |
| imagePath | String | Local file path to photo |
| imageWidth | int | Image dimensions |
| imageHeight | int | |
| ocrCompleted | bool | Whether OCR has been run |
| createdAt | DateTime | |

### Word

| Field | Type | Description |
|---|---|---|
| id | String (UUID) | Primary key |
| pageId | String | Foreign key to Page |
| text | String | Recognized word |
| x | double | Bounding box position in absolute pixels |
| y | double | |
| w | double | Bounding box size in absolute pixels |
| h | double | |
| confidence | double | 0.0 - 1.0 |
| sortIndex | int | Reading order (top-left to bottom-right) |

### Settings (Singleton)

| Field | Type | Default |
|---|---|---|
| appLanguage | String | "de" |
| ocrLanguage | String | Book language |
| ttsSpeed | double | 0.8 |
| ttsEnabled | bool | true |
| ageGroup | enum | earlyPrimary |
| confidenceThreshold | double | 0.85 |

## Reader Screen (Core Feature)

### Layout

```
┌─────────────────────────────┐
│  ← Back          Page 3/12  │  Header (subtle)
│─────────────────────────────│
│                             │
│    ┌───────────────────┐    │
│    │                   │    │
│    │   Book page image │    │
│    │   with word       │    │
│    │   overlays        │    │
│    │                   │    │
│    └───────────────────┘    │
│                             │
│─────────────────────────────│
│  🔊  ◄ "Waschbär"  ►  3/47 │  Control bar
└─────────────────────────────┘
```

### Word Highlighting

- **Active word:** Warm color highlight with smooth animation on transition
- **Other words:** Dimmed with semi-transparent overlay (intensity varies by age group)
- **Already-read words:** Subtly different from unread (progress indicator)

### Navigation Gestures

| Gesture | Action |
|---|---|
| Tap active word | Next word |
| Tap other word | Jump to that word |
| Swipe left/right | Previous/next word |
| Pinch | Zoom |
| Two-finger pan | Pan image |

Auto-scroll/zoom to keep active word visible on word change.

### Age Group Adaptations

| Aspect | Preschool (4-6) | Early Primary (6-8) | Late Primary (8-10) |
|---|---|---|---|
| Button size | Extra large | Large | Normal |
| Word highlight | Very strong, large marker | Clear | Subtler |
| Inactive words | Heavily dimmed | Lightly dimmed | Visible, subtle |
| Auto read-aloud | Always on | On (toggleable) | Off (toggleable) |

### Edge Cases

- **No words recognized:** Show hint "No words found — try photographing again?" with camera button
- **Low confidence:** Words below threshold are filtered out (threshold adjustable in settings)
- **Last word on page:** Offer "Next page →" action or return to page list

## Capture Flow

```
Add Page (button in Book Detail)
    ├── Open Camera (in-app)
    │     ├── Take photo
    │     ├── Preview: "Is the text readable?"
    │     │     ├── Yes → Start OCR
    │     │     └── Retake → back to camera
    │     └── OCR running (loading animation)
    │           ├── Success → page saved, open Reader
    │           └── No words found → hint + retry
    └── Choose from Gallery
          └── Image selected → Start OCR (same flow)
```

### Camera Screen

- Live preview, full-screen
- Large shutter button (child-friendly)
- Flash toggle (Auto/On/Off)
- No crop/edit step — keep it simple for children
- Permission denied: show explanation dialog with button to open device Settings

### OCR Processing

- Google ML Kit Text Recognition v2, on-device
- Loading animation during OCR (<1s on modern devices)
- Post-processing (ported from existing Python logic):
  - Confidence filter (default 85%). Fallback: if ML Kit plugin does not expose word-level confidence, set confidence to 1.0 and rely solely on noise filter heuristics.
  - Noise filter: remove single characters (except "a", "i", "o"), pure numbers, special characters, mixed alpha+digit strings (e.g. "h3llo"), abbreviation-like patterns (e.g. "w.w")
  - Reading order: use ML Kit's native TextLine grouping. Sort lines by Y midpoint, elements within each line by X position.

### Batch Scanning

After successful OCR: offer "Add another page?" so users can scan a whole book without navigating back each time.

## Library & Book Management

### Home Screen (Library)

- Grid view with book covers (first page image as cover)
- Book title + page count below each cover
- "+" card to create new book
- Long-press → context menu: Rename, Change Language, Delete

### New Book Flow

1. Enter title (optional — defaults to "Book 1", "Book 2", ...)
2. Choose language (picker with common languages, default = app language)
3. → Directly into camera flow for first page

### Book Detail (Page List)

- Grid with page thumbnails
- Page number + word count as info
- Tap → open Reader
- Long-press → Delete page, Re-scan
- Drag & drop to reorder pages (nice-to-have, lower priority for v1)
- "+📷" button top-right → add new page

### Delete Confirmation

All destructive actions require confirmation dialog — especially important since children operate the app.

## Localization

- Mechanism: Flutter `intl` / `.arb` files
- Initial UI languages: German, English
- OCR languages: All ML Kit Latin languages (DE, EN, FR, ES, PT, IT, NL, ...)
- TTS languages: Depends on device-installed voices — app only shows languages with available voice. If no TTS voice is available for a book's language, disable TTS automatically and show a hint to install the language pack in device settings.

## Store Publication

### Apple App Store

- Apple Developer Account required (99$/year)
- Children's app category: strict rules (COPPA, no ads, no external links, no tracking)
- Age rating: 4+ (no objectionable content)
- Privacy Policy required (simple: "We collect no data")
- Screenshots for iPhone + iPad

### Google Play Store

- Google Developer Account (one-time 25$)
- "Designed for Families" program recommended
- Similar children's protection requirements
- Privacy Policy required
- AAB format (App Bundles)

### Image Storage

- Images stored in app documents directory (`getApplicationDocumentsDirectory`)
- Compress to ~1080p JPEG on capture to manage storage
- Delete image file when page or book is deleted

### Privacy

- No tracking, no analytics, no ads, no in-app purchases
- All data stays locally on device
- No network requests at all (fully offline)
- Simplifies store review process significantly

## Out of Scope (YAGNI)

- No user accounts / login
- No cloud sync
- No ads / in-app purchases
- No analytics / tracking
- No social sharing
- No gamification / reading progress tracking
- No backend server
- No custom OCR model training

## Open Questions

1. **ML Kit confidence in Flutter:** The Flutter plugin's exposure of word-level confidence scores needs verification with the current plugin version. Test early.
2. **ML Kit on Huawei:** ML Kit requires Google Play Services — Huawei devices without GMS cannot use the app. Acceptable trade-off for now.
3. **Decorative fonts:** ML Kit's accuracy on decorative/handwritten children's book fonts is unknown. Test with real book photos before committing.
