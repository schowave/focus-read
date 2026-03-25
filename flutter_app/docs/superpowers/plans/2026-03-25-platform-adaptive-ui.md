# Platform-Adaptive UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the app feel native on iOS (Cupertino widgets, transitions, scroll physics) while keeping Material 3 on Android, and speed up startup by bundling fonts.

**Architecture:** Thin adaptive wrapper widgets in `lib/shared/adaptive/` that check `defaultTargetPlatform` and delegate to Cupertino or Material. Screens swap Material widgets for adaptive equivalents. GoRouter uses `pageBuilder:` with platform-specific page types. Fonts bundled as assets instead of fetched at runtime.

**Tech Stack:** Flutter 3.41.4, Cupertino widgets, GoRouter, Riverpod, bundled TTF fonts

**Spec:** `docs/superpowers/specs/2026-03-25-platform-adaptive-ui-design.md`

---

## File Structure

### New files

| File | Responsibility |
|------|---------------|
| `lib/shared/adaptive/platform_utils.dart` | `bool isIOS` getter using `defaultTargetPlatform`, reused by all adaptive widgets |
| `lib/shared/adaptive/adaptive_app.dart` | Root app widget: `CupertinoApp.router` (with Material Theme injected) on iOS, `MaterialApp.router` on Android |
| `lib/shared/adaptive/adaptive_scaffold.dart` | `CupertinoPageScaffold` + `CupertinoNavigationBar` on iOS, `Scaffold` + `AppBar` on Android |
| `lib/shared/adaptive/adaptive_dialog.dart` | `showAdaptiveConfirmDialog()` and `showAdaptiveAlertDialog()` — Cupertino on iOS, Material on Android |
| `lib/shared/adaptive/adaptive_action_sheet.dart` | `showAdaptiveActionSheet()` — `CupertinoActionSheet` on iOS, `showModalBottomSheet` on Android |
| `lib/shared/adaptive/adaptive_button.dart` | `AdaptiveFilledButton` and `AdaptiveTextButton` wrappers |
| `lib/shared/adaptive/adaptive_text_field.dart` | `AdaptiveTextField` — `CupertinoTextField` on iOS, `TextField` on Android |
| `lib/shared/adaptive/adaptive_slider.dart` | `AdaptiveSlider` — `CupertinoSlider` on iOS, `Slider` on Android |
| `lib/shared/adaptive/adaptive_switch.dart` | `AdaptiveSwitch` — `CupertinoSwitch` on iOS, `Switch` on Android |
| `lib/shared/adaptive/adaptive_progress_indicator.dart` | `AdaptiveProgressIndicator` — `CupertinoActivityIndicator` on iOS, `CircularProgressIndicator` on Android |
| `assets/fonts/Quicksand-Regular.ttf` | Bundled font file |
| `assets/fonts/Quicksand-Medium.ttf` | Bundled font file |
| `assets/fonts/Quicksand-SemiBold.ttf` | Bundled font file |
| `assets/fonts/Quicksand-Bold.ttf` | Bundled font file |
| `assets/fonts/Nunito-Regular.ttf` | Bundled font file |
| `assets/fonts/Nunito-SemiBold.ttf` | Bundled font file |
| `assets/fonts/Nunito-Bold.ttf` | Bundled font file |
| `assets/fonts/OFL-Quicksand.txt` | Font license |
| `assets/fonts/OFL-Nunito.txt` | Font license |

### Modified files

| File | Changes |
|------|---------|
| `pubspec.yaml` | Remove `google_fonts`, add `fonts:` declarations |
| `lib/app/theme.dart` | Extract `AppColors` (rename from existing), replace `GoogleFonts.*` with `TextStyle(fontFamily:)`, add `CupertinoThemeData` builder |
| `lib/app/app.dart` | Replace `MaterialApp.router` with `AdaptiveApp` |
| `lib/app/router.dart` | Switch all routes from `builder:` to `pageBuilder:` with `adaptivePage()` |
| `lib/shared/confirm_dialog.dart` | Use `showAdaptiveConfirmDialog` |
| `lib/features/library/library_screen.dart` | Use `AdaptiveScaffold`, `AdaptiveActionSheet`, `AdaptiveProgressIndicator`, adaptive dialogs |
| `lib/features/book/book_screen.dart` | Use `AdaptiveScaffold`, `AdaptiveActionSheet`, `AdaptiveProgressIndicator` |
| `lib/features/book/create_book_dialog.dart` | Adaptive dialog, text field, buttons, language picker |
| `lib/features/capture/capture_screen.dart` | Use `AdaptiveScaffold`, adaptive dialogs, `AdaptiveProgressIndicator`, keep inner `Scaffold` for `ScaffoldMessenger` |
| `lib/features/reader/reader_screen.dart` | Use `AdaptiveScaffold`, `AdaptiveProgressIndicator` |
| `lib/features/reader/control_bar.dart` | Replace `GoogleFonts.quicksand` with `TextStyle(fontFamily: 'Quicksand')` |
| `ios/Runner/Base.lproj/LaunchScreen.storyboard` | Set background color to Warm Cream |

---

### Task 1: Bundle fonts and remove google_fonts

**Files:**
- Create: `assets/fonts/Quicksand-Regular.ttf`, `assets/fonts/Quicksand-Medium.ttf`, `assets/fonts/Quicksand-SemiBold.ttf`, `assets/fonts/Quicksand-Bold.ttf`
- Create: `assets/fonts/Nunito-Regular.ttf`, `assets/fonts/Nunito-SemiBold.ttf`, `assets/fonts/Nunito-Bold.ttf`
- Create: `assets/fonts/OFL-Quicksand.txt`, `assets/fonts/OFL-Nunito.txt`
- Modify: `pubspec.yaml`
- Modify: `lib/app/theme.dart`
- Modify: `lib/features/capture/capture_screen.dart:258` (GoogleFonts.nunito reference)
- Modify: `lib/features/reader/control_bar.dart:74` (GoogleFonts.quicksand reference)

- [ ] **Step 1: Download font files**

Download Quicksand and Nunito TTF files from Google Fonts and place in `assets/fonts/`:

```bash
cd /Users/dsh/repos/privat/focus-read/flutter_app
mkdir -p assets/fonts

# Download Quicksand
curl -L "https://fonts.google.com/download?family=Quicksand" -o /tmp/quicksand.zip
unzip -o /tmp/quicksand.zip -d /tmp/quicksand
cp /tmp/quicksand/static/Quicksand-Regular.ttf assets/fonts/
cp /tmp/quicksand/static/Quicksand-Medium.ttf assets/fonts/
cp /tmp/quicksand/static/Quicksand-SemiBold.ttf assets/fonts/
cp /tmp/quicksand/static/Quicksand-Bold.ttf assets/fonts/
cp /tmp/quicksand/OFL.txt assets/fonts/OFL-Quicksand.txt

# Download Nunito
curl -L "https://fonts.google.com/download?family=Nunito" -o /tmp/nunito.zip
unzip -o /tmp/nunito.zip -d /tmp/nunito
cp /tmp/nunito/static/Nunito-Regular.ttf assets/fonts/
cp /tmp/nunito/static/Nunito-SemiBold.ttf assets/fonts/
cp /tmp/nunito/static/Nunito-Bold.ttf assets/fonts/
cp /tmp/nunito/OFL.txt assets/fonts/OFL-Nunito.txt
```

- [ ] **Step 2: Update pubspec.yaml**

Remove `google_fonts` from dependencies and add font declarations:

```yaml
# In dependencies: section, REMOVE this line:
  google_fonts: ^6.2.1

# At the end of the flutter: section, add:
  fonts:
    - family: Quicksand
      fonts:
        - asset: assets/fonts/Quicksand-Regular.ttf
          weight: 400
        - asset: assets/fonts/Quicksand-Medium.ttf
          weight: 500
        - asset: assets/fonts/Quicksand-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Quicksand-Bold.ttf
          weight: 700
    - family: Nunito
      fonts:
        - asset: assets/fonts/Nunito-Regular.ttf
          weight: 400
        - asset: assets/fonts/Nunito-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Nunito-Bold.ttf
          weight: 700
```

- [ ] **Step 3: Update theme.dart — remove GoogleFonts**

Replace every `GoogleFonts.quicksand(...)` with `TextStyle(fontFamily: 'Quicksand', ...)` and every `GoogleFonts.nunito(...)` with `TextStyle(fontFamily: 'Nunito', ...)`. Also replace `GoogleFonts.nunitoTextTheme()` with a manually constructed text theme using `fontFamily: 'Nunito'`.

Remove the `import 'package:google_fonts/google_fonts.dart';` line.

Use `.apply(fontFamily:)` as a base so that ALL text styles (including unlisted ones like `labelMedium`, `labelSmall`) default to Nunito — matching the previous `GoogleFonts.nunitoTextTheme()` behavior:

```dart
textTheme: ThemeData.light().textTheme.apply(fontFamily: 'Nunito').copyWith(
  displayLarge: const TextStyle(fontFamily: 'Quicksand', fontSize: 40, fontWeight: FontWeight.w700, color: AppColors.textDark),
  displayMedium: const TextStyle(fontFamily: 'Quicksand', fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textDark),
  headlineLarge: const TextStyle(fontFamily: 'Quicksand', fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textDark),
  headlineMedium: const TextStyle(fontFamily: 'Quicksand', fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textDark),
  headlineSmall: const TextStyle(fontFamily: 'Quicksand', fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textDark),
  titleLarge: const TextStyle(fontFamily: 'Quicksand', fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textDark),
  titleMedium: const TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark),
  titleSmall: const TextStyle(fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
  bodyLarge: const TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textDark),
  bodyMedium: const TextStyle(fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textDark),
  bodySmall: const TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textLight),
  labelLarge: const TextStyle(fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
),
```

Also update `appBarTheme.titleTextStyle`, `filledButtonTheme`, `textButtonTheme`, `sliderTheme.valueIndicatorTextStyle`, `dialogTheme.titleTextStyle`, and `inputDecorationTheme.labelStyle` — all from `GoogleFonts.*()` to `TextStyle(fontFamily: ...)`.

- [ ] **Step 4: Update capture_screen.dart — remove GoogleFonts import**

In `lib/features/capture/capture_screen.dart`, line 6: remove `import 'package:google_fonts/google_fonts.dart';`

Line 258: replace `GoogleFonts.nunito(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)` with `TextStyle(fontFamily: 'Nunito', color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)`.

- [ ] **Step 5: Update control_bar.dart — remove GoogleFonts import**

In `lib/features/reader/control_bar.dart`, line 2: remove `import 'package:google_fonts/google_fonts.dart';`

Line 74: replace `GoogleFonts.quicksand(fontSize: 20 * buttonScale, fontWeight: FontWeight.w700, color: AppColors.textDark)` with `TextStyle(fontFamily: 'Quicksand', fontSize: 20 * buttonScale, fontWeight: FontWeight.w700, color: AppColors.textDark)`.

- [ ] **Step 6: Run flutter pub get and verify no google_fonts references remain**

```bash
cd /Users/dsh/repos/privat/focus-read/flutter_app
fvm flutter pub get
```

Expected: resolves successfully without google_fonts.

Then verify no remaining references:
```bash
grep -r "google_fonts" lib/ --include="*.dart"
```

Expected: no output.

- [ ] **Step 7: Verify build compiles**

```bash
cd /Users/dsh/repos/privat/focus-read/flutter_app
fvm flutter build ios --no-codesign --debug 2>&1 | tail -5
```

Expected: build succeeds.

- [ ] **Step 8: Commit**

```bash
git add assets/fonts/ pubspec.yaml lib/app/theme.dart lib/features/capture/capture_screen.dart lib/features/reader/control_bar.dart
git commit -m "feat: bundle Quicksand + Nunito fonts, remove google_fonts dependency"
```

---

### Task 2: Create platform_utils.dart and adaptive_progress_indicator.dart

**Files:**
- Create: `lib/shared/adaptive/platform_utils.dart`
- Create: `lib/shared/adaptive/adaptive_progress_indicator.dart`

- [ ] **Step 1: Create platform_utils.dart**

```dart
// lib/shared/adaptive/platform_utils.dart
import 'package:flutter/foundation.dart';

bool get isIOSPlatform => defaultTargetPlatform == TargetPlatform.iOS;
```

- [ ] **Step 2: Create adaptive_progress_indicator.dart**

```dart
// lib/shared/adaptive/adaptive_progress_indicator.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'platform_utils.dart';

class AdaptiveProgressIndicator extends StatelessWidget {
  final Color? color;

  const AdaptiveProgressIndicator({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    if (isIOSPlatform) {
      return CupertinoActivityIndicator(color: color);
    }
    return CircularProgressIndicator(color: color);
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/shared/adaptive/
git commit -m "feat: add platform_utils and AdaptiveProgressIndicator"
```

---

### Task 3: Create adaptive_dialog.dart and adaptive_action_sheet.dart

**Files:**
- Create: `lib/shared/adaptive/adaptive_dialog.dart`
- Create: `lib/shared/adaptive/adaptive_action_sheet.dart`
- Modify: `lib/shared/confirm_dialog.dart`

- [ ] **Step 1: Create adaptive_dialog.dart**

```dart
// lib/shared/adaptive/adaptive_dialog.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'platform_utils.dart';

/// Shows a confirm dialog with cancel + confirm actions.
/// Returns true if confirmed, false otherwise.
Future<bool> showAdaptiveConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
  String cancelLabel = 'Cancel',
  Color? confirmColor,
  bool isDestructive = false,
}) async {
  if (isIOSPlatform) {
    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelLabel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: isDestructive || confirmColor == Colors.red,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: confirmColor != null
              ? FilledButton.styleFrom(backgroundColor: confirmColor)
              : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Shows an alert dialog with a single OK action.
Future<void> showAdaptiveAlert(
  BuildContext context, {
  required String title,
  required String message,
  String okLabel = 'OK',
}) async {
  if (isIOSPlatform) {
    await showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(okLabel),
          ),
        ],
      ),
    );
    return;
  }

  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(okLabel),
        ),
      ],
    ),
  );
}

/// Shows a dialog that returns a value picked from a list of options.
/// On iOS: CupertinoActionSheet. On Android: SimpleDialog.
Future<T?> showAdaptiveChoiceDialog<T>({
  required BuildContext context,
  required String title,
  required List<AdaptiveChoice<T>> choices,
}) async {
  if (isIOSPlatform) {
    return showCupertinoModalPopup<T>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(title),
        actions: choices
            .map((c) => CupertinoActionSheetAction(
                  onPressed: () => Navigator.of(context).pop(c.value),
                  child: Text(c.label),
                ))
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  return showDialog<T>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(title),
      children: choices
          .map((c) => SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(c.value),
                child: Text(c.label),
              ))
          .toList(),
    ),
  );
}

class AdaptiveChoice<T> {
  final T value;
  final String label;
  const AdaptiveChoice({required this.value, required this.label});
}
```

- [ ] **Step 2: Create adaptive_action_sheet.dart**

```dart
// lib/shared/adaptive/adaptive_action_sheet.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'platform_utils.dart';

class AdaptiveAction {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool isDestructive;

  const AdaptiveAction({
    required this.label,
    this.icon,
    required this.onPressed,
    this.isDestructive = false,
  });
}

Future<void> showAdaptiveActionSheet(
  BuildContext context, {
  required List<AdaptiveAction> actions,
}) async {
  if (isIOSPlatform) {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: actions
            .map((a) => CupertinoActionSheetAction(
                  isDestructiveAction: a.isDestructive,
                  onPressed: () {
                    Navigator.of(context).pop();
                    a.onPressed();
                  },
                  child: Text(a.label),
                ))
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: actions
            .map((a) => ListTile(
                  leading: a.icon != null
                      ? Icon(a.icon,
                          color: a.isDestructive ? Colors.red : null)
                      : null,
                  title: Text(
                    a.label,
                    style: a.isDestructive
                        ? const TextStyle(color: Colors.red)
                        : null,
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    a.onPressed();
                  },
                ))
            .toList(),
      ),
    ),
  );
}
```

- [ ] **Step 3: Update confirm_dialog.dart to use adaptive dialog**

Replace the entire file:

```dart
// lib/shared/confirm_dialog.dart
import 'package:flutter/material.dart';
import '../app/theme.dart';
import 'adaptive/adaptive_dialog.dart';

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
  Color? confirmColor,
}) {
  final effectiveColor = confirmColor ?? AppColors.error;
  return showAdaptiveConfirmDialog(
    context,
    title: title,
    message: message,
    confirmLabel: confirmLabel,
    confirmColor: effectiveColor,
    isDestructive: true,
  );
}
```

- [ ] **Step 4: Verify build compiles**

```bash
cd /Users/dsh/repos/privat/focus-read/flutter_app
fvm flutter analyze lib/shared/
```

Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/adaptive/adaptive_dialog.dart lib/shared/adaptive/adaptive_action_sheet.dart lib/shared/confirm_dialog.dart
git commit -m "feat: add adaptive dialogs and action sheets"
```

---

### Task 4: Create adaptive_button.dart, adaptive_text_field.dart, adaptive_slider.dart, adaptive_switch.dart

**Files:**
- Create: `lib/shared/adaptive/adaptive_button.dart`
- Create: `lib/shared/adaptive/adaptive_text_field.dart`
- Create: `lib/shared/adaptive/adaptive_slider.dart`
- Create: `lib/shared/adaptive/adaptive_switch.dart`

- [ ] **Step 1: Create adaptive_button.dart**

```dart
// lib/shared/adaptive/adaptive_button.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'platform_utils.dart';

class AdaptiveFilledButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;
  final ButtonStyle? style;

  const AdaptiveFilledButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    if (isIOSPlatform) {
      return CupertinoButton.filled(
        onPressed: onPressed,
        child: icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [icon!, const SizedBox(width: 8), child],
              )
            : child,
      );
    }
    if (icon != null) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: icon!,
        label: child,
        style: style,
      );
    }
    return FilledButton(
      onPressed: onPressed,
      style: style,
      child: child,
    );
  }
}

class AdaptiveTextButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;

  const AdaptiveTextButton({
    super.key,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (isIOSPlatform) {
      return CupertinoButton(
        onPressed: onPressed,
        child: child,
      );
    }
    return TextButton(
      onPressed: onPressed,
      child: child,
    );
  }
}
```

- [ ] **Step 2: Create adaptive_text_field.dart**

```dart
// lib/shared/adaptive/adaptive_text_field.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'platform_utils.dart';

class AdaptiveTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? placeholder;
  final String? labelText;
  final bool autofocus;
  final ValueChanged<String>? onChanged;

  const AdaptiveTextField({
    super.key,
    this.controller,
    this.placeholder,
    this.labelText,
    this.autofocus = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (isIOSPlatform) {
      return CupertinoTextField(
        controller: controller,
        placeholder: placeholder ?? labelText,
        autofocus: autofocus,
        onChanged: onChanged,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: CupertinoColors.systemGrey4),
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }
    return TextField(
      controller: controller,
      autofocus: autofocus,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: placeholder,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
```

- [ ] **Step 3: Create adaptive_slider.dart**

```dart
// lib/shared/adaptive/adaptive_slider.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'platform_utils.dart';

class AdaptiveSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String? label;
  final ValueChanged<double>? onChanged;

  const AdaptiveSlider({
    super.key,
    required this.value,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.label,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (isIOSPlatform) {
      return CupertinoSlider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
      );
    }
    return Slider(
      value: value,
      min: min,
      max: max,
      divisions: divisions,
      label: label,
      onChanged: onChanged,
    );
  }
}
```

- [ ] **Step 4: Create adaptive_switch.dart**

```dart
// lib/shared/adaptive/adaptive_switch.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'platform_utils.dart';

class AdaptiveSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const AdaptiveSwitch({
    super.key,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (isIOSPlatform) {
      return CupertinoSwitch(
        value: value,
        onChanged: onChanged,
      );
    }
    return Switch(
      value: value,
      onChanged: onChanged,
    );
  }
}
```

- [ ] **Step 5: Verify build**

```bash
cd /Users/dsh/repos/privat/focus-read/flutter_app
fvm flutter analyze lib/shared/adaptive/
```

Expected: no errors.

- [ ] **Step 6: Commit**

```bash
git add lib/shared/adaptive/
git commit -m "feat: add adaptive button, text field, slider, and switch widgets"
```

---

### Task 5: Create adaptive_scaffold.dart

**Files:**
- Create: `lib/shared/adaptive/adaptive_scaffold.dart`

- [ ] **Step 1: Create adaptive_scaffold.dart**

```dart
// lib/shared/adaptive/adaptive_scaffold.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'platform_utils.dart';

class AdaptiveScaffold extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final Widget body;
  final List<Widget>? actions;
  final Widget? leading;
  final Color? backgroundColor;

  const AdaptiveScaffold({
    super.key,
    this.title,
    this.titleWidget,
    required this.body,
    this.actions,
    this.leading,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (isIOSPlatform) {
      return CupertinoPageScaffold(
        backgroundColor:
            backgroundColor ?? CupertinoTheme.of(context).scaffoldBackgroundColor,
        navigationBar: CupertinoNavigationBar(
          middle: titleWidget ?? (title != null ? Text(title!) : null),
          leading: leading,
          trailing: actions != null && actions!.isNotEmpty
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions!,
                )
              : null,
        ),
        child: SafeArea(
          bottom: false,
          child: body,
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        leading: leading,
        title: titleWidget ?? (title != null ? Text(title!) : null),
        actions: actions,
      ),
      body: body,
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/shared/adaptive/adaptive_scaffold.dart
git commit -m "feat: add AdaptiveScaffold widget"
```

---

### Task 6: Create AdaptiveApp and update theme

**Files:**
- Create: `lib/shared/adaptive/adaptive_app.dart`
- Modify: `lib/app/theme.dart` — add `cupertinoTheme` builder
- Modify: `lib/app/app.dart` — use `AdaptiveApp`

- [ ] **Step 1: Add CupertinoThemeData builder to theme.dart**

Add at the bottom of `lib/app/theme.dart`:

```dart
CupertinoThemeData get focusReadCupertinoTheme => CupertinoThemeData(
  primaryColor: AppColors.primary,
  scaffoldBackgroundColor: AppColors.background,
  textTheme: const CupertinoTextThemeData(
    primaryColor: AppColors.textDark,
    navTitleTextStyle: TextStyle(
      fontFamily: 'Quicksand',
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.textDark,
    ),
    navLargeTitleTextStyle: TextStyle(
      fontFamily: 'Quicksand',
      fontSize: 34,
      fontWeight: FontWeight.w700,
      color: AppColors.textDark,
    ),
  ),
);
```

- [ ] **Step 2: Create adaptive_app.dart**

```dart
// lib/shared/adaptive/adaptive_app.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'platform_utils.dart';

class AdaptiveApp extends StatelessWidget {
  final String title;
  final ThemeData materialTheme;
  final CupertinoThemeData cupertinoTheme;
  final GoRouter routerConfig;
  final Iterable<LocalizationsDelegate<dynamic>> localizationsDelegates;
  final Iterable<Locale> supportedLocales;
  final Locale? locale;

  const AdaptiveApp({
    super.key,
    required this.title,
    required this.materialTheme,
    required this.cupertinoTheme,
    required this.routerConfig,
    required this.localizationsDelegates,
    required this.supportedLocales,
    this.locale,
  });

  @override
  Widget build(BuildContext context) {
    if (isIOSPlatform) {
      return CupertinoApp.router(
        title: title,
        theme: cupertinoTheme,
        routerConfig: routerConfig,
        localizationsDelegates: localizationsDelegates,
        supportedLocales: supportedLocales,
        locale: locale,
        // Inject Material Theme so Theme.of(context) works for
        // Material widgets (Card, etc.) used inside Cupertino shell.
        builder: (context, child) {
          return Theme(
            data: materialTheme,
            child: child ?? const SizedBox.shrink(),
          );
        },
      );
    }

    return MaterialApp.router(
      title: title,
      theme: materialTheme,
      routerConfig: routerConfig,
      localizationsDelegates: localizationsDelegates,
      supportedLocales: supportedLocales,
      locale: locale,
    );
  }
}
```

- [ ] **Step 3: Update app.dart to use AdaptiveApp**

Replace the contents of `lib/app/app.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:focus_read/core/l10n/app_localizations.dart';
import '../features/settings/settings_provider.dart';
import '../shared/adaptive/adaptive_app.dart';
import 'router.dart';
import 'theme.dart';

class FocusReadApp extends ConsumerWidget {
  const FocusReadApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return AdaptiveApp(
      title: 'Focus Read',
      materialTheme: focusReadTheme,
      cupertinoTheme: focusReadCupertinoTheme,
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale(settings.appLanguage),
    );
  }
}
```

- [ ] **Step 4: Verify build**

```bash
cd /Users/dsh/repos/privat/focus-read/flutter_app
fvm flutter analyze
```

Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/adaptive/adaptive_app.dart lib/app/theme.dart lib/app/app.dart
git commit -m "feat: add AdaptiveApp with CupertinoApp.router on iOS and Material Theme injection"
```

---

### Task 7: Update router.dart — switch to pageBuilder with adaptive pages

**Files:**
- Modify: `lib/app/router.dart`

- [ ] **Step 1: Update router.dart**

Replace the entire file:

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/library/library_screen.dart';
import '../features/book/book_screen.dart';
import '../features/capture/capture_screen.dart';
import '../features/reader/reader_screen.dart';
import '../features/settings/settings_screen.dart';
import '../shared/adaptive/platform_utils.dart';

Page<void> adaptivePage({
  required LocalKey key,
  required Widget child,
}) {
  if (isIOSPlatform) {
    return CupertinoPage(key: key, child: child);
  }
  return MaterialPage(key: key, child: child);
}

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => adaptivePage(
        key: state.pageKey,
        child: const LibraryScreen(),
      ),
    ),
    GoRoute(
      path: '/book/:bookId',
      pageBuilder: (context, state) {
        final bookId = state.pathParameters['bookId']!;
        return adaptivePage(
          key: state.pageKey,
          child: BookScreen(bookId: bookId),
        );
      },
      routes: [
        GoRoute(
          path: 'capture',
          pageBuilder: (context, state) {
            final bookId = state.pathParameters['bookId']!;
            return adaptivePage(
              key: state.pageKey,
              child: CaptureScreen(bookId: bookId),
            );
          },
        ),
        GoRoute(
          path: 'read/:pageId',
          pageBuilder: (context, state) {
            final bookId = state.pathParameters['bookId']!;
            final pageId = state.pathParameters['pageId']!;
            return adaptivePage(
              key: state.pageKey,
              child: ReaderScreen(bookId: bookId, pageId: pageId),
            );
          },
        ),
      ],
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) => adaptivePage(
        key: state.pageKey,
        child: const SettingsScreen(),
      ),
    ),
  ],
);
```

- [ ] **Step 2: Verify build**

```bash
cd /Users/dsh/repos/privat/focus-read/flutter_app
fvm flutter analyze lib/app/router.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/app/router.dart
git commit -m "feat: switch GoRouter to pageBuilder with CupertinoPage on iOS"
```

---

### Task 8: Migrate LibraryScreen

**Files:**
- Modify: `lib/features/library/library_screen.dart`

- [ ] **Step 1: Update library_screen.dart**

Changes needed:
1. Add imports for adaptive widgets
2. Replace `Scaffold` + `AppBar` with `AdaptiveScaffold`
3. Replace `CircularProgressIndicator` with `AdaptiveProgressIndicator`
4. Replace `showModalBottomSheet` in `_showBookOptions` with `showAdaptiveActionSheet`
5. Replace `AlertDialog` in `_renameBook` with adaptive version using `showAdaptiveAlert`-style dialog (or keep as is since it has a text field — use the Cupertino equivalent)

For the rename dialog (which has a TextField), create a platform-adaptive version inline:

```dart
import 'package:flutter/cupertino.dart';
// ... existing imports ...
import '../../shared/adaptive/adaptive_scaffold.dart';
import '../../shared/adaptive/adaptive_progress_indicator.dart';
import '../../shared/adaptive/adaptive_action_sheet.dart';
import '../../shared/adaptive/adaptive_dialog.dart';
import '../../shared/adaptive/adaptive_text_field.dart';
import '../../shared/adaptive/platform_utils.dart';
```

Key changes in build():
- `Scaffold(appBar: AppBar(...), body: ...)` → `AdaptiveScaffold(title: 'Focus Read', actions: [...], body: ...)`
- `CircularProgressIndicator()` → `AdaptiveProgressIndicator()`
- `_showBookOptions`: replace `showModalBottomSheet` with `showAdaptiveActionSheet`
- `_renameBook`: replace `AlertDialog` with Cupertino-aware version (on iOS use `CupertinoAlertDialog` with `CupertinoTextField` inside)

For _renameBook, since `CupertinoAlertDialog.content` can accept any widget:

```dart
Future<void> _renameBook(BuildContext context, Book book, AppDatabase db) async {
  final controller = TextEditingController(text: book.title);
  final String? newTitle;

  if (isIOSPlatform) {
    newTitle = await showCupertinoDialog<String>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Rename Book'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: CupertinoTextField(
            controller: controller,
            placeholder: 'Title',
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              final title = controller.text.trim();
              if (title.isEmpty) return;
              Navigator.of(context).pop(title);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  } else {
    newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Book'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Title',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final title = controller.text.trim();
              if (title.isEmpty) return;
              Navigator.of(context).pop(title);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  if (newTitle != null && newTitle.isNotEmpty) {
    await db.updateBook(
      BooksCompanion(
        id: Value(book.id),
        title: Value(newTitle),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
```

For _showBookOptions:
```dart
Future<void> _showBookOptions(
  BuildContext context, Book book,
  Future<void> Function(String) deleteBook, AppDatabase db,
) async {
  await showAdaptiveActionSheet(
    context,
    actions: [
      AdaptiveAction(
        label: 'Rename',
        icon: Icons.edit,
        onPressed: () => _renameBook(context, book, db),
      ),
      AdaptiveAction(
        label: 'Delete',
        icon: Icons.delete,
        isDestructive: true,
        onPressed: () => _deleteBook(context, book, deleteBook),
      ),
    ],
  );
}
```

- [ ] **Step 2: Verify build**

```bash
cd /Users/dsh/repos/privat/focus-read/flutter_app
fvm flutter analyze lib/features/library/
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/library/library_screen.dart
git commit -m "feat: migrate LibraryScreen to adaptive widgets"
```

---

### Task 9: Migrate BookScreen

**Files:**
- Modify: `lib/features/book/book_screen.dart`

- [ ] **Step 1: Update book_screen.dart**

Changes:
1. Add imports for adaptive widgets
2. `Scaffold` + `AppBar` → `AdaptiveScaffold`
3. `CircularProgressIndicator` → `AdaptiveProgressIndicator`
4. `showModalBottomSheet` in `_showPageOptions` → `showAdaptiveActionSheet`
5. Back button: on iOS `CupertinoNavigationBar` provides back button automatically via GoRouter, so remove explicit `leading: IconButton(icon: Icon(Icons.arrow_back)...)`. On Android keep default AppBar back behavior.

Add imports:
```dart
import '../../shared/adaptive/adaptive_scaffold.dart';
import '../../shared/adaptive/adaptive_progress_indicator.dart';
import '../../shared/adaptive/adaptive_action_sheet.dart';
```

Replace build method's Scaffold with AdaptiveScaffold. Note: `bookAsync.when` for the title widget needs to be passed as `titleWidget:`.

For _showPageOptions:
```dart
Future<void> _showPageOptions(
  BuildContext context, db.Page page,
  Future<void> Function(String, String) deletePage,
) async {
  await showAdaptiveActionSheet(
    context,
    actions: [
      AdaptiveAction(
        label: 'Delete Page',
        icon: Icons.delete,
        isDestructive: true,
        onPressed: () => _deletePage(context, page, deletePage),
      ),
    ],
  );
}
```

- [ ] **Step 2: Verify build**

```bash
cd /Users/dsh/repos/privat/focus-read/flutter_app
fvm flutter analyze lib/features/book/book_screen.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/book/book_screen.dart
git commit -m "feat: migrate BookScreen to adaptive widgets"
```

---

### Task 10: Migrate CreateBookDialog

**Files:**
- Modify: `lib/features/book/create_book_dialog.dart`

- [ ] **Step 1: Update create_book_dialog.dart**

Add platform-adaptive branch. On iOS: use `CupertinoAlertDialog` with `CupertinoTextField` + `CupertinoActionSheet` for language selection. On Android: keep current Material implementation.

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../shared/adaptive/platform_utils.dart';

// ... CreateBookResult class stays the same ...

Future<CreateBookResult?> showCreateBookDialog(
  BuildContext context, {
  required int bookNumber,
  String defaultLanguage = 'de',
}) async {
  final titleController = TextEditingController(text: 'Book $bookNumber');
  var selectedLanguage = defaultLanguage;

  const languages = {
    'de': 'Deutsch',
    'en': 'English',
    'fr': 'Français',
    'es': 'Español',
    'pt': 'Português',
    'it': 'Italiano',
    'nl': 'Nederlands',
  };

  if (isIOSPlatform) {
    return showCupertinoDialog<CreateBookResult>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => CupertinoAlertDialog(
          title: const Text('New Book'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: titleController,
                placeholder: 'Title',
                autofocus: true,
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final result = await showCupertinoModalPopup<String>(
                    context: context,
                    builder: (context) => CupertinoActionSheet(
                      title: const Text('Language'),
                      actions: languages.entries
                          .map((e) => CupertinoActionSheetAction(
                                onPressed: () => Navigator.of(context).pop(e.key),
                                child: Text(e.value),
                              ))
                          .toList(),
                      cancelButton: CupertinoActionSheetAction(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                  );
                  if (result != null) {
                    setState(() => selectedLanguage = result);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: CupertinoColors.systemGrey4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(languages[selectedLanguage] ?? selectedLanguage),
                      const Icon(CupertinoIcons.chevron_down, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isEmpty) return;
                Navigator.of(context).pop(
                  CreateBookResult(title: title, language: selectedLanguage),
                );
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  // Android: keep existing Material dialog
  return showDialog<CreateBookResult>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('New Book'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedLanguage,
              decoration: const InputDecoration(
                labelText: 'Language',
                border: OutlineInputBorder(),
              ),
              items: languages.entries
                  .map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => selectedLanguage = value);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isEmpty) return;
              Navigator.of(context).pop(
                CreateBookResult(title: title, language: selectedLanguage),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    ),
  );
}
```

- [ ] **Step 2: Verify build**

```bash
fvm flutter analyze lib/features/book/create_book_dialog.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/book/create_book_dialog.dart
git commit -m "feat: migrate CreateBookDialog to adaptive widgets"
```

---

### Task 11: Migrate CaptureScreen

**Files:**
- Modify: `lib/features/capture/capture_screen.dart`

- [ ] **Step 1: Update capture_screen.dart**

Changes:
1. Add adaptive imports
2. Keep outer `Scaffold` (needed for `ScaffoldMessenger` snackbars) but make it minimal — on iOS it just provides the ScaffoldMessenger ancestor
3. Replace `AppBar` with `AdaptiveScaffold` pattern. Since CaptureScreen has a black background + custom camera layout, use a different approach: keep `Scaffold` on both platforms but with adaptive elements inside.
4. Replace `AlertDialog` in `_showPermissionDeniedDialog` with `showAdaptiveAlert`
5. Replace `AlertDialog` in `_handleSuccess` with adaptive version
6. Replace `CircularProgressIndicator` with `AdaptiveProgressIndicator`

Actually, CaptureScreen is special — it has a black background and camera-specific layout. The best approach is to keep the `Scaffold` (for `ScaffoldMessenger`) but make the dialogs adaptive:

```dart
// Add imports:
import 'package:flutter/cupertino.dart';
import '../../shared/adaptive/adaptive_dialog.dart';
import '../../shared/adaptive/adaptive_progress_indicator.dart';
import '../../shared/adaptive/platform_utils.dart';
```

Replace `_showPermissionDeniedDialog`:
```dart
Future<void> _showPermissionDeniedDialog() async {
  if (!mounted) return;
  await showAdaptiveAlert(
    context,
    title: 'Camera Access Needed',
    message: 'Focus Read needs camera access to photograph book pages. '
        'Please enable camera access in your device settings.',
  );
}
```

Replace `_handleSuccess` dialogs — make adaptive:
```dart
Future<void> _handleSuccess(String pageId) async {
  if (!mounted) return;
  String? result;

  if (isIOSPlatform) {
    result = await showCupertinoDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Page saved!'),
        content: const Text('What would you like to do next?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop('another'),
            child: const Text('Add another page'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop('read'),
            child: const Text('Start reading'),
          ),
        ],
      ),
    );
  } else {
    result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Page saved!'),
        content: const Text('What would you like to do next?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('another'),
            child: const Text('Add another page'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop('read'),
            child: const Text('Start reading'),
          ),
        ],
      ),
    );
  }

  if (!mounted) return;
  ref.read(captureProvider(widget.bookId).notifier).reset();

  if (result == 'read') {
    context.go('/book/${widget.bookId}/read/$pageId');
  }
}
```

Replace all `CircularProgressIndicator(color: Colors.white)` with `AdaptiveProgressIndicator(color: Colors.white)`.

Replace `GoogleFonts.nunito(...)` with `TextStyle(fontFamily: 'Nunito', ...)` (already done in Task 1, verify).

- [ ] **Step 2: Verify build**

```bash
fvm flutter analyze lib/features/capture/capture_screen.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/capture/capture_screen.dart
git commit -m "feat: migrate CaptureScreen dialogs to adaptive widgets"
```

---

### Task 12: Migrate ReaderScreen

**Files:**
- Modify: `lib/features/reader/reader_screen.dart`

- [ ] **Step 1: Update reader_screen.dart**

Changes:
1. Add adaptive imports
2. Replace `Scaffold` + `AppBar` with `AdaptiveScaffold`
3. Replace `CircularProgressIndicator` with `AdaptiveProgressIndicator`
4. The `GestureDetector` wrapping the scaffold for word navigation swipe must wrap the `AdaptiveScaffold`

```dart
// Add imports:
import '../../shared/adaptive/adaptive_scaffold.dart';
import '../../shared/adaptive/adaptive_progress_indicator.dart';
```

In build(), replace:
```dart
return GestureDetector(
  onHorizontalDragEnd: (details) { ... },
  child: AdaptiveScaffold(
    title: 'Page ${readerState.currentPage}/${readerState.totalPages}',
    body: Column(
      children: [
        Expanded(
          child: _buildMainArea(readerState, settings, ageGroup),
        ),
        ControlBar(...),
      ],
    ),
  ),
);
```

In `_buildMainArea`, replace `CircularProgressIndicator()` with `AdaptiveProgressIndicator()` (2 occurrences).

- [ ] **Step 2: Verify build**

```bash
fvm flutter analyze lib/features/reader/reader_screen.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/reader/reader_screen.dart
git commit -m "feat: migrate ReaderScreen to adaptive widgets"
```

---

### Task 13: Migrate SettingsScreen

**Files:**
- Modify: `lib/features/settings/settings_screen.dart`

- [ ] **Step 1: Update settings_screen.dart**

This is the biggest screen change. On iOS, use `CupertinoListSection` + `CupertinoListTile` for the native grouped-list look. On Android, keep existing Material `ListView`.

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models.dart';
import '../../shared/adaptive/adaptive_scaffold.dart';
import '../../shared/adaptive/adaptive_slider.dart';
import '../../shared/adaptive/adaptive_switch.dart';
import '../../shared/adaptive/adaptive_dialog.dart';
import '../../shared/adaptive/platform_utils.dart';
import 'settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return AdaptiveScaffold(
      title: 'Settings',
      body: isIOSPlatform
          ? _buildCupertinoBody(context, settings, notifier)
          : _buildMaterialBody(context, settings, notifier),
    );
  }

  Widget _buildCupertinoBody(
    BuildContext context, AppSettings settings, SettingsNotifier notifier,
  ) {
    return ListView(
      children: [
        CupertinoListSection.insetGrouped(
          header: const Text('General'),
          children: [
            CupertinoListTile(
              title: const Text('App Language'),
              additionalInfo: Text(settings.appLanguage == 'de' ? 'Deutsch' : 'English'),
              trailing: const CupertinoListTileChevron(),
              onTap: () => _selectLanguage(context, notifier),
            ),
            CupertinoListTile(
              title: const Text('Age Group'),
              additionalInfo: Text(_ageGroupLabel(settings.ageGroup)),
              trailing: const CupertinoListTileChevron(),
              onTap: () => _selectAgeGroup(context, notifier),
            ),
          ],
        ),
        CupertinoListSection.insetGrouped(
          header: const Text('Text-to-Speech'),
          children: [
            CupertinoListTile(
              title: const Text('Read Aloud'),
              trailing: AdaptiveSwitch(
                value: settings.ttsEnabled,
                onChanged: (value) => notifier.setTtsEnabled(value),
              ),
            ),
            CupertinoListTile(
              title: const Text('Speech Speed'),
              subtitle: Text('${settings.ttsSpeed.toStringAsFixed(1)}x'),
              additionalInfo: SizedBox(
                width: 180,
                child: AdaptiveSlider(
                  value: settings.ttsSpeed,
                  min: 0.3,
                  max: 1.5,
                  divisions: 12,
                  onChanged: settings.ttsEnabled
                      ? (value) => notifier.setTtsSpeed(value)
                      : null,
                ),
              ),
            ),
          ],
        ),
        CupertinoListSection.insetGrouped(
          header: const Text('Advanced'),
          children: [
            CupertinoListTile(
              title: const Text('OCR Confidence'),
              subtitle: Text('${(settings.confidenceThreshold * 100).round()}%'),
              additionalInfo: SizedBox(
                width: 180,
                child: AdaptiveSlider(
                  value: settings.confidenceThreshold,
                  min: 0.5,
                  max: 1.0,
                  divisions: 10,
                  onChanged: (value) => notifier.setConfidenceThreshold(value),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMaterialBody(
    BuildContext context, AppSettings settings, SettingsNotifier notifier,
  ) {
    return ListView(
      children: [
        _SectionHeader(title: 'General'),
        ListTile(
          title: const Text('App Language'),
          subtitle: Text(settings.appLanguage == 'de' ? 'Deutsch' : 'English'),
          onTap: () => _selectLanguage(context, notifier),
        ),
        ListTile(
          title: const Text('Age Group'),
          subtitle: Text(_ageGroupLabel(settings.ageGroup)),
          onTap: () => _selectAgeGroup(context, notifier),
        ),
        const Divider(),
        _SectionHeader(title: 'Text-to-Speech'),
        SwitchListTile(
          title: const Text('Read Aloud'),
          value: settings.ttsEnabled,
          onChanged: (value) => notifier.setTtsEnabled(value),
        ),
        ListTile(
          title: const Text('Speech Speed'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${settings.ttsSpeed.toStringAsFixed(1)}x'),
              Slider(
                value: settings.ttsSpeed,
                min: 0.3,
                max: 1.5,
                divisions: 12,
                label: '${settings.ttsSpeed.toStringAsFixed(1)}x',
                onChanged: settings.ttsEnabled
                    ? (value) => notifier.setTtsSpeed(value)
                    : null,
              ),
            ],
          ),
        ),
        const Divider(),
        _SectionHeader(title: 'Advanced'),
        ListTile(
          title: const Text('OCR Confidence Threshold'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${(settings.confidenceThreshold * 100).round()}%'),
              Slider(
                value: settings.confidenceThreshold,
                min: 0.5,
                max: 1.0,
                divisions: 10,
                label: '${(settings.confidenceThreshold * 100).round()}%',
                onChanged: (value) => notifier.setConfidenceThreshold(value),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _selectLanguage(BuildContext context, SettingsNotifier notifier) async {
    final result = await showAdaptiveChoiceDialog<String>(
      context: context,
      title: 'App Language',
      choices: const [
        AdaptiveChoice(value: 'de', label: 'Deutsch'),
        AdaptiveChoice(value: 'en', label: 'English'),
      ],
    );
    if (result != null) {
      await notifier.setAppLanguage(result);
    }
  }

  Future<void> _selectAgeGroup(BuildContext context, SettingsNotifier notifier) async {
    final result = await showAdaptiveChoiceDialog<AgeGroup>(
      context: context,
      title: 'Age Group',
      choices: const [
        AdaptiveChoice(value: AgeGroup.preschool, label: 'Preschool (4–6)'),
        AdaptiveChoice(value: AgeGroup.earlyPrimary, label: 'Early Primary (6–8)'),
        AdaptiveChoice(value: AgeGroup.latePrimary, label: 'Late Primary (8–10)'),
      ],
    );
    if (result != null) {
      await notifier.setAgeGroup(result);
    }
  }

  String _ageGroupLabel(AgeGroup group) => switch (group) {
        AgeGroup.preschool => 'Preschool (4–6)',
        AgeGroup.earlyPrimary => 'Early Primary (6–8)',
        AgeGroup.latePrimary => 'Late Primary (8–10)',
      };
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify build**

```bash
fvm flutter analyze lib/features/settings/settings_screen.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/settings/settings_screen.dart
git commit -m "feat: migrate SettingsScreen to adaptive widgets with CupertinoListSection on iOS"
```

---

### Task 14: Update iOS LaunchScreen

**Files:**
- Modify: `ios/Runner/Base.lproj/LaunchScreen.storyboard`

- [ ] **Step 1: Update LaunchScreen.storyboard background color**

Change the background color from white (`red="1" green="1" blue="1"`) to Warm Cream (#FFF8F0 = R:1.0 G:0.973 B:0.941):

In the storyboard XML, replace:
```xml
<color key="backgroundColor" red="1" green="1" blue="1" alpha="1" colorSpace="custom" customColorSpace="sRGB"/>
```
with:
```xml
<color key="backgroundColor" red="1" green="0.97254901960784312" blue="0.94117647058823528" alpha="1" colorSpace="custom" customColorSpace="sRGB"/>
```

- [ ] **Step 2: Commit**

```bash
git add ios/Runner/Base.lproj/LaunchScreen.storyboard
git commit -m "feat: set iOS launch screen background to warm cream for seamless transition"
```

---

### Task 15: Full build verification

- [ ] **Step 1: Run flutter analyze on entire project**

```bash
cd /Users/dsh/repos/privat/focus-read/flutter_app
fvm flutter analyze
```

Expected: no errors, no warnings (or only pre-existing warnings).

- [ ] **Step 2: Run iOS build**

```bash
fvm flutter build ios --no-codesign --debug 2>&1 | tail -10
```

Expected: build succeeds.

- [ ] **Step 3: Run existing tests**

```bash
fvm flutter test
```

Expected: all tests pass.

- [ ] **Step 4: Manual verification checklist**

Run on iOS Simulator and verify:
- [ ] App starts with warm cream splash → no white flash
- [ ] LibraryScreen: iOS navigation bar, swipe-back works
- [ ] BookScreen: iOS navigation bar, back button is iOS-style
- [ ] CaptureScreen: camera works, dialogs are Cupertino
- [ ] ReaderScreen: word navigation works, iOS nav bar
- [ ] SettingsScreen: grouped list sections, Cupertino switches and sliders
- [ ] All screen transitions are iOS slide-from-right
- [ ] Scroll physics are bouncy (iOS native)

- [ ] **Step 5: Final commit if any fixes needed**

```bash
git add -A
git commit -m "fix: address issues found during verification"
```
