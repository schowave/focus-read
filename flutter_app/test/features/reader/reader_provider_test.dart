import 'package:flutter_test/flutter_test.dart';
import 'package:focus_read/features/reader/reader_provider.dart';

void main() {
  group('ReaderState', () {
    final words = [
      {'text': 'Der', 'sortIndex': 0},
      {'text': 'Hund', 'sortIndex': 1},
      {'text': 'rennt', 'sortIndex': 2},
    ];

    test('starts at word 0', () {
      final state = ReaderState(words: words, currentIndex: 0, totalPages: 3, currentPage: 1);
      expect(state.currentWord, 'Der');
      expect(state.isFirstWord, true);
      expect(state.isLastWord, false);
      expect(state.progress, '1/3');
    });

    test('advances to next word', () {
      final state = ReaderState(words: words, currentIndex: 0, totalPages: 3, currentPage: 1);
      final next = state.advance(1);
      expect(next.currentWord, 'Hund');
      expect(next.currentIndex, 1);
    });

    test('does not go below 0', () {
      final state = ReaderState(words: words, currentIndex: 0, totalPages: 3, currentPage: 1);
      final prev = state.advance(-1);
      expect(prev.currentIndex, 0);
    });

    test('does not go past last word', () {
      final state = ReaderState(words: words, currentIndex: 2, totalPages: 3, currentPage: 1);
      expect(state.isLastWord, true);
      final next = state.advance(1);
      expect(next.currentIndex, 2);
    });

    test('jumps to specific word', () {
      final state = ReaderState(words: words, currentIndex: 0, totalPages: 3, currentPage: 1);
      final jumped = state.jumpTo(2);
      expect(jumped.currentWord, 'rennt');
    });
  });
}
