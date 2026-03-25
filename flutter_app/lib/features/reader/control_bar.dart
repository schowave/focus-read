import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme.dart';

class ControlBar extends StatelessWidget {
  final String? currentWord;
  final String progress;
  final bool isFirstWord;
  final bool isLastWord;
  final bool ttsEnabled;
  final double buttonScale;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onTtsToggle;
  final VoidCallback onRepeatTts;

  const ControlBar({
    super.key,
    required this.currentWord,
    required this.progress,
    required this.isFirstWord,
    required this.isLastWord,
    required this.ttsEnabled,
    required this.buttonScale,
    required this.onPrevious,
    required this.onNext,
    required this.onTtsToggle,
    required this.onRepeatTts,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = 24.0 * buttonScale;
    final theme = Theme.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // TTS toggle
            IconButton(
              icon: Icon(
                ttsEnabled ? Icons.volume_up : Icons.volume_off,
                size: iconSize,
              ),
              tooltip: ttsEnabled ? 'Disable TTS' : 'Enable TTS',
              onPressed: onTtsToggle,
            ),
            // Previous button
            IconButton(
              icon: Icon(Icons.chevron_left, size: iconSize),
              tooltip: 'Previous word',
              onPressed: isFirstWord ? null : onPrevious,
            ),
            // Current word (tappable to repeat TTS)
            Expanded(
              child: GestureDetector(
                onTap: onRepeatTts,
                child: Center(
                  child: Text(
                    currentWord ?? '',
                    style: GoogleFonts.quicksand(
                      fontSize: 20 * buttonScale,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            // Next button
            IconButton(
              icon: Icon(Icons.chevron_right, size: iconSize),
              tooltip: 'Next word',
              onPressed: isLastWord ? null : onNext,
            ),
            // Progress text
            SizedBox(
              width: 48,
              child: Text(
                progress,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
