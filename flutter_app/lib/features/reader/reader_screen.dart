import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/database.dart' as db;
import '../../core/tts/tts_service.dart';
import '../../shared/models.dart';
import '../settings/settings_provider.dart';
import 'reader_provider.dart';
import 'word_overlay.dart';
import 'control_bar.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final String bookId;
  final String pageId;

  const ReaderScreen({
    super.key,
    required this.bookId,
    required this.pageId,
  });

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  db.Page? _pageInfo;
  Size? _imageDisplaySize;
  final GlobalKey _imageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadPageInfo();
    // Measure image size after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureImage());
  }

  Future<void> _loadPageInfo() async {
    final database = ref.read(db.databaseProvider);
    try {
      final page = await (database.select(database.pages)
            ..where((p) => p.id.equals(widget.pageId)))
          .getSingle();
      if (mounted) {
        setState(() => _pageInfo = page);
        // Measure again once page info loaded
        WidgetsBinding.instance.addPostFrameCallback((_) => _measureImage());
      }
    } catch (_) {}
  }

  void _measureImage() {
    final ctx = _imageKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;
    final size = box.size;
    if (size != _imageDisplaySize) {
      setState(() => _imageDisplaySize = size);
    }
  }

  Rect _wordRect(Map<String, dynamic> word, Size displaySize, db.Page page) {
    final scaleX = displaySize.width / page.imageWidth;
    final scaleY = displaySize.height / page.imageHeight;
    return Rect.fromLTWH(
      (word['x'] as double) * scaleX,
      (word['y'] as double) * scaleY,
      (word['w'] as double) * scaleX,
      (word['h'] as double) * scaleY,
    );
  }

  void _speakCurrentWord(ReaderState readerState, AppSettings settings) {
    if (!settings.ttsEnabled) return;
    final word = readerState.currentWord;
    if (word == null || word.isEmpty) return;
    final tts = ref.read(ttsServiceProvider);
    tts.speak(
      word,
      language: '${settings.appLanguage}-${settings.appLanguage.toUpperCase()}',
      rate: settings.ttsSpeed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final readerState = ref.watch(readerProvider(widget.pageId));
    final settings = ref.watch(settingsProvider);
    final ageGroup = settings.ageGroup;

    // Listen to word changes to trigger TTS
    ref.listen<ReaderState>(readerProvider(widget.pageId), (previous, next) {
      if (previous?.currentIndex != next.currentIndex) {
        _speakCurrentWord(next, settings);
      }
    });

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null) return;
        if (details.primaryVelocity! < -200) {
          // Swipe left → next word
          ref.read(readerProvider(widget.pageId).notifier).advance(1);
        } else if (details.primaryVelocity! > 200) {
          // Swipe right → previous word
          ref.read(readerProvider(widget.pageId).notifier).advance(-1);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Page ${readerState.currentPage}/${readerState.totalPages}'),
        ),
        body: Column(
          children: [
            Expanded(
              child: _buildMainArea(readerState, settings, ageGroup),
            ),
            ControlBar(
              currentWord: readerState.currentWord,
              progress: readerState.progress,
              isFirstWord: readerState.isFirstWord,
              isLastWord: readerState.isLastWord,
              ttsEnabled: settings.ttsEnabled,
              buttonScale: ageGroup.buttonScale,
              onPrevious: () =>
                  ref.read(readerProvider(widget.pageId).notifier).advance(-1),
              onNext: () =>
                  ref.read(readerProvider(widget.pageId).notifier).advance(1),
              onTtsToggle: () {
                ref
                    .read(settingsProvider.notifier)
                    .setTtsEnabled(!settings.ttsEnabled);
                if (settings.ttsEnabled) {
                  ref.read(ttsServiceProvider).stop();
                }
              },
              onRepeatTts: () => _speakCurrentWord(readerState, settings),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainArea(
      ReaderState readerState, AppSettings settings, AgeGroup ageGroup) {
    if (_pageInfo == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (readerState.isEmpty && readerState.words.isEmpty &&
        readerState.currentPage == 1 && readerState.totalPages == 1) {
      // Still loading — show spinner
      return const Center(child: CircularProgressIndicator());
    }

    if (readerState.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.text_fields, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No words found on this page'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      );
    }

    final page = _pageInfo!;

    return LayoutBuilder(
      builder: (context, constraints) {
        return InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: Stack(
              children: [
                // The page image
                Positioned.fill(
                  child: Image.file(
                    File(page.imagePath),
                    key: _imageKey,
                    fit: BoxFit.contain,
                    frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                      if (frame != null) {
                        WidgetsBinding.instance.addPostFrameCallback(
                            (_) => _measureImage());
                      }
                      return child;
                    },
                  ),
                ),
                // Word overlays — only if we have display size
                if (_imageDisplaySize != null)
                  ..._buildOverlays(
                      readerState, ageGroup, page, _imageDisplaySize!,
                      constraints),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildOverlays(
    ReaderState readerState,
    AgeGroup ageGroup,
    db.Page page,
    Size imageKeySize,
    BoxConstraints constraints,
  ) {
    // Calculate actual image display rect within the container (BoxFit.contain)
    final containerW = constraints.maxWidth;
    final containerH = constraints.maxHeight;
    final imageAspect = page.imageWidth / page.imageHeight;
    final containerAspect = containerW / containerH;

    double displayW, displayH, offsetX, offsetY;
    if (imageAspect > containerAspect) {
      // Image is wider — constrained by width
      displayW = containerW;
      displayH = containerW / imageAspect;
      offsetX = 0;
      offsetY = (containerH - displayH) / 2;
    } else {
      // Image is taller — constrained by height
      displayH = containerH;
      displayW = containerH * imageAspect;
      offsetX = (containerW - displayW) / 2;
      offsetY = 0;
    }

    final displaySize = Size(displayW, displayH);

    return readerState.words.asMap().entries.map((entry) {
      final index = entry.key;
      final word = entry.value;
      final rect = _wordRect(word, displaySize, page);
      // Shift by offset to account for letterboxing
      final shiftedRect = rect.translate(offsetX, offsetY);
      final isActive = index == readerState.currentIndex;
      final isRead = index < readerState.currentIndex;

      return WordOverlay(
        rect: shiftedRect,
        isActive: isActive,
        isRead: isRead,
        dimOpacity: ageGroup.dimOpacity,
        onTap: () {
          ref.read(readerProvider(widget.pageId).notifier).jumpTo(index);
        },
      );
    }).toList();
  }
}
