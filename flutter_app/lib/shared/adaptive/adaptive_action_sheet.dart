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
                      ? Icon(a.icon, color: a.isDestructive ? Colors.red : null)
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
