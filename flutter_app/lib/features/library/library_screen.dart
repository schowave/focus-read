import 'package:drift/drift.dart' show Value;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/storage/database.dart';
import '../../features/settings/settings_provider.dart';
import '../../shared/adaptive/adaptive_scaffold.dart';
import '../../shared/adaptive/adaptive_progress_indicator.dart';
import '../../shared/adaptive/adaptive_action_sheet.dart';
import '../../shared/adaptive/platform_utils.dart';
import '../../shared/confirm_dialog.dart';
import '../book/create_book_dialog.dart';
import 'book_card.dart';
import 'library_provider.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  bool _editMode = false;

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(booksProvider);
    final settings = ref.watch(settingsProvider);
    final deleteBook = ref.read(deleteBookProvider);
    final db = ref.read(databaseProvider);

    return AdaptiveScaffold(
      title: 'Focus Read',
      actions: [
        IconButton(
          icon: Icon(_editMode ? Icons.done : Icons.edit),
          tooltip: _editMode ? 'Done' : 'Edit',
          onPressed: () => setState(() => _editMode = !_editMode),
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          tooltip: 'Settings',
          onPressed: () => context.push('/settings'),
        ),
      ],
      body: booksAsync.when(
        loading: () => const Center(child: AdaptiveProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (books) {
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
              if (index == books.length) {
                return _AddBookCard(
                  onTap: () => _createBook(context, books.length, settings, db),
                );
              }

              final book = books[index];
              return BookCard(
                book: book,
                editMode: _editMode,
                onTap: () => context.push('/book/${book.id}'),
                onLongPress: () =>
                    _showBookOptions(context, book, deleteBook, db),
                onRename: () => _renameBook(context, book, db),
                onDelete: () => _deleteBook(context, book, deleteBook),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _createBook(
    BuildContext context,
    int bookCount,
    AppSettings settings,
    AppDatabase db,
  ) async {
    final result = await showCreateBookDialog(
      context,
      bookNumber: bookCount + 1,
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
  }

  Future<void> _showBookOptions(
    BuildContext context,
    Book book,
    Future<void> Function(String) deleteBook,
    AppDatabase db,
  ) async {
    await showAdaptiveActionSheet(
      context,
      actions: [
        AdaptiveAction(
          label: 'Rename',
          icon: Icons.edit,
          onPressed: () => _renameBook(context, book, db),
        ),
        AdaptiveAction(
          label: 'Delete',
          icon: Icons.delete,
          isDestructive: true,
          onPressed: () => _deleteBook(context, book, deleteBook),
        ),
      ],
    );
  }

  Future<void> _renameBook(
    BuildContext context,
    Book book,
    AppDatabase db,
  ) async {
    final controller = TextEditingController(text: book.title);
    final String? newTitle;

    if (isIOSPlatform) {
      newTitle = await showCupertinoDialog<String>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Rename Book'),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: CupertinoTextField(
              controller: controller,
              placeholder: 'Title',
              autofocus: true,
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
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
    } else {
      newTitle = await showDialog<String>(
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
    }

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
