import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/storage/database.dart';
import '../../features/settings/settings_provider.dart';
import '../../shared/confirm_dialog.dart';
import '../book/create_book_dialog.dart';
import 'book_card.dart';
import 'library_provider.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(booksProvider);
    final settings = ref.watch(settingsProvider);
    final deleteBook = ref.read(deleteBookProvider);
    final db = ref.read(databaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Read'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: booksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (books) {
          // Total items = books + 1 "add" card
          final itemCount = books.length + 1;

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.7,
            ),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              // Last item is the "add new book" card
              if (index == books.length) {
                return _AddBookCard(
                  onTap: () async {
                    final result = await showCreateBookDialog(
                      context,
                      bookNumber: books.length + 1,
                      defaultLanguage: settings.appLanguage,
                    );
                    if (result == null) return;

                    final id = const Uuid().v4();
                    await db.insertBook(
                      BooksCompanion(
                        id: Value(id),
                        title: Value(result.title),
                        language: Value(result.language),
                      ),
                    );

                    if (context.mounted) {
                      context.push('/book/$id');
                    }
                  },
                );
              }

              final book = books[index];
              return BookCard(
                book: book,
                onTap: () => context.push('/book/${book.id}'),
                onLongPress: () =>
                    _showBookOptions(context, ref, book, deleteBook, db),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showBookOptions(
    BuildContext context,
    WidgetRef ref,
    Book book,
    Future<void> Function(String) deleteBook,
    AppDatabase db,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Rename'),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                await _renameBook(context, book, db);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title:
                  const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                await _deleteBook(context, book, deleteBook);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _renameBook(
    BuildContext context,
    Book book,
    AppDatabase db,
  ) async {
    final controller = TextEditingController(text: book.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Book'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Title',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final title = controller.text.trim();
              if (title.isEmpty) return;
              Navigator.of(context).pop(title);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (newTitle != null && newTitle.isNotEmpty) {
      await db.updateBook(
        BooksCompanion(
          id: Value(book.id),
          title: Value(newTitle),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  Future<void> _deleteBook(
    BuildContext context,
    Book book,
    Future<void> Function(String) deleteBook,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Book',
      message: 'Are you sure you want to delete "${book.title}"? '
          'This will remove all pages and cannot be undone.',
      confirmLabel: 'Delete',
      confirmColor: Colors.red,
    );

    if (confirmed) {
      await deleteBook(book.id);
    }
  }
}

class _AddBookCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddBookCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              'New Book',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
