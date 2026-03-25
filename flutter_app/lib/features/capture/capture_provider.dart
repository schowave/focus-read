import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';
import '../../core/ocr/ocr_service.dart';
import '../../core/image/image_service.dart';
import '../../core/storage/database.dart';
import '../settings/settings_provider.dart';

enum CaptureState { idle, processing, success, error }

class CaptureStatus {
  final CaptureState state;
  final String? errorMessage;
  final String? savedPageId;

  const CaptureStatus({
    this.state = CaptureState.idle,
    this.errorMessage,
    this.savedPageId,
  });
}

class CaptureNotifier extends Notifier<CaptureStatus> {
  CaptureNotifier(this.bookId);
  final String bookId;

  @override
  CaptureStatus build() => const CaptureStatus();

  Future<void> processImage(File imageFile) async {
    state = const CaptureStatus(state: CaptureState.processing);

    try {
      final imageService = ref.read(imageServiceProvider);
      final ocrService = ref.read(ocrServiceProvider);
      final db = ref.read(databaseProvider);
      final settings = ref.read(settingsProvider);

      final savedPath = await imageService.saveImage(imageFile);

      final ocrResult = await ocrService.processImage(
        savedPath,
        confidenceThreshold: settings.confidenceThreshold,
      );

      final existingPages = await db.getPagesForBook(bookId);
      final nextPageNumber = existingPages.isEmpty
          ? 1
          : existingPages
                  .map((p) => p.pageNumber)
                  .reduce((a, b) => a > b ? a : b) +
              1;

      final pageId = const Uuid().v4();
      await db.insertPage(PagesCompanion.insert(
        id: pageId,
        bookId: bookId,
        pageNumber: nextPageNumber,
        imagePath: savedPath,
        imageWidth: ocrResult.imageWidth,
        imageHeight: ocrResult.imageHeight,
        ocrCompleted: const Value(true),
      ));

      if (ocrResult.words.isNotEmpty) {
        final wordCompanions = ocrResult.words.map((w) {
          return WordsCompanion.insert(
            id: const Uuid().v4(),
            pageId: pageId,
            textContent: w['text'] as String,
            x: (w['x'] as num).toDouble(),
            y: (w['y'] as num).toDouble(),
            w: (w['w'] as num).toDouble(),
            h: (w['h'] as num).toDouble(),
            confidence: (w['confidence'] as num).toDouble(),
            sortIndex: w['sortIndex'] as int,
          );
        }).toList();
        await db.insertWords(wordCompanions);
      }

      if (nextPageNumber == 1) {
        await db.updateBook(BooksCompanion(
          id: Value(bookId),
          coverImagePath: Value(savedPath),
          updatedAt: Value(DateTime.now()),
        ));
      }

      state = CaptureStatus(
        state: ocrResult.words.isEmpty
            ? CaptureState.error
            : CaptureState.success,
        savedPageId: pageId,
        errorMessage: ocrResult.words.isEmpty
            ? 'No words found. Try again with better lighting.'
            : null,
      );
    } catch (e) {
      state = CaptureStatus(
        state: CaptureState.error,
        errorMessage: 'OCR failed: $e',
      );
    }
  }

  void reset() {
    state = const CaptureStatus();
  }
}

final captureProvider =
    NotifierProvider.family<CaptureNotifier, CaptureStatus, String>(
        CaptureNotifier.new);
