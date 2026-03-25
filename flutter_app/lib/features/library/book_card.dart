import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/database.dart';
import 'library_provider.dart';

class BookCard extends ConsumerWidget {
  final Book book;
  final bool editMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  const BookCard({
    super.key,
    required this.book,
    this.editMode = false,
    required this.onTap,
    required this.onLongPress,
    this.onRename,
    this.onDelete,
  });

  Widget _placeholder(BuildContext context) => Container(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          Icons.menu_book,
          size: 48,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageCount = ref.watch(bookPageCountProvider(book.id));

    return GestureDetector(
      onTap: editMode ? null : onTap,
      onLongPress: onLongPress,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: book.coverImagePath != null &&
                          File(book.coverImagePath!).existsSync()
                      ? Image.file(
                          File(book.coverImagePath!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(context),
                        )
                      : Container(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(
                            Icons.menu_book,
                            size: 48,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      pageCount.when(
                        data: (count) => Text(
                          '$count ${count == 1 ? 'page' : 'pages'}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (editMode && (onRename != null || onDelete != null))
              Positioned(
                top: 4,
                right: 4,
                child: Column(
                  children: [
                    _EditButton(
                      icon: Icons.edit,
                      color: Theme.of(context).colorScheme.primary,
                      onTap: onRename,
                    ),
                    const SizedBox(height: 4),
                    _EditButton(
                      icon: Icons.delete,
                      color: Colors.red,
                      onTap: onDelete,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EditButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _EditButton({
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 4,
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
