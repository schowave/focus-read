import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:focus_read/core/storage/database.dart';
import 'package:focus_read/core/ocr/word_filter.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('full flow: create book, add page with words, read them back', () async {
    // Create a book
    await db.insertBook(BooksCompanion.insert(
      id: 'book-1',
      title: 'Test Book',
    ));

    // Simulate OCR result
    final rawWords = [
      {'text': 'Der', 'x': 10.0, 'y': 10.0, 'w': 40.0, 'h': 20.0, 'confidence': 0.95},
      {'text': 'Hund', 'x': 60.0, 'y': 10.0, 'w': 50.0, 'h': 20.0, 'confidence': 0.92},
      {'text': 'x3z', 'x': 120.0, 'y': 10.0, 'w': 30.0, 'h': 20.0, 'confidence': 0.90},
      {'text': 'rennt', 'x': 10.0, 'y': 50.0, 'w': 55.0, 'h': 20.0, 'confidence': 0.88},
      {'text': '(1)', 'x': 200.0, 'y': 200.0, 'w': 20.0, 'h': 15.0, 'confidence': 0.99},
    ];

    final filtered = filterAndSortWords(rawWords, confidenceThreshold: 0.85);
    expect(filtered.length, 3); // Der, Hund, rennt — noise filtered out

    // Insert page
    await db.insertPage(PagesCompanion.insert(
      id: 'page-1',
      bookId: 'book-1',
      pageNumber: 1,
      imagePath: '/tmp/test.jpg',
      imageWidth: 800,
      imageHeight: 600,
      ocrCompleted: const Value(true),
    ));

    // Insert filtered words
    await db.insertWords(filtered.map((w) => WordsCompanion.insert(
          id: 'word-${w['sortIndex']}',
          pageId: 'page-1',
          textContent: w['text'] as String,
          x: (w['x'] as num).toDouble(),
          y: (w['y'] as num).toDouble(),
          w: (w['w'] as num).toDouble(),
          h: (w['h'] as num).toDouble(),
          confidence: (w['confidence'] as num).toDouble(),
          sortIndex: w['sortIndex'] as int,
        )).toList());

    // Read back
    final words = await db.getWordsForPage('page-1');
    expect(words.length, 3);
    expect(words[0].textContent, 'Der');
    expect(words[1].textContent, 'Hund');
    expect(words[2].textContent, 'rennt');

    // Verify reading order
    expect(words[0].sortIndex, lessThan(words[1].sortIndex));
    expect(words[1].sortIndex, lessThan(words[2].sortIndex));
  });
}
