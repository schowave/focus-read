import 'package:flutter/material.dart';
import '../../app/theme.dart';

class WordOverlay extends StatelessWidget {
  final Rect rect;
  final bool isActive;
  final bool isRead;
  final double focusIntensity;
  final VoidCallback onTap;

  const WordOverlay({
    super.key,
    required this.rect,
    required this.isActive,
    required this.isRead,
    required this.focusIntensity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _overlayColor,
            borderRadius: BorderRadius.circular(6),
            border: isActive
                ? Border.all(
                    color: AppColors.activeWord,
                    width: 2,
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Color get _overlayColor {
    if (isActive) {
      // Strong yellow highlight: 0.4–0.9
      return AppColors.activeWord.withValues(alpha: 0.4 + focusIntensity * 0.5);
    }
    if (isRead) {
      // Read words: heavily faded white: 0.3–0.9
      return Colors.white.withValues(alpha: 0.3 + focusIntensity * 0.6);
    }
    // Unread words: dimmed white: 0.2–0.8
    return Colors.white.withValues(alpha: 0.2 + focusIntensity * 0.6);
  }
}
