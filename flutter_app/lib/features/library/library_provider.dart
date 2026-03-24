import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/database.dart';
import '../../core/image/image_service.dart';

final booksProvider = StreamProvider<List<Book>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllBooks();
});

final bookPageCountProvider =
    FutureProvider.family<int, String>((ref, bookId) {
  final db = ref.watch(databaseProvider);
  return db.getPageCount(bookId);
});

final deleteBookProvider = Provider<Future<void> Function(String)>((ref) {
  final db = ref.read(databaseProvider);
  final imageService = ref.read(imageServiceProvider);

  return (String bookId) async {
    final pages = await db.getPagesForBook(bookId);
    for (final page in pages) {
      await imageService.deleteImage(page.imagePath);
    }
    final book = await db.getBook(bookId);
    if (book.coverImagePath != null) {
      await imageService.deleteImage(book.coverImagePath!);
    }
    await db.deleteBook(bookId);
  };
});
