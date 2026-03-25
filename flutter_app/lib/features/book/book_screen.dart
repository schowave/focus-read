import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/storage/database.dart' as db;
import '../../shared/confirm_dialog.dart';
import 'book_provider.dart';
import 'page_card.dart';

class BookScreen extends ConsumerWidget {
  final String bookId;

  const BookScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookAsync = ref.watch(bookProvider(bookId));
    final pagesAsync = ref.watch(pagesProvider(bookId));
    final deletePage = ref.read(deletePageProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: bookAsync.when(
          data: (book) => Text(book.title),
          loading: () => const Text(''),
          error: (_, __) => const Text('Book'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            tooltip: 'Add page',
            onPressed: () => context.push('/book/$bookId/capture'),
          ),
        ],
      ),
      body: pagesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (pages) {
          if (pages.isEmpty) {
            return _EmptyState(
              onAddPage: () => context.push('/book/$bookId/capture'),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.75,
            ),
            itemCount: pages.length,
            itemBuilder: (context, index) {
              final page = pages[index];
              return PageCard(
                page: page,
                onTap: () => context.push('/book/$bookId/read/${page.id}'),
                onLongPress: () => _showPageOptions(
                  context,
                  page,
                  deletePage,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showPageOptions(
    BuildContext context,
    db.Page page,
    Future<void> Function(String, String) deletePage,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Delete Page',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                await _deletePage(context, page, deletePage);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePage(
    BuildContext context,
    db.Page page,
    Future<void> Function(String, String) deletePage,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Page',
      message:
          'Are you sure you want to delete page ${page.pageNumber}? This cannot be undone.',
      confirmLabel: 'Delete',
      confirmColor: Colors.red,
    );

    if (confirmed) {
      await deletePage(page.id, page.imagePath);
    }
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddPage;

  const _EmptyState({required this.onAddPage});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_alt,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'No pages yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: onAddPage,
            icon: const Icon(Icons.add),
            label: const Text('Add first page'),
          ),
        ],
      ),
    );
  }
}
