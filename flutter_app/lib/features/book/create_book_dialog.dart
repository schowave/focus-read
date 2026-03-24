import 'package:flutter/material.dart';

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
