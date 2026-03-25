import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'database.g.dart';

class Books extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get language => text().withDefault(const Constant('de'))();
  TextColumn get coverImagePath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Pages extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text().references(Books, #id)();
  IntColumn get pageNumber => integer()();
  TextColumn get imagePath => text()();
  IntColumn get imageWidth => integer()();
  IntColumn get imageHeight => integer()();
  BoolColumn get ocrCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Words extends Table {
  TextColumn get id => text()();
  TextColumn get pageId => text().references(Pages, #id)();
  TextColumn get textContent => text().named('text_content')();
  RealColumn get x => real()();
  RealColumn get y => real()();
  RealColumn get w => real()();
  RealColumn get h => real()();
  RealColumn get confidence => real()();
  IntColumn get sortIndex => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Books, Pages, Words])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  // Book queries
  Future<List<Book>> getAllBooks() =>
      (select(books)..orderBy([(b) => OrderingTerm.desc(b.updatedAt)])).get();

  Stream<List<Book>> watchAllBooks() =>
      (select(books)..orderBy([(b) => OrderingTerm.desc(b.updatedAt)])).watch();

  Future<Book> getBook(String id) =>
      (select(books)..where((b) => b.id.equals(id))).getSingle();

  Future<void> insertBook(BooksCompanion book) => into(books).insert(book);

  Future<void> updateBook(BooksCompanion book) =>
      (update(books)..where((b) => b.id.equals(book.id.value))).write(book);

  Future<void> deleteBook(String id) async {
    final pageIds = await (select(pages)..where((p) => p.bookId.equals(id)))
        .map((p) => p.id)
        .get();
    for (final pageId in pageIds) {
      await (delete(words)..where((w) => w.pageId.equals(pageId))).go();
    }
    await (delete(pages)..where((p) => p.bookId.equals(id))).go();
    await (delete(books)..where((b) => b.id.equals(id))).go();
  }

  // Page queries
  Future<List<Page>> getPagesForBook(String bookId) =>
      (select(pages)
            ..where((p) => p.bookId.equals(bookId))
            ..orderBy([(p) => OrderingTerm.asc(p.pageNumber)]))
          .get();

  Stream<List<Page>> watchPagesForBook(String bookId) =>
      (select(pages)
            ..where((p) => p.bookId.equals(bookId))
            ..orderBy([(p) => OrderingTerm.asc(p.pageNumber)]))
          .watch();

  Future<void> insertPage(PagesCompanion page) => into(pages).insert(page);

  Future<void> deletePage(String id) async {
    await (delete(words)..where((w) => w.pageId.equals(id))).go();
    await (delete(pages)..where((p) => p.id.equals(id))).go();
  }

  // Word queries
  Future<List<Word>> getWordsForPage(String pageId) =>
      (select(words)
            ..where((w) => w.pageId.equals(pageId))
            ..orderBy([(w) => OrderingTerm.asc(w.sortIndex)]))
          .get();

  Future<void> insertWords(List<WordsCompanion> wordList) async {
    await batch((b) => b.insertAll(words, wordList));
  }

  // Page count for a book
  Future<int> getPageCount(String bookId) async {
    final count = countAll();
    final query = selectOnly(pages)
      ..addColumns([count])
      ..where(pages.bookId.equals(bookId));
    final result = await query.getSingle();
    return result.read(count)!;
  }

  Stream<int> watchPageCount(String bookId) {
    final count = countAll();
    final query = selectOnly(pages)
      ..addColumns([count])
      ..where(pages.bookId.equals(bookId));
    return query.watchSingle().map((row) => row.read(count)!);
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'focus_read.db'));
    return NativeDatabase.createInBackground(file);
  });
}

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});
