import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/database.dart';
import '../../core/image/image_service.dart';

final bookProvider = FutureProvider.family<Book, String>((ref, bookId) {
  final db = ref.watch(databaseProvider);
  return db.getBook(bookId);
});

final pagesProvider = StreamProvider.family<List<Page>, String>((ref, bookId) {
  final db = ref.watch(databaseProvider);
  return db.watchPagesForBook(bookId);
});

final wordCountProvider =
    FutureProvider.family<int, String>((ref, pageId) async {
  final db = ref.watch(databaseProvider);
  final words = await db.getWordsForPage(pageId);
  return words.length;
});

final deletePageProvider = Provider<Future<void> Function(String, String)>((ref) {
  final db = ref.read(databaseProvider);
  final imageService = ref.read(imageServiceProvider);

  return (String pageId, String imagePath) async {
    await imageService.deleteImage(imagePath);
    await db.deletePage(pageId);
  };
});
