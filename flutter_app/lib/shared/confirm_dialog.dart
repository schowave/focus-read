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
