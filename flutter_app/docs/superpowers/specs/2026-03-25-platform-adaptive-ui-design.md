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
| `AdaptiveApp` | `CupertinoApp.router` (with Material `Theme` injected via `builder:`) | `MaterialApp.router` |
| `AdaptiveScaffold` | `CupertinoPageScaffold` + `CupertinoNavigationBar` (with explicit safe area handling) | `Scaffold` + `AppBar` |
| `AdaptiveSlider` | `CupertinoSlider` | `Slider` |
| `AdaptiveSwitch` | `CupertinoSwitch` | `Switch` |
| `AdaptiveDialog` | `CupertinoAlertDialog` | `AlertDialog` |
| `AdaptiveActionSheet` | `CupertinoActionSheet` | `showModalBottomSheet` + `ListTile` |
| `AdaptiveButton` | `CupertinoButton` | `ElevatedButton` / `TextButton` |
| `AdaptiveTextField` | `CupertinoTextField` | `TextField` |
| `AdaptiveProgressIndicator` | `CupertinoActivityIndicator` | `CircularProgressIndicator` |

**Platform detection:** All widgets use `defaultTargetPlatform == TargetPlatform.iOS` from `package:flutter/foundation.dart` (NOT `dart:io` `Platform.isIOS`) to ensure compatibility with web and tests.

### 2. Navigation & Transitions

- GoRouter routes switch from `builder:` to `pageBuilder:` using an `adaptivePage()` helper that returns `CupertinoPage` on iOS and `MaterialPage` on Android
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

**Critical: Material Theme under CupertinoApp.** `CupertinoApp.router` does not provide a Material `Theme` ancestor. Since the app still uses Material widgets (Card, etc.) in custom components, `AdaptiveApp` must inject a Material `Theme` widget via the `builder:` parameter on iOS. This ensures `Theme.of(context)` calls continue to work.

**Shared colors** stay in `theme.dart` as constants (`LeseeckeColors`), accessible to both themes. Cards, word overlays, and custom widgets use these colors directly.

**Localization delegates:** Both platform paths include all four delegates (`GlobalMaterialLocalizations`, `GlobalWidgetsLocalizations`, `GlobalCupertinoLocalizations`, app-specific) since Material widgets are still used within the Cupertino shell.

Fonts (Quicksand + Nunito) remain the same on both platforms.

### 4. Font Bundling & App Startup

**Current:** `google_fonts` package downloads Quicksand + Nunito over the network at runtime.

**New:**
- Bundle Quicksand + Nunito font files in `assets/fonts/` (OFL license files included)
- Declare in `pubspec.yaml` under `fonts:` section
- Remove `google_fonts` dependency
- Update theme references from `GoogleFonts.quicksand()` to `TextStyle(fontFamily: 'Quicksand')`
- Set iOS `LaunchScreen.storyboard` background to Warm Cream (#FFF8F0) for seamless splash-to-app transition

### 5. Screen Changes

| Screen | Changes |
|--------|---------|
| **LibraryScreen** | `Scaffold` → `AdaptiveScaffold`, `showModalBottomSheet` → `AdaptiveActionSheet`, `CircularProgressIndicator` → `AdaptiveProgressIndicator` |
| **BookScreen** | `Scaffold` → `AdaptiveScaffold`, `showModalBottomSheet` → `AdaptiveActionSheet`, delete dialog adaptive, `CircularProgressIndicator` → `AdaptiveProgressIndicator` |
| **CaptureScreen** | `Scaffold` → `AdaptiveScaffold`, success dialog → `AdaptiveDialog`, snackbars → keep internal `Scaffold` wrapper for `ScaffoldMessenger` support on iOS, `CircularProgressIndicator` → `AdaptiveProgressIndicator` |
| **ReaderScreen** | `Scaffold` → `AdaptiveScaffold` (with explicit safe area for ControlBar on notched devices), ControlBar stays custom, `CircularProgressIndicator` → `AdaptiveProgressIndicator` |
| **SettingsScreen** | Biggest change — iOS uses `CupertinoListSection` + `CupertinoListTile`, `AdaptiveSlider`, `AdaptiveSwitch`. Selection dialogs (language, age group) use `CupertinoActionSheet` on iOS instead of `SimpleDialog` |
| **CreateBookDialog** | `AlertDialog` → `AdaptiveDialog`, `TextField` → `AdaptiveTextField`, buttons → `AdaptiveButton`, `DropdownButtonFormField` → adaptive picker |

**Remains custom on both platforms (no native equivalent):**
- Word overlays in Reader
- ControlBar (word navigation)
- Book/Page grid cards (Leseecke colors)
- Camera preview + shutter button

### 6. File Changes Summary

**New files (~10):**
- `lib/shared/adaptive/adaptive_app.dart`
- `lib/shared/adaptive/adaptive_scaffold.dart`
- `lib/shared/adaptive/adaptive_slider.dart`
- `lib/shared/adaptive/adaptive_switch.dart`
- `lib/shared/adaptive/adaptive_dialog.dart`
- `lib/shared/adaptive/adaptive_action_sheet.dart`
- `lib/shared/adaptive/adaptive_button.dart`
- `lib/shared/adaptive/adaptive_text_field.dart`
- `lib/shared/adaptive/adaptive_progress_indicator.dart`
- `lib/shared/adaptive/platform_utils.dart`

**Modified files (~12):**
- `lib/app/app.dart` — swap `MaterialApp.router` for `AdaptiveApp`
- `lib/app/router.dart` — switch to `pageBuilder:` with `adaptivePage()` helper
- `lib/app/theme.dart` — extract `LeseeckeColors`, add `CupertinoThemeData`
- `lib/features/library/library_screen.dart`
- `lib/features/book/book_screen.dart`
- `lib/features/book/create_book_dialog.dart`
- `lib/features/capture/capture_screen.dart`
- `lib/features/reader/reader_screen.dart`
- `lib/features/reader/control_bar.dart`
- `lib/features/settings/settings_screen.dart`
- `lib/shared/confirm_dialog.dart` — use `AdaptiveDialog`
- `pubspec.yaml` — remove `google_fonts`, add font assets

**Asset additions:**
- `assets/fonts/Quicksand-*.ttf`
- `assets/fonts/Nunito-*.ttf`
- `assets/fonts/OFL.txt` (license)

**iOS native:**
- `ios/Runner/Base.lproj/LaunchScreen.storyboard` — background color

### 7. Verification

- Run on iOS Simulator: verify each screen renders with Cupertino widgets, transitions are native slide-from-right, swipe-back works
- Run on Android Emulator: verify Material 3 look is preserved
- Verify fonts load instantly without network (airplane mode test)
- Verify iOS splash → app transition has no white flash
