import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../core/storage/database.dart' as db;
import 'book_provider.dart';

class PageCard extends ConsumerWidget {
  final db.Page page;
  final bool editMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback? onDelete;

  const PageCard({
    super.key,
    required this.page,
    this.editMode = false,
    required this.onTap,
    required this.onLongPress,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wordCount = ref.watch(wordCountProvider(page.id));

    return GestureDetector(
      onTap: editMode ? null : onTap,
      onLongPress: onLongPress,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: File(page.imagePath).existsSync()
                      ? Image.file(File(page.imagePath),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer,
                            child: const Icon(Icons.broken_image, size: 32),
                          ))
                      : Container(
                          color:
                              Theme.of(context).colorScheme.primaryContainer,
                          child: const Icon(Icons.broken_image, size: 32),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Page ${page.pageNumber}',
                          style: Theme.of(context).textTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      wordCount.when(
                        data: (count) => Text('$count words',
                            style: Theme.of(context).textTheme.bodySmall),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (editMode)
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: onDelete,
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
                    child: const Icon(Icons.delete, size: 18, color: AppColors.error),
                  ),
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }
}
