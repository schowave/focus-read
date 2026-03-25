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
