import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/database.dart' as db;
import 'book_provider.dart';

class PageCard extends ConsumerWidget {
  final db.Page page;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const PageCard({
    super.key,
    required this.page,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wordCount = ref.watch(wordCountProvider(page.id));

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Image.file(File(page.imagePath), fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Page ${page.pageNumber}',
                      style: Theme.of(context).textTheme.titleSmall),
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
      ),
    );
  }
}
