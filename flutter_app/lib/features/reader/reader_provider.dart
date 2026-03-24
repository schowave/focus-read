import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/database.dart' as db;

class ReaderState {
  final List<Map<String, dynamic>> words;
  final int currentIndex;
  final int totalPages;
  final int currentPage;

  const ReaderState({
    required this.words,
    required this.currentIndex,
    required this.totalPages,
    required this.currentPage,
  });

  bool get isEmpty => words.isEmpty;

  String? get currentWord {
    if (isEmpty) return null;
    return words[currentIndex]['text'] as String?;
  }

  bool get isFirstWord => currentIndex == 0;

  bool get isLastWord => isEmpty ? true : currentIndex == words.length - 1;

  String get progress => '$currentPage/$totalPages';

  ReaderState advance(int direction) {
    if (isEmpty) return this;
    final next = currentIndex + direction;
    if (next < 0) return copyWith(currentIndex: 0);
    if (next >= words.length) return copyWith(currentIndex: words.length - 1);
    return copyWith(currentIndex: next);
  }

  ReaderState jumpTo(int index) {
    if (isEmpty) return this;
    final clamped = index.clamp(0, words.length - 1);
    return copyWith(currentIndex: clamped);
  }

  ReaderState copyWith({
    List<Map<String, dynamic>>? words,
    int? currentIndex,
    int? totalPages,
    int? currentPage,
  }) {
    return ReaderState(
      words: words ?? this.words,
      currentIndex: currentIndex ?? this.currentIndex,
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class ReaderNotifier extends FamilyNotifier<ReaderState, String> {
  @override
  ReaderState build(String arg) {
    _load(arg);
    return ReaderState(
      words: const [],
      currentIndex: 0,
      totalPages: 1,
      currentPage: 1,
    );
  }

  Future<void> _load(String pageId) async {
    final database = ref.read(db.databaseProvider);

    // Load words for page
    final wordList = await database.getWordsForPage(pageId);
    final wordMaps = wordList
        .map((w) => <String, dynamic>{
              'text': w.textContent,
              'x': w.x,
              'y': w.y,
              'w': w.w,
              'h': w.h,
              'sortIndex': w.sortIndex,
            })
        .toList();

    // Get page info for page number and total
    int currentPage = 1;
    int totalPages = 1;

    // Try to get page info from the pages table via a workaround
    try {
      // Use Drift select directly — we need page data
      // Since database.dart exposes getPagesForBook but not getPage(id),
      // we need to get bookId first. We'll use a custom query via the exposed tables.
      // Actually we can get all pages sorted and find our pageId position.
      // The simplest approach: query all pages that share the same bookId.
      // We need to find bookId for this pageId. Use selectOnly on pages table.
      final pageRow = await (database.select(database.pages)
            ..where((p) => p.id.equals(pageId)))
          .getSingle();
      final allPages = await database.getPagesForBook(pageRow.bookId);
      currentPage = pageRow.pageNumber;
      totalPages = allPages.length;
    } catch (_) {
      // If page lookup fails, keep defaults
    }

    state = ReaderState(
      words: wordMaps,
      currentIndex: 0,
      totalPages: totalPages,
      currentPage: currentPage,
    );
  }

  void advance(int direction) {
    state = state.advance(direction);
  }

  void jumpTo(int index) {
    state = state.jumpTo(index);
  }
}

final readerProvider =
    NotifierProvider.family<ReaderNotifier, ReaderState, String>(
  ReaderNotifier.new,
);
