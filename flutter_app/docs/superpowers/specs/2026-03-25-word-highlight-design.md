# Improved Word Highlighting with Focus Intensity

**Date:** 2026-03-25
**Status:** Approved

## Problem

The current word overlay in the Reader is too subtle — the active word doesn't stand out enough and the other words aren't dimmed enough to create a clear reading focus.

## Goals

1. Active word gets a stronger visual highlight (spotlight + color)
2. Unread and read words are more clearly dimmed
3. New setting "Focus Intensity" (0–100%) to control how strong the effect is
4. AgeGroup presets set the default intensity, but users can override manually

## Design

### Overlay Logic

Per-word overlays (not full-page). The `focusIntensity` value (0.0–1.0) controls all three states:

- **Active word:** `AppColors.activeWord.withAlpha(0.3 + intensity * 0.5)` (range 0.3–0.8) + yellow border (unchanged)
- **Unread words:** `Colors.white.withAlpha(intensity * 0.7)` (range 0–0.7)
- **Read words:** `Colors.white.withAlpha(intensity * 0.85)` (range 0–0.85)

### Focus Intensity Setting

New field `focusIntensity` (double, 0.0–1.0) in `AppSettings`, persisted via SharedPreferences.

**AgeGroup defaults:**
- Preschool: 0.85
- Early Primary: 0.6
- Late Primary: 0.35

When user changes AgeGroup, `focusIntensity` is reset to the AgeGroup's default value. Manual slider adjustments persist until the next AgeGroup change.

### Settings Screen

New "Reading" section (between "Text-to-Speech" and "Advanced") with a single slider:
- Label: "Focus Intensity"
- Shows percentage (0–100%)
- Range: 0.0–1.0, 20 divisions

### Cleanup

Remove `dimOpacity` and `highlightOpacity` from `AgeGroupConfig` in `models.dart` — replaced by `focusIntensity` from Settings.

## File Changes

| File | Changes |
|------|---------|
| `lib/shared/models.dart` | Remove `dimOpacity` and `highlightOpacity` from `AgeGroupConfig` |
| `lib/features/settings/settings_provider.dart` | Add `focusIntensity` field, persistence, reset on AgeGroup change |
| `lib/features/settings/settings_screen.dart` | Add "Reading" section with Focus Intensity slider |
| `lib/features/reader/word_overlay.dart` | New overlay color logic using `focusIntensity` |
| `lib/features/reader/reader_screen.dart` | Pass `focusIntensity` from settings to WordOverlay instead of `dimOpacity` |
