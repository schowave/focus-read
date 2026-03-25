# Platform-Adaptive UI & Startup Optimization

**Date:** 2026-03-25
**Status:** Approved

## Problem

The app feels laggy and non-native on iOS. Screen transitions, startup time, and general look & feel don't match iOS user expectations. The app uses Material 3 widgets exclusively, which feel foreign on iOS.

## Goals

1. On iOS, the app should feel like a native iOS app (Cupertino widgets, transitions, scroll physics)
2. On Android, the app continues to use Material 3
3. One codebase, two platform-native looks
4. Faster app startup by bundling fonts instead of downloading them at runtime
5. Seamless splash-to-app transition on iOS

## Non-Goals

- Rewriting app logic or state management
- Changing the database layer or OCR pipeline
- Adding new features

## Design

### 1. Adaptive Widget Layer

New directory `lib/shared/adaptive/` with wrapper widgets that render Cupertino on iOS, Material on Android:

| Widget | iOS | Android |
|--------|-----|---------|
| `AdaptiveApp` | `CupertinoApp.router` | `MaterialApp.router` |
| `AdaptiveScaffold` | `CupertinoPageScaffold` + `CupertinoNavigationBar` | `Scaffold` + `AppBar` |
| `AdaptiveSlider` | `CupertinoSlider` | `Slider` |
| `AdaptiveSwitch` | `CupertinoSwitch` | `Switch` |
| `AdaptiveDialog` | `CupertinoAlertDialog` | `AlertDialog` |
| `AdaptiveButton` | `CupertinoButton` | `ElevatedButton` / `TextButton` |
| `AdaptiveTextField` | `CupertinoTextField` | `TextField` |

Each widget checks `Platform.isIOS` and renders accordingly. The API is unified so screens only use adaptive widgets.

### 2. Navigation & Transitions

- GoRouter gets a helper function `adaptivePage()` that returns `CupertinoPage` on iOS and `MaterialPage` on Android
- Route definitions remain unchanged — only the page wrapper changes
- iOS scroll physics (`BouncingScrollPhysics`) come automatically via `CupertinoApp`
- Swipe-back navigation is native to `CupertinoPage`

### 3. Theming Strategy

**Two theme paths, one color palette:**

- **Android:** Full Material 3 Leseecke theme (Terracotta, Cream, Sage) via `ThemeData`
- **iOS:** `CupertinoThemeData` with limited color mapping:
  - `primaryColor` → Terracotta
  - `scaffoldBackgroundColor` → Warm Cream (#FFF8F0)
  - `barBackgroundColor` → Standard iOS blur (native, not customized)
  - Navigation bar title color → Warm Brown

**Shared colors** stay in `theme.dart` as constants (`LeseeckeColors`), accessible to both themes. Cards, word overlays, and custom widgets use these colors directly.

Fonts (Quicksand + Nunito) remain the same on both platforms.

### 4. Font Bundling & App Startup

**Current:** `google_fonts` package downloads Quicksand + Nunito over the network at runtime.

**New:**
- Bundle Quicksand + Nunito font files in `assets/fonts/`
- Declare in `pubspec.yaml` under `fonts:` section
- Remove `google_fonts` dependency
- Update theme references from `GoogleFonts.quicksand()` to `TextStyle(fontFamily: 'Quicksand')`
- Set iOS `LaunchScreen.storyboard` background to Warm Cream (#FFF8F0) for seamless splash-to-app transition

### 5. Screen Changes

| Screen | Changes |
|--------|---------|
| **LibraryScreen** | `Scaffold` → `AdaptiveScaffold`, dialogs → `AdaptiveDialog` |
| **BookScreen** | `Scaffold` → `AdaptiveScaffold`, delete dialog adaptive |
| **CaptureScreen** | `Scaffold` → `AdaptiveScaffold`, success dialog → `AdaptiveDialog` |
| **ReaderScreen** | `Scaffold` → `AdaptiveScaffold`, ControlBar stays custom |
| **SettingsScreen** | Biggest change — iOS uses `CupertinoListSection` + `CupertinoListTile`, `AdaptiveSlider`, `AdaptiveSwitch` |

**Remains custom on both platforms (no native equivalent):**
- Word overlays in Reader
- ControlBar (word navigation)
- Book/Page grid cards (Leseecke colors)
- Camera preview + shutter button

### 6. File Changes Summary

**New files (~8):**
- `lib/shared/adaptive/adaptive_app.dart`
- `lib/shared/adaptive/adaptive_scaffold.dart`
- `lib/shared/adaptive/adaptive_slider.dart`
- `lib/shared/adaptive/adaptive_switch.dart`
- `lib/shared/adaptive/adaptive_dialog.dart`
- `lib/shared/adaptive/adaptive_button.dart`
- `lib/shared/adaptive/adaptive_text_field.dart`
- `lib/shared/adaptive/platform_utils.dart`

**Modified files (~10):**
- `lib/app/app.dart` — swap `MaterialApp.router` for `AdaptiveApp`
- `lib/app/router.dart` — `adaptivePage()` helper
- `lib/app/theme.dart` — extract `LeseeckeColors`, add `CupertinoThemeData`
- `lib/features/library/library_screen.dart`
- `lib/features/book/book_screen.dart`
- `lib/features/capture/capture_screen.dart`
- `lib/features/reader/reader_screen.dart`
- `lib/features/settings/settings_screen.dart`
- `lib/shared/confirm_dialog.dart` — use `AdaptiveDialog`
- `pubspec.yaml` — remove `google_fonts`, add font assets

**Asset additions:**
- `assets/fonts/Quicksand-*.ttf`
- `assets/fonts/Nunito-*.ttf`

**iOS native:**
- `ios/Runner/Base.lproj/LaunchScreen.storyboard` — background color
