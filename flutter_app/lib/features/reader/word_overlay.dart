import 'package:flutter/material.dart';

class WordOverlay extends StatelessWidget {
  final Rect rect;
  final bool isActive;
  final bool isRead;
  final double dimOpacity;
  final VoidCallback onTap;

  const WordOverlay({
    super.key,
    required this.rect,
    required this.isActive,
    required this.isRead,
    required this.dimOpacity,
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
            border: isActive
                ? Border.all(
                    color: const Color(0xFFE8A87C),
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
      return const Color(0xFFE8A87C).withValues(alpha: 0.4);
    }
    if (isRead) {
      return Colors.white.withValues(alpha: dimOpacity * 0.5);
    }
    return Colors.white.withValues(alpha: dimOpacity);
  }
}
