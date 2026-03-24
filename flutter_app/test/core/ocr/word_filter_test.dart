import 'package:flutter_test/flutter_test.dart';
import 'package:focus_read/core/ocr/word_filter.dart';

void main() {
  group('isRealWord', () {
    test('accepts normal words', () {
      expect(isRealWord('Hund'), true);
      expect(isRealWord('Waschbär'), true);
      expect(isRealWord('die'), true);
      expect(isRealWord('überhaupt'), true);
    });

    test('accepts single-char words a, i, o', () {
      expect(isRealWord('a'), true);
      expect(isRealWord('I'), true);
      expect(isRealWord('o'), true);
      expect(isRealWord('O'), true);
    });

    test('rejects single characters that are not a/i/o', () {
      expect(isRealWord('x'), false);
      expect(isRealWord('T'), false);
      expect(isRealWord('3'), false);
    });

    test('rejects pure numbers', () {
      expect(isRealWord('123'), false);
      expect(isRealWord('42'), false);
    });

    test('rejects mixed alpha+digit strings', () {
      expect(isRealWord('h3llo'), false);
      expect(isRealWord('abc123'), false);
      expect(isRealWord('4ever'), false);
    });

    test('rejects strings with brackets', () {
      expect(isRealWord('(TM)'), false);
      expect(isRealWord('[1]'), false);
      expect(isRealWord('{foo}'), false);
    });

    test('rejects abbreviation-like patterns (w.w)', () {
      expect(isRealWord('e.g'), false);
      expect(isRealWord('U.S.A'), false);
      expect(isRealWord('z.B'), false);
    });

    test('rejects empty/whitespace strings', () {
      expect(isRealWord(''), false);
      expect(isRealWord('  '), false);
    });

    test('accepts words with trailing punctuation', () {
      expect(isRealWord('Hund,'), true);
      expect(isRealWord('Ende.'), true);
      expect(isRealWord('was?'), true);
    });
  });

  group('filterAndSortWords', () {
    test('filters out low confidence words', () {
      final words = [
        _word('Hund', confidence: 0.95),
        _word('x3z', confidence: 0.90),
        _word('Katze', confidence: 0.50),
      ];
      final result = filterAndSortWords(words, confidenceThreshold: 0.85);
      expect(result.map((w) => w['text']), ['Hund']);
    });

    test('sorts by line then x position', () {
      final words = [
        _word('third', x: 300.0, y: 10.0),
        _word('first', x: 10.0, y: 10.0),
        _word('second', x: 150.0, y: 10.0),
        _word('fourth', x: 10.0, y: 100.0),
      ];
      final result = filterAndSortWords(words, confidenceThreshold: 0.0);
      expect(result.map((w) => w['text']), ['first', 'second', 'third', 'fourth']);
    });

    test('groups words into lines with tolerance', () {
      final words = [
        _word('b', x: 100.0, y: 15.0, h: 20.0),
        _word('a', x: 10.0, y: 10.0, h: 20.0),
        _word('c', x: 10.0, y: 100.0, h: 20.0),
      ];
      final result = filterAndSortWords(words, confidenceThreshold: 0.0);
      expect(result.map((w) => w['text']), ['a', 'b', 'c']);
    });
  });
}

Map<String, dynamic> _word(
  String text, {
  double x = 0,
  double y = 0,
  double w = 50,
  double h = 20,
  double confidence = 0.95,
}) =>
    {
      'text': text,
      'x': x,
      'y': y,
      'w': w,
      'h': h,
      'confidence': confidence,
    };
