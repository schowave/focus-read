import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../shared/adaptive/platform_utils.dart';

class CreateBookResult {
  final String title;
  final String language;
  CreateBookResult({required this.title, required this.language});
}

Future<CreateBookResult?> showCreateBookDialog(
  BuildContext context, {
  required int bookNumber,
  String defaultLanguage = 'de',
}) async {
  final titleController = TextEditingController(text: 'Book $bookNumber');
  var selectedLanguage = defaultLanguage;

  const languages = {
    'de': 'Deutsch',
    'en': 'English',
    'fr': 'Français',
    'es': 'Español',
    'pt': 'Português',
    'it': 'Italiano',
    'nl': 'Nederlands',
  };

  if (isIOSPlatform) {
    return showCupertinoDialog<CreateBookResult>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => CupertinoAlertDialog(
          title: const Text('New Book'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: titleController,
                placeholder: 'Title',
                autofocus: true,
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final result = await showCupertinoModalPopup<String>(
                    context: context,
                    builder: (context) => CupertinoActionSheet(
                      title: const Text('Language'),
                      actions: languages.entries
                          .map((e) => CupertinoActionSheetAction(
                                onPressed: () => Navigator.of(context).pop(e.key),
                                child: Text(e.value),
                              ))
                          .toList(),
                      cancelButton: CupertinoActionSheetAction(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                  );
                  if (result != null) {
                    setState(() => selectedLanguage = result);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: CupertinoColors.systemGrey4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(languages[selectedLanguage] ?? selectedLanguage),
                      const Icon(CupertinoIcons.chevron_down, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isEmpty) return;
                Navigator.of(context).pop(
                  CreateBookResult(title: title, language: selectedLanguage),
                );
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  return showDialog<CreateBookResult>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('New Book'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedLanguage,
              decoration: const InputDecoration(
                labelText: 'Language',
                border: OutlineInputBorder(),
              ),
              items: languages.entries
                  .map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => selectedLanguage = value);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isEmpty) return;
              Navigator.of(context).pop(
                CreateBookResult(title: title, language: selectedLanguage),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    ),
  );
}
