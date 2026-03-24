import 'dart:io';
import 'dart:ui' show Size;
import 'package:image/image.dart' as img;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'word_filter.dart';

class OcrResult {
  final List<Map<String, dynamic>> words;
  final int imageWidth;
  final int imageHeight;

  OcrResult({
    required this.words,
    required this.imageWidth,
    required this.imageHeight,
  });
}

class OcrService {
  TextRecognizer? _recognizer;

  TextRecognizer _getRecognizer() {
    _recognizer?.close();
    _recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    return _recognizer!;
  }

  Future<OcrResult> processImage(
    String imagePath, {
    double confidenceThreshold = 0.85,
  }) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizer = _getRecognizer();
    final recognizedText = await recognizer.processImage(inputImage);

    final rawWords = <Map<String, dynamic>>[];
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        for (final element in line.elements) {
          final rect = element.boundingBox;
          // confidence is double? — available on Android, null on iOS.
          // Fall back to 1.0 so words are not filtered out on iOS.
          final confidence = element.confidence ?? 1.0;

          rawWords.add({
            'text': element.text,
            'x': rect.left,
            'y': rect.top,
            'w': rect.width,
            'h': rect.height,
            'confidence': confidence,
          });
        }
      }
    }

    final imageSize = await _getImageSize(imagePath);

    final filtered = filterAndSortWords(
      rawWords,
      confidenceThreshold: confidenceThreshold,
    );

    return OcrResult(
      words: filtered,
      imageWidth: imageSize.width.round(),
      imageHeight: imageSize.height.round(),
    );
  }

  Future<Size> _getImageSize(String path) async {
    final bytes = await File(path).readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return const Size(0, 0);
    return Size(image.width.toDouble(), image.height.toDouble());
  }

  void dispose() {
    _recognizer?.close();
  }
}

final ocrServiceProvider = Provider<OcrService>((ref) {
  final service = OcrService();
  ref.onDispose(() => service.dispose());
  return service;
});
