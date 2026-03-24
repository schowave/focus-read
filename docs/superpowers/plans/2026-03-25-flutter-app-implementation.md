# Focus Read Flutter App — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native Flutter app for iOS and Android that lets children photograph book pages, runs on-device OCR, and guides word-by-word reading with highlighting and TTS.

**Architecture:** Feature-based Flutter project with Riverpod for state, Drift (SQLite) for persistence, Google ML Kit for on-device OCR, and flutter_tts for speech. All processing happens on-device — no backend server.

**Tech Stack:** Flutter 3.x, Dart, Riverpod, Drift, go_router, google_mlkit_text_recognition, camera, flutter_tts, image_picker

**Spec:** `docs/superpowers/specs/2026-03-24-flutter-app-design.md`

---

## File Map

```
flutter_app/                          # New Flutter project alongside existing web app
├── lib/
│   ├── main.dart                     # App entry point, ProviderScope
│   ├── app/
│   │   ├── app.dart                  # MaterialApp.router, theme
│   │   ├── router.dart               # GoRouter config
│   │   └── theme.dart                # App theme (warm, child-friendly)
│   ├── core/
│   │   ├── ocr/
│   │   │   ├── ocr_service.dart      # ML Kit integration
│   │   │   └── word_filter.dart      # Noise filter (ported from Python)
│   │   ├── tts/
│   │   │   └── tts_service.dart      # TTS abstraction
│   │   ├── storage/
│   │   │   ├── database.dart         # Drift database definition
│   │   │   └── database.g.dart       # Generated code
│   │   ├── image/
│   │   │   └── image_service.dart    # Image compression & storage
│   │   └── l10n/
│   │       ├── app_de.arb            # German strings
│   │       └── app_en.arb            # English strings
│   ├── features/
│   │   ├── library/
│   │   │   ├── library_screen.dart   # Book grid (home screen)
│   │   │   ├── library_provider.dart # Riverpod provider for books
│   │   │   └── book_card.dart        # Single book card widget
│   │   ├── book/
│   │   │   ├── book_screen.dart      # Page grid for one book
│   │   │   ├── book_provider.dart    # Riverpod provider for pages
│   │   │   ├── page_card.dart        # Single page thumbnail widget
│   │   │   └── create_book_dialog.dart # New book dialog
│   │   ├── capture/
│   │   │   ├── capture_screen.dart   # Camera preview + shutter + photo confirmation
│   │   │   └── capture_provider.dart # OCR processing state
│   │   ├── reader/
│   │   │   ├── reader_screen.dart    # Main reading experience
│   │   │   ├── reader_provider.dart  # Word navigation state
│   │   │   ├── word_overlay.dart     # Single word overlay widget
│   │   │   └── control_bar.dart      # Bottom bar (TTS, nav, counter)
│   │   └── settings/
│   │       ├── settings_screen.dart  # Settings UI
│   │       └── settings_provider.dart # Settings state (shared_preferences)
│   └── shared/
│       ├── models.dart               # Age group enum, constants
│       └── confirm_dialog.dart       # Reusable delete confirmation
├── test/
│   ├── core/
│   │   ├── ocr/
│   │   │   └── word_filter_test.dart
│   │   └── tts/
│   │       └── tts_service_test.dart
│   ├── features/
│   │   ├── reader/
│   │   │   └── reader_provider_test.dart
│   │   └── library/
│   │       └── library_provider_test.dart
│   └── integration/
│       └── capture_to_read_test.dart
├── pubspec.yaml
├── analysis_options.yaml
├── android/
│   └── app/src/main/AndroidManifest.xml  # Camera permission
└── ios/
    └── Runner/Info.plist                  # Camera permission strings
```

---

## Task 1: Flutter Project Scaffold

**Files:**
- Create: `flutter_app/` (entire scaffold)
- Create: `flutter_app/pubspec.yaml`
- Create: `flutter_app/lib/main.dart`
- Create: `flutter_app/lib/app/app.dart`

- [ ] **Step 1: Create Flutter project**

```bash
cd /Users/dsh/repos/privat/focus-read
flutter create flutter_app --org com.focusread --project-name focus_read
```

- [ ] **Step 2: Configure pubspec.yaml dependencies**

Replace `flutter_app/pubspec.yaml` dependencies section with:

```yaml
name: focus_read
description: Reading aid for children — photograph book pages and read word by word.
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ^3.8.0

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: any

  # State management
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1

  # Routing
  go_router: ^14.8.1

  # Database
  drift: ^2.22.1
  sqlite3_flutter_libs: ^0.5.28
  path_provider: ^2.1.5
  path: ^1.9.1

  # OCR
  google_mlkit_text_recognition: ^0.15.0

  # Camera & image
  camera: ^0.11.0+2
  image_picker: ^1.1.2
  image: ^4.5.3

  # TTS
  flutter_tts: ^4.2.0

  # Utils
  uuid: ^4.5.1
  shared_preferences: ^2.3.4

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  build_runner: ^2.4.13
  drift_dev: ^2.22.1
  riverpod_generator: ^2.6.3
  mockito: ^5.4.4
  build_verify: ^3.1.0

flutter:
  generate: true
  uses-material-design: true
```

- [ ] **Step 3: Configure l10n.yaml**

Create `flutter_app/l10n.yaml`:

```yaml
arb-dir: lib/core/l10n
template-arb-file: app_de.arb
output-localization-file: app_localizations.dart
```

- [ ] **Step 4: Create minimal ARB files**

Create `flutter_app/lib/core/l10n/app_de.arb`:

```json
{
  "@@locale": "de",
  "appTitle": "Focus Read",
  "library": "Bibliothek",
  "settings": "Einstellungen",
  "newBook": "Neues Buch",
  "cancel": "Abbrechen",
  "delete": "Löschen",
  "confirm": "Bestätigen"
}
```

Create `flutter_app/lib/core/l10n/app_en.arb`:

```json
{
  "@@locale": "en",
  "appTitle": "Focus Read",
  "library": "Library",
  "settings": "Settings",
  "newBook": "New Book",
  "cancel": "Cancel",
  "delete": "Delete",
  "confirm": "Confirm"
}
```

- [ ] **Step 5: Create app entry point**

Create `flutter_app/lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: FocusReadApp()));
}
```

Create `flutter_app/lib/app/app.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../features/settings/settings_provider.dart';
import 'router.dart';
import 'theme.dart';

class FocusReadApp extends ConsumerWidget {
  const FocusReadApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp.router(
      title: 'Focus Read',
      theme: focusReadTheme,
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale(settings.appLanguage),
    );
  }
}
```

- [ ] **Step 6: Create placeholder router**

Create `flutter_app/lib/app/router.dart`:

```dart
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const Scaffold(
        body: Center(child: Text('Focus Read')),
      ),
    ),
  ],
);
```

- [ ] **Step 7: Create theme**

Create `flutter_app/lib/app/theme.dart`:

```dart
import 'package:flutter/material.dart';

final focusReadTheme = ThemeData(
  useMaterial3: true,
  colorSchemeSeed: const Color(0xFFE8A87C), // Warm orange
  brightness: Brightness.light,
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    elevation: 0,
  ),
  cardTheme: CardTheme(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(48, 56),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  ),
);
```

- [ ] **Step 8: Install dependencies and verify build**

```bash
cd /Users/dsh/repos/privat/focus-read/flutter_app
flutter pub get
flutter analyze
```

- [ ] **Step 9: Commit**

```bash
git add flutter_app/
git commit -m "feat: scaffold Flutter project with dependencies and theme"
```

---

## Task 2: Shared Models & Constants

**Files:**
- Create: `flutter_app/lib/shared/models.dart`

- [ ] **Step 1: Create shared models**

Create `flutter_app/lib/shared/models.dart`:

```dart
enum AgeGroup {
  preschool,    // 4-6
  earlyPrimary, // 6-8
  latePrimary,  // 8-10
}

extension AgeGroupConfig on AgeGroup {
  double get buttonScale => switch (this) {
    AgeGroup.preschool => 1.4,
    AgeGroup.earlyPrimary => 1.2,
    AgeGroup.latePrimary => 1.0,
  };

  double get highlightOpacity => switch (this) {
    AgeGroup.preschool => 0.85,
    AgeGroup.earlyPrimary => 0.6,
    AgeGroup.latePrimary => 0.35,
  };

  double get dimOpacity => switch (this) {
    AgeGroup.preschool => 0.8,
    AgeGroup.earlyPrimary => 0.5,
    AgeGroup.latePrimary => 0.25,
  };

  bool get autoTtsDefault => switch (this) {
    AgeGroup.preschool => true,
    AgeGroup.earlyPrimary => true,
    AgeGroup.latePrimary => false,
  };
}
```

- [ ] **Step 2: Commit**

```bash
git add flutter_app/lib/shared/
git commit -m "feat: add AgeGroup enum with age-adaptive config"
```

---

## Task 3: Drift Database

**Files:**
- Create: `flutter_app/lib/core/storage/database.dart`
- Generate: `flutter_app/lib/core/storage/database.g.dart`

- [ ] **Step 1: Create Drift database schema**

Create `flutter_app/lib/core/storage/database.dart`:

```dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'database.g.dart';

class Books extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get language => text().withDefault(const Constant('de'))();
  TextColumn get coverImagePath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Pages extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text().references(Books, #id)();
  IntColumn get pageNumber => integer()();
  TextColumn get imagePath => text()();
  IntColumn get imageWidth => integer()();
  IntColumn get imageHeight => integer()();
  BoolColumn get ocrCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Words extends Table {
  TextColumn get id => text()();
  TextColumn get pageId => text().references(Pages, #id)();
  TextColumn get textContent => text().named('text_content')();
  RealColumn get x => real()();
  RealColumn get y => real()();
  RealColumn get w => real()();
  RealColumn get h => real()();
  RealColumn get confidence => real()();
  IntColumn get sortIndex => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Books, Pages, Words])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  // Book queries
  Future<List<Book>> getAllBooks() =>
      (select(books)..orderBy([(b) => OrderingTerm.desc(b.updatedAt)])).get();

  Stream<List<Book>> watchAllBooks() =>
      (select(books)..orderBy([(b) => OrderingTerm.desc(b.updatedAt)])).watch();

  Future<Book> getBook(String id) =>
      (select(books)..where((b) => b.id.equals(id))).getSingle();

  Future<void> insertBook(BooksCompanion book) => into(books).insert(book);

  Future<void> updateBook(BooksCompanion book) =>
      (update(books)..where((b) => b.id.equals(book.id.value))).write(book);

  Future<void> deleteBook(String id) async {
    // Delete all words for all pages of this book
    final pageIds = await (select(pages)..where((p) => p.bookId.equals(id)))
        .map((p) => p.id)
        .get();
    for (final pageId in pageIds) {
      await (delete(words)..where((w) => w.pageId.equals(pageId))).go();
    }
    await (delete(pages)..where((p) => p.bookId.equals(id))).go();
    await (delete(books)..where((b) => b.id.equals(id))).go();
  }

  // Page queries
  Future<List<Page>> getPagesForBook(String bookId) =>
      (select(pages)
            ..where((p) => p.bookId.equals(bookId))
            ..orderBy([(p) => OrderingTerm.asc(p.pageNumber)]))
          .get();

  Stream<List<Page>> watchPagesForBook(String bookId) =>
      (select(pages)
            ..where((p) => p.bookId.equals(bookId))
            ..orderBy([(p) => OrderingTerm.asc(p.pageNumber)]))
          .watch();

  Future<void> insertPage(PagesCompanion page) => into(pages).insert(page);

  Future<void> deletePage(String id) async {
    await (delete(words)..where((w) => w.pageId.equals(id))).go();
    await (delete(pages)..where((p) => p.id.equals(id))).go();
  }

  // Word queries
  Future<List<Word>> getWordsForPage(String pageId) =>
      (select(words)
            ..where((w) => w.pageId.equals(pageId))
            ..orderBy([(w) => OrderingTerm.asc(w.sortIndex)]))
          .get();

  Future<void> insertWords(List<WordsCompanion> wordList) async {
    await batch((b) => b.insertAll(words, wordList));
  }

  // Page count for a book
  Future<int> getPageCount(String bookId) async {
    final count = countAll();
    final query = selectOnly(pages)
      ..addColumns([count])
      ..where(pages.bookId.equals(bookId));
    final result = await query.getSingle();
    return result.read(count)!;
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'focus_read.db'));
    return NativeDatabase.createInBackground(file);
  });
}

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});
```

- [ ] **Step 2: Run Drift code generation**

```bash
cd /Users/dsh/repos/privat/focus-read/flutter_app
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 3: Verify build passes**

```bash
cd /Users/dsh/repos/privat/focus-read/flutter_app
flutter analyze
```

- [ ] **Step 4: Commit**

```bash
git add flutter_app/lib/core/storage/
git commit -m "feat: add Drift database with Book, Page, Word tables"
```

---

## Task 4: Word Filter (TDD — ported from Python)

**Files:**
- Create: `flutter_app/lib/core/ocr/word_filter.dart`
- Create: `flutter_app/test/core/ocr/word_filter_test.dart`

- [ ] **Step 1: Write failing tests**

Create `flutter_app/test/core/ocr/word_filter_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_read/core/ocr/word_filter.dart';

void main() {
  group('isRealWord', () {
    test('accepts normal words', () {
      expect(isRealWord('Hund'), true);
      expect(isRealWord('Waschbär'), true);
      expect(isRealWord('die'), true);
      expect(isRealWord('überhaupt'), true);
    });

    test('accepts single-char words a, i, o', () {
      expect(isRealWord('a'), true);
      expect(isRealWord('I'), true);
      expect(isRealWord('o'), true);
      expect(isRealWord('O'), true);
    });

    test('rejects single characters that are not a/i/o', () {
      expect(isRealWord('x'), false);
      expect(isRealWord('T'), false);
      expect(isRealWord('3'), false);
    });

    test('rejects pure numbers', () {
      expect(isRealWord('123'), false);
      expect(isRealWord('42'), false);
    });

    test('rejects mixed alpha+digit strings', () {
      expect(isRealWord('h3llo'), false);
      expect(isRealWord('abc123'), false);
      expect(isRealWord('4ever'), false);
    });

    test('rejects strings with brackets', () {
      expect(isRealWord('(TM)'), false);
      expect(isRealWord('[1]'), false);
      expect(isRealWord('{foo}'), false);
    });

    test('rejects abbreviation-like patterns (w.w)', () {
      expect(isRealWord('e.g'), false);
      expect(isRealWord('U.S.A'), false);
      expect(isRealWord('z.B'), false);
    });

    test('rejects empty/whitespace strings', () {
      expect(isRealWord(''), false);
      expect(isRealWord('  '), false);
    });

    test('accepts words with trailing punctuation', () {
      expect(isRealWord('Hund,'), true);
      expect(isRealWord('Ende.'), true);
      expect(isRealWord('was?'), true);
    });
  });

  group('filterAndSortWords', () {
    test('filters out low confidence words', () {
      final words = [
        _word('Hund', confidence: 0.95),
        _word('x3z', confidence: 0.90),
        _word('Katze', confidence: 0.50),
      ];
      final result = filterAndSortWords(words, confidenceThreshold: 0.85);
      expect(result.map((w) => w['text']), ['Hund']);
    });

    test('sorts by line then x position', () {
      final words = [
        _word('third', x: 300.0, y: 10.0),
        _word('first', x: 10.0, y: 10.0),
        _word('second', x: 150.0, y: 10.0),
        _word('fourth', x: 10.0, y: 100.0),
      ];
      final result = filterAndSortWords(words, confidenceThreshold: 0.0);
      expect(result.map((w) => w['text']), ['first', 'second', 'third', 'fourth']);
    });

    test('groups words into lines with tolerance', () {
      // Words at y=10 and y=15 should be same line (within tolerance)
      // Word at y=100 is a different line
      final words = [
        _word('b', x: 100.0, y: 15.0, h: 20.0),
        _word('a', x: 10.0, y: 10.0, h: 20.0),
        _word('c', x: 10.0, y: 100.0, h: 20.0),
      ];
      final result = filterAndSortWords(words, confidenceThreshold: 0.0);
      expect(result.map((w) => w['text']), ['a', 'b', 'c']);
    });
  });
}

Map<String, dynamic> _word(
  String text, {
  double x = 0,
  double y = 0,
  double w = 50,
  double h = 20,
  double confidence = 0.95,
}) =>
    {
      'text': text,
      'x': x,
      'y': y,
      'w': w,
      'h': h,
      'confidence': confidence,
    };
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd /Users/dsh/repos/privat/focus-read/flutter_app
flutter test test/core/ocr/word_filter_test.dart
```

Expected: FAIL — `word_filter.dart` does not exist yet.

- [ ] **Step 3: Implement word filter**

Create `flutter_app/lib/core/ocr/word_filter.dart`:

```dart
/// Returns true if the word is likely a real word (not barcode/logo noise).
/// Ported from Python backend/ocr.py `_is_real_word`.
bool isRealWord(String text) {
  // Strip non-word characters to get core
  final core = text.replaceAll(RegExp(r'[^\w]', unicode: true), '');
  if (core.isEmpty) return false;

  // Single char: only allow a, i, o
  if (core.length == 1 && !{'a', 'i', 'o'}.contains(core.toLowerCase())) {
    return false;
  }

  // Pure digits
  if (RegExp(r'^\d+$').hasMatch(core)) return false;

  // Mixed alpha + digit
  if (core.contains(RegExp(r'\d'))) return false;

  // Brackets
  if (text.contains(RegExp(r'[(){}\[\]]'))) return false;

  // Abbreviation-like: w.w pattern
  if (RegExp(r'\w\.\w').hasMatch(text)) return false;

  return true;
}

/// Filter words by confidence and noise, then sort into reading order.
///
/// Input: list of maps with keys: text, x, y, w, h, confidence.
/// Returns: filtered and sorted list with added sortIndex.
List<Map<String, dynamic>> filterAndSortWords(
  List<Map<String, dynamic>> words, {
  double confidenceThreshold = 0.85,
}) {
  // Filter by confidence and noise
  final filtered = words.where((w) {
    final conf = (w['confidence'] as num).toDouble();
    if (conf < confidenceThreshold) return false;
    return isRealWord(w['text'] as String);
  }).toList();

  // Group into lines: words within half the average height are on the same line
  if (filtered.isEmpty) return [];

  final avgHeight =
      filtered.map((w) => (w['h'] as num).toDouble()).reduce((a, b) => a + b) /
          filtered.length;
  final lineTolerance = avgHeight * 0.5;

  // Sort by y first to group lines
  filtered.sort((a, b) =>
      (a['y'] as num).toDouble().compareTo((b['y'] as num).toDouble()));

  // Group into lines
  final List<List<Map<String, dynamic>>> lines = [];
  for (final word in filtered) {
    final wordY = (word['y'] as num).toDouble();
    if (lines.isNotEmpty) {
      final lastLineY = (lines.last.first['y'] as num).toDouble();
      if ((wordY - lastLineY).abs() < lineTolerance) {
        lines.last.add(word);
        continue;
      }
    }
    lines.add([word]);
  }

  // Sort within each line by x
  for (final line in lines) {
    line.sort((a, b) =>
        (a['x'] as num).toDouble().compareTo((b['x'] as num).toDouble()));
  }

  // Flatten and assign sortIndex
  final result = <Map<String, dynamic>>[];
  var index = 0;
  for (final line in lines) {
    for (final word in line) {
      result.add({...word, 'sortIndex': index});
      index++;
    }
  }

  return result;
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd /Users/dsh/repos/privat/focus-read/flutter_app
flutter test test/core/ocr/word_filter_test.dart
```

Expected: ALL PASS

- [ ] **Step 5: Commit**

```bash
git add flutter_app/lib/core/ocr/word_filter.dart flutter_app/test/core/ocr/word_filter_test.dart
git commit -m "feat: add word noise filter with TDD (ported from Python)"
```

---

## Task 5: OCR Service (ML Kit Integration)

**Files:**
- Create: `flutter_app/lib/core/ocr/ocr_service.dart`

- [ ] **Step 1: Create OCR service**

Create `flutter_app/lib/core/ocr/ocr_service.dart`:

```dart
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'word_filter.dart';

class OcrResult {
  final List<Map<String, dynamic>> words;
  final int imageWidth;
  final int imageHeight;

  OcrResult({
    required this.words,
    required this.imageWidth,
    required this.imageHeight,
  });
}

class OcrService {
  TextRecognizer? _recognizer;

  TextRecognizer _getRecognizer({String script = 'Latin'}) {
    _recognizer?.close();
    _recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    return _recognizer!;
  }

  Future<OcrResult> processImage(
    String imagePath, {
    double confidenceThreshold = 0.85,
  }) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizer = _getRecognizer();
    final recognizedText = await recognizer.processImage(inputImage);

    // Extract words from ML Kit's TextBlock > TextLine > TextElement hierarchy
    final rawWords = <Map<String, dynamic>>[];
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        for (final element in line.elements) {
          final rect = element.boundingBox;
          // ML Kit may or may not expose confidence at element level.
          // Fallback: set to 1.0 and rely on noise filter.
          final confidence = element.confidence ?? 1.0;

          rawWords.add({
            'text': element.text,
            'x': rect.left,
            'y': rect.top,
            'w': rect.width,
            'h': rect.height,
            'confidence': confidence,
          });
        }
      }
    }

    // Get image dimensions from the first block's image metadata or inputImage
    // ML Kit doesn't directly return image dimensions, so we read them separately
    final imageSize = await _getImageSize(imagePath);

    final filtered = filterAndSortWords(
      rawWords,
      confidenceThreshold: confidenceThreshold,
    );

    return OcrResult(
      words: filtered,
      imageWidth: imageSize.width.round(),
      imageHeight: imageSize.height.round(),
    );
  }

  Future<Size> _getImageSize(String path) async {
    final bytes = await File(path).readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return const Size(0, 0);
    return Size(image.width.toDouble(), image.height.toDouble());
  }

  void dispose() {
    _recognizer?.close();
  }
}

final ocrServiceProvider = Provider<OcrService>((ref) {
  final service = OcrService();
  ref.onDispose(() => service.dispose());
  return service;
});
```

Note: Add required imports at top:
```dart
import 'dart:io';
import 'dart:ui' show Size;
import 'package:image/image.dart' as img;
```

- [ ] **Step 2: Verify build**

```bash
cd /Users/dsh/repos/privat/focus-read/flutter_app
flutter analyze
```

- [ ] **Step 3: Commit**

```bash
git add flutter_app/lib/core/ocr/ocr_service.dart
git commit -m "feat: add ML Kit OCR service with word extraction"
```

---

## Task 6: Image Service

**Files:**
- Create: `flutter_app/lib/core/image/image_service.dart`

- [ ] **Step 1: Create image service**

Create `flutter_app/lib/core/image/image_service.dart`:

```dart
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class ImageService {
  static const _maxDimension = 1920; // ~1080p
  static const _jpegQuality = 85;

  /// Save and compress an image to the app documents directory.
  /// Returns the saved file path.
  Future<String> saveImage(File sourceFile) async {
    final dir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(dir.path, 'images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final id = const Uuid().v4();
    final destPath = p.join(imagesDir.path, '$id.jpg');

    // Read and compress
    final bytes = await sourceFile.readAsBytes();
    var image = img.decodeImage(bytes);
    if (image == null) {
      // Fallback: just copy the file
      await sourceFile.copy(destPath);
      return destPath;
    }

    // Resize if larger than max dimension
    if (image.width > _maxDimension || image.height > _maxDimension) {
      image = img.copyResize(
        image,
        width: image.width > image.height ? _maxDimension : null,
        height: image.height >= image.width ? _maxDimension : null,
      );
    }

    // Save as JPEG
    final jpeg = img.encodeJpg(image, quality: _jpegQuality);
    await File(destPath).writeAsBytes(jpeg);

    return destPath;
  }

  /// Delete an image file.
  Future<void> deleteImage(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}

final imageServiceProvider = Provider<ImageService>((ref) => ImageService());
```

- [ ] **Step 2: Commit**

```bash
git add flutter_app/lib/core/image/image_service.dart
git commit -m "feat: add image service with compression and storage"
```

---

## Task 7: TTS Service

**Files:**
- Create: `flutter_app/lib/core/tts/tts_service.dart`

- [ ] **Step 1: Create TTS service**

Create `flutter_app/lib/core/tts/tts_service.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _tts.setSharedInstance(true);
    _initialized = true;
  }

  Future<void> speak(String text, {String language = 'de-DE', double rate = 0.8}) async {
    await _ensureInitialized();
    await _tts.setLanguage(language);
    await _tts.setSpeechRate(rate);
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  /// Returns list of available language codes (e.g., ["de-DE", "en-US"]).
  Future<List<String>> getAvailableLanguages() async {
    await _ensureInitialized();
    final languages = await _tts.getLanguages;
    return (languages as List).map((l) => l.toString()).toList()..sort();
  }

  /// Check if a language has a TTS voice available.
  Future<bool> isLanguageAvailable(String languageCode) async {
    final languages = await getAvailableLanguages();
    return languages.any((l) => l.startsWith(languageCode));
  }

  void dispose() {
    _tts.stop();
  }
}

final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = TtsService();
  ref.onDispose(() => service.dispose());
  return service;
});
```

- [ ] **Step 2: Commit**

```bash
git add flutter_app/lib/core/tts/tts_service.dart
git commit -m "feat: add TTS service with language detection"
```

---

## Task 8: Settings Provider

**Files:**
- Create: `flutter_app/lib/features/settings/settings_provider.dart`

- [ ] **Step 1: Create settings provider**

Create `flutter_app/lib/features/settings/settings_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/models.dart';

class AppSettings {
  final String appLanguage;
  final double ttsSpeed;
  final bool ttsEnabled;
  final AgeGroup ageGroup;
  final double confidenceThreshold;

  const AppSettings({
    this.appLanguage = 'de',
    this.ttsSpeed = 0.8,
    this.ttsEnabled = true,
    this.ageGroup = AgeGroup.earlyPrimary,
    this.confidenceThreshold = 0.85,
  });

  AppSettings copyWith({
    String? appLanguage,
    double? ttsSpeed,
    bool? ttsEnabled,
    AgeGroup? ageGroup,
    double? confidenceThreshold,
  }) =>
      AppSettings(
        appLanguage: appLanguage ?? this.appLanguage,
        ttsSpeed: ttsSpeed ?? this.ttsSpeed,
        ttsEnabled: ttsEnabled ?? this.ttsEnabled,
        ageGroup: ageGroup ?? this.ageGroup,
        confidenceThreshold: confidenceThreshold ?? this.confidenceThreshold,
      );
}

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    _load();
    return const AppSettings();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = AppSettings(
      appLanguage: prefs.getString('appLanguage') ?? 'de',
      ttsSpeed: prefs.getDouble('ttsSpeed') ?? 0.8,
      ttsEnabled: prefs.getBool('ttsEnabled') ?? true,
      ageGroup: AgeGroup.values[prefs.getInt('ageGroup') ?? 1],
      confidenceThreshold: prefs.getDouble('confidenceThreshold') ?? 0.85,
    );
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('appLanguage', state.appLanguage);
    await prefs.setDouble('ttsSpeed', state.ttsSpeed);
    await prefs.setBool('ttsEnabled', state.ttsEnabled);
    await prefs.setInt('ageGroup', state.ageGroup.index);
    await prefs.setDouble('confidenceThreshold', state.confidenceThreshold);
  }

  Future<void> setAppLanguage(String lang) async {
    state = state.copyWith(appLanguage: lang);
    await _save();
  }

  Future<void> setTtsSpeed(double speed) async {
    state = state.copyWith(ttsSpeed: speed);
    await _save();
  }

  Future<void> setTtsEnabled(bool enabled) async {
    state = state.copyWith(ttsEnabled: enabled);
    await _save();
  }

  Future<void> setAgeGroup(AgeGroup group) async {
    state = state.copyWith(ageGroup: group);
    await _save();
  }

  Future<void> setConfidenceThreshold(double threshold) async {
    state = state.copyWith(confidenceThreshold: threshold);
    await _save();
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
```

- [ ] **Step 2: Commit**

```bash
git add flutter_app/lib/features/settings/settings_provider.dart
git commit -m "feat: add settings provider with SharedPreferences persistence"
```

---

## Task 9: Library Screen & Book Provider

**Files:**
- Create: `flutter_app/lib/features/library/library_provider.dart`
- Create: `flutter_app/lib/features/library/library_screen.dart`
- Create: `flutter_app/lib/features/library/book_card.dart`
- Create: `flutter_app/lib/features/book/create_book_dialog.dart`
- Create: `flutter_app/lib/shared/confirm_dialog.dart`

- [ ] **Step 1: Create library provider**

Create `flutter_app/lib/features/library/library_provider.dart`:

```dart
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
    // Delete images for all pages
    final pages = await db.getPagesForBook(bookId);
    for (final page in pages) {
      await imageService.deleteImage(page.imagePath);
    }
    // Delete cover image if custom
    final book = await db.getBook(bookId);
    if (book.coverImagePath != null) {
      await imageService.deleteImage(book.coverImagePath!);
    }
    await db.deleteBook(bookId);
  };
});
```

- [ ] **Step 2: Create confirm dialog**

Create `flutter_app/lib/shared/confirm_dialog.dart`:

```dart
import 'package:flutter/material.dart';

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
  Color? confirmColor,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: confirmColor != null
              ? FilledButton.styleFrom(backgroundColor: confirmColor)
              : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
```

- [ ] **Step 3: Create book card widget**

Create `flutter_app/lib/features/library/book_card.dart`:

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/database.dart';
import 'library_provider.dart';

class BookCard extends ConsumerWidget {
  final Book book;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const BookCard({
    super.key,
    required this.book,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageCount = ref.watch(bookPageCountProvider(book.id));

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: book.coverImagePath != null
                  ? Image.file(
                      File(book.coverImagePath!),
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(
                        Icons.menu_book,
                        size: 48,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
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
      ),
    );
  }
}
```

- [ ] **Step 4: Create create-book dialog**

Create `flutter_app/lib/features/book/create_book_dialog.dart`:

```dart
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
```

- [ ] **Step 5: Create library screen**

Create `flutter_app/lib/features/library/library_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' show Value;
import '../../core/storage/database.dart';
import '../../features/settings/settings_provider.dart';
import '../book/create_book_dialog.dart';
import '../../shared/confirm_dialog.dart';
import 'library_provider.dart';
import 'book_card.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(booksProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Read'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: booksAsync.when(
        data: (books) => _buildGrid(context, ref, books, settings),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildGrid(
    BuildContext context,
    WidgetRef ref,
    List<Book> books,
    AppSettings settings,
  ) {
    final items = books.length + 1; // +1 for "new book" card

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items,
      itemBuilder: (context, index) {
        if (index == books.length) {
          return _buildNewBookCard(context, ref, books.length, settings);
        }
        final book = books[index];
        return BookCard(
          book: book,
          onTap: () => context.push('/book/${book.id}'),
          onLongPress: () => _showBookMenu(context, ref, book),
        );
      },
    );
  }

  Widget _buildNewBookCard(
    BuildContext context,
    WidgetRef ref,
    int bookCount,
    AppSettings settings,
  ) {
    return GestureDetector(
      onTap: () => _createBook(context, ref, bookCount + 1, settings),
      child: Card(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_circle_outline,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                'New Book',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createBook(
    BuildContext context,
    WidgetRef ref,
    int bookNumber,
    AppSettings settings,
  ) async {
    final result = await showCreateBookDialog(
      context,
      bookNumber: bookNumber,
      defaultLanguage: settings.appLanguage,
    );
    if (result == null) return;

    final db = ref.read(databaseProvider);
    final bookId = const Uuid().v4();
    await db.insertBook(BooksCompanion.insert(
      id: bookId,
      title: result.title,
      language: Value(result.language),
    ));

    if (context.mounted) {
      context.push('/book/$bookId');
    }
  }

  Future<void> _showBookMenu(
    BuildContext context,
    WidgetRef ref,
    Book book,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Rename'),
              onTap: () => Navigator.pop(context, 'rename'),
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );

    if (!context.mounted || action == null) return;

    if (action == 'rename') {
      final controller = TextEditingController(text: book.title);
      final newTitle = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Rename Book'),
          content: TextField(controller: controller, autofocus: true),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        ),
      );
      if (newTitle != null && newTitle.isNotEmpty && context.mounted) {
        final db = ref.read(databaseProvider);
        await db.updateBook(BooksCompanion(
          id: Value(book.id),
          title: Value(newTitle),
          updatedAt: Value(DateTime.now()),
        ));
      }
    } else if (action == 'delete') {
      final confirmed = await showConfirmDialog(
        context,
        title: 'Delete Book',
        message: 'Delete "${book.title}" and all its pages?',
        confirmColor: Colors.red,
      );
      if (confirmed) {
        await ref.read(deleteBookProvider)(book.id);
      }
    }
  }
}
```

- [ ] **Step 6: Verify build**

```bash
cd /Users/dsh/repos/privat/focus-read/flutter_app
flutter analyze
```

- [ ] **Step 7: Commit**

```bash
git add flutter_app/lib/features/library/ flutter_app/lib/features/book/create_book_dialog.dart flutter_app/lib/shared/
git commit -m "feat: add library screen with book grid and create book dialog"
```

---

## Task 10: Book Detail Screen

**Files:**
- Create: `flutter_app/lib/features/book/book_provider.dart`
- Create: `flutter_app/lib/features/book/book_screen.dart`
- Create: `flutter_app/lib/features/book/page_card.dart`

- [ ] **Step 1: Create book provider**

Create `flutter_app/lib/features/book/book_provider.dart`:

```dart
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
```

- [ ] **Step 2: Create page card widget**

Create `flutter_app/lib/features/book/page_card.dart`:

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/database.dart';
import 'book_provider.dart';

class PageCard extends ConsumerWidget {
  final Page page;
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
              child: Image.file(
                File(page.imagePath),
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Page ${page.pageNumber}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  wordCount.when(
                    data: (count) => Text(
                      '$count words',
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
      ),
    );
  }
}
```

- [ ] **Step 3: Create book screen**

Create `flutter_app/lib/features/book/book_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/storage/database.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: bookAsync.when(
          data: (book) => Text(book.title),
          loading: () => const Text('...'),
          error: (_, __) => const Text('Error'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo),
            onPressed: () => context.push('/book/$bookId/capture'),
          ),
        ],
      ),
      body: pagesAsync.when(
        data: (pages) => pages.isEmpty
            ? _buildEmptyState(context)
            : _buildPageGrid(context, ref, pages),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.photo_camera,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No pages yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => context.push('/book/$bookId/capture'),
            icon: const Icon(Icons.add_a_photo),
            label: const Text('Add first page'),
          ),
        ],
      ),
    );
  }

  Widget _buildPageGrid(BuildContext context, WidgetRef ref, List<Page> pages) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.75,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: pages.length,
      itemBuilder: (context, index) {
        final page = pages[index];
        return PageCard(
          page: page,
          onTap: () => context.push('/book/$bookId/read/${page.id}'),
          onLongPress: () => _showPageMenu(context, ref, page),
        );
      },
    );
  }

  Future<void> _showPageMenu(
    BuildContext context,
    WidgetRef ref,
    Page page,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Page',
                  style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );

    if (!context.mounted || action != 'delete') return;

    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Page',
      message: 'Delete page ${page.pageNumber}?',
      confirmColor: Colors.red,
    );
    if (confirmed) {
      await ref.read(deletePageProvider)(page.id, page.imagePath);
    }
  }
}
```

- [ ] **Step 4: Commit**

```bash
git add flutter_app/lib/features/book/
git commit -m "feat: add book detail screen with page grid"
```

---

## Task 11: Capture Flow (Camera + Gallery + OCR)

**Files:**
- Create: `flutter_app/lib/features/capture/capture_screen.dart`
- Create: `flutter_app/lib/features/capture/preview_screen.dart`
- Create: `flutter_app/lib/features/capture/capture_provider.dart`
- Modify: `flutter_app/android/app/src/main/AndroidManifest.xml` (camera permission)
- Modify: `flutter_app/ios/Runner/Info.plist` (camera permission strings)

- [ ] **Step 1: Add platform permissions**

Add to `flutter_app/android/app/src/main/AndroidManifest.xml` (inside `<manifest>`, before `<application>`):

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-feature android:name="android.hardware.camera" android:required="false"/>
```

Add to `flutter_app/ios/Runner/Info.plist` (inside `<dict>`):

```xml
<key>NSCameraUsageDescription</key>
<string>Focus Read needs camera access to photograph book pages for reading practice.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Focus Read needs photo library access to select book page photos.</string>
```

- [ ] **Step 2: Create capture provider**

Create `flutter_app/lib/features/capture/capture_provider.dart`:

```dart
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';
import '../../core/ocr/ocr_service.dart';
import '../../core/image/image_service.dart';
import '../../core/storage/database.dart';
import '../settings/settings_provider.dart';

enum CaptureState { idle, processing, success, error }

class CaptureStatus {
  final CaptureState state;
  final String? errorMessage;
  final String? savedPageId;

  const CaptureStatus({
    this.state = CaptureState.idle,
    this.errorMessage,
    this.savedPageId,
  });
}

class CaptureNotifier extends FamilyNotifier<CaptureStatus, String> {
  @override
  CaptureStatus build(String bookId) => const CaptureStatus();

  Future<void> processImage(File imageFile) async {
    state = const CaptureStatus(state: CaptureState.processing);

    try {
      final imageService = ref.read(imageServiceProvider);
      final ocrService = ref.read(ocrServiceProvider);
      final db = ref.read(databaseProvider);
      final settings = ref.read(settingsProvider);

      // Save and compress image
      final savedPath = await imageService.saveImage(imageFile);

      // Run OCR
      final ocrResult = await ocrService.processImage(
        savedPath,
        confidenceThreshold: settings.confidenceThreshold,
      );

      // Get next page number
      final existingPages = await db.getPagesForBook(arg);
      final nextPageNumber = existingPages.isEmpty
          ? 1
          : existingPages.map((p) => p.pageNumber).reduce((a, b) => a > b ? a : b) + 1;

      // Save page to database
      final pageId = const Uuid().v4();
      await db.insertPage(PagesCompanion.insert(
        id: pageId,
        bookId: arg,
        pageNumber: nextPageNumber,
        imagePath: savedPath,
        imageWidth: ocrResult.imageWidth,
        imageHeight: ocrResult.imageHeight,
        ocrCompleted: Value(true),
      ));

      // Save words
      if (ocrResult.words.isNotEmpty) {
        final wordCompanions = ocrResult.words.map((w) {
          return WordsCompanion.insert(
            id: const Uuid().v4(),
            pageId: pageId,
            textContent: w['text'] as String,
            x: (w['x'] as num).toDouble(),
            y: (w['y'] as num).toDouble(),
            w: (w['w'] as num).toDouble(),
            h: (w['h'] as num).toDouble(),
            confidence: (w['confidence'] as num).toDouble(),
            sortIndex: w['sortIndex'] as int,
          );
        }).toList();
        await db.insertWords(wordCompanions);
      }

      // Update book cover if this is the first page
      if (nextPageNumber == 1) {
        await db.updateBook(BooksCompanion(
          id: Value(arg),
          coverImagePath: Value(savedPath),
          updatedAt: Value(DateTime.now()),
        ));
      }

      state = CaptureStatus(
        state: ocrResult.words.isEmpty ? CaptureState.error : CaptureState.success,
        savedPageId: pageId,
        errorMessage: ocrResult.words.isEmpty ? 'No words found. Try again with better lighting.' : null,
      );
    } catch (e) {
      state = CaptureStatus(
        state: CaptureState.error,
        errorMessage: 'OCR failed: $e',
      );
    }
  }

  void reset() {
    state = const CaptureStatus();
  }
}

final captureProvider =
    NotifierProvider.family<CaptureNotifier, CaptureStatus, String>(
        CaptureNotifier.new);
```

- [ ] **Step 3: Create capture screen**

Create `flutter_app/lib/features/capture/capture_screen.dart`:

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'capture_provider.dart';

class CaptureScreen extends ConsumerStatefulWidget {
  final String bookId;

  const CaptureScreen({super.key, required this.bookId});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  CameraController? _controller;
  bool _isInitialized = false;
  FlashMode _flashMode = FlashMode.auto;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _controller = CameraController(backCamera, ResolutionPreset.high);
      await _controller!.initialize();
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      if (mounted) {
        _showPermissionDialog();
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera Permission'),
        content: const Text(
          'Camera access is needed to photograph book pages. '
          'Please enable it in Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // openAppSettings() could be used here
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final xFile = await _controller!.takePicture();
    if (mounted) {
      _processImage(File(xFile.path));
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery);
    if (xFile != null && mounted) {
      _processImage(File(xFile.path));
    }
  }

  void _processImage(File imageFile) {
    ref.read(captureProvider(widget.bookId).notifier).processImage(imageFile);
  }

  @override
  Widget build(BuildContext context) {
    final captureStatus = ref.watch(captureProvider(widget.bookId));

    // Handle state changes
    ref.listen(captureProvider(widget.bookId), (prev, next) {
      if (next.state == CaptureState.success && next.savedPageId != null) {
        // Show success + option to add more or read
        _showSuccessDialog(next.savedPageId!);
      } else if (next.state == CaptureState.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
        ref.read(captureProvider(widget.bookId).notifier).reset();
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Take Photo'),
        actions: [
          IconButton(
            icon: Icon(_flashIcon),
            onPressed: _toggleFlash,
          ),
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: _pickFromGallery,
          ),
        ],
      ),
      body: captureStatus.state == CaptureState.processing
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text('Recognizing text...',
                      style: TextStyle(color: Colors.white)),
                ],
              ),
            )
          : _isInitialized
              ? Stack(
                  children: [
                    Positioned.fill(
                      child: CameraPreview(_controller!),
                    ),
                    Positioned(
                      bottom: 32,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: _takePicture,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                  color: Colors.white54, width: 4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
    );
  }

  IconData get _flashIcon => switch (_flashMode) {
    FlashMode.auto => Icons.flash_auto,
    FlashMode.always => Icons.flash_on,
    FlashMode.off => Icons.flash_off,
    _ => Icons.flash_auto,
  };

  void _toggleFlash() {
    setState(() {
      _flashMode = switch (_flashMode) {
        FlashMode.auto => FlashMode.always,
        FlashMode.always => FlashMode.off,
        FlashMode.off => FlashMode.auto,
        _ => FlashMode.auto,
      };
    });
    _controller?.setFlashMode(_flashMode);
  }

  void _showSuccessDialog(String pageId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Page added!'),
        content: const Text('What would you like to do next?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(captureProvider(widget.bookId).notifier).reset();
            },
            child: const Text('Add another page'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop(); // back to book detail
              context.push('/book/${widget.bookId}/read/$pageId');
            },
            child: const Text('Start reading'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Verify build**

```bash
cd /Users/dsh/repos/privat/focus-read/flutter_app
flutter analyze
```

- [ ] **Step 5: Commit**

```bash
git add flutter_app/lib/features/capture/ flutter_app/android/ flutter_app/ios/
git commit -m "feat: add capture flow with camera, gallery, and OCR processing"
```

---

## Task 12: Reader Screen (Core Feature)

**Files:**
- Create: `flutter_app/lib/features/reader/reader_provider.dart`
- Create: `flutter_app/lib/features/reader/word_overlay.dart`
- Create: `flutter_app/lib/features/reader/control_bar.dart`
- Create: `flutter_app/lib/features/reader/reader_screen.dart`
- Create: `flutter_app/test/features/reader/reader_provider_test.dart`

- [ ] **Step 1: Write failing test for reader provider**

Create `flutter_app/test/features/reader/reader_provider_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_read/features/reader/reader_provider.dart';

void main() {
  group('ReaderState', () {
    final words = [
      {'text': 'Der', 'sortIndex': 0},
      {'text': 'Hund', 'sortIndex': 1},
      {'text': 'rennt', 'sortIndex': 2},
    ];

    test('starts at word 0', () {
      final state = ReaderState(words: words, currentIndex: 0, totalPages: 3, currentPage: 1);
      expect(state.currentWord, 'Der');
      expect(state.isFirstWord, true);
      expect(state.isLastWord, false);
      expect(state.progress, '1/3');
    });

    test('advances to next word', () {
      final state = ReaderState(words: words, currentIndex: 0, totalPages: 3, currentPage: 1);
      final next = state.advance(1);
      expect(next.currentWord, 'Hund');
      expect(next.currentIndex, 1);
    });

    test('does not go below 0', () {
      final state = ReaderState(words: words, currentIndex: 0, totalPages: 3, currentPage: 1);
      final prev = state.advance(-1);
      expect(prev.currentIndex, 0);
    });

    test('does not go past last word', () {
      final state = ReaderState(words: words, currentIndex: 2, totalPages: 3, currentPage: 1);
      expect(state.isLastWord, true);
      final next = state.advance(1);
      expect(next.currentIndex, 2);
    });

    test('jumps to specific word', () {
      final state = ReaderState(words: words, currentIndex: 0, totalPages: 3, currentPage: 1);
      final jumped = state.jumpTo(2);
      expect(jumped.currentWord, 'rennt');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /Users/dsh/repos/privat/focus-read/flutter_app
flutter test test/features/reader/reader_provider_test.dart
```

- [ ] **Step 3: Create reader provider**

Create `flutter_app/lib/features/reader/reader_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/database.dart';

class ReaderState {
  final List<Map<String, dynamic>> words;
  final int currentIndex;
  final int totalPages;
  final int currentPage;

  const ReaderState({
    required this.words,
    required this.currentIndex,
    required this.totalPages,
    required this.currentPage,
  });

  String get currentWord =>
      words.isNotEmpty ? words[currentIndex]['text'] as String : '';

  bool get isFirstWord => currentIndex == 0;
  bool get isLastWord => currentIndex == words.length - 1;
  bool get isEmpty => words.isEmpty;

  String get progress => '${currentIndex + 1}/${words.length}';

  ReaderState advance(int direction) {
    final newIndex = (currentIndex + direction).clamp(0, words.length - 1);
    return ReaderState(
      words: words,
      currentIndex: newIndex,
      totalPages: totalPages,
      currentPage: currentPage,
    );
  }

  ReaderState jumpTo(int index) {
    final clamped = index.clamp(0, words.length - 1);
    return ReaderState(
      words: words,
      currentIndex: clamped,
      totalPages: totalPages,
      currentPage: currentPage,
    );
  }
}

class ReaderNotifier extends FamilyNotifier<ReaderState, String> {
  @override
  ReaderState build(String pageId) {
    _load(pageId);
    return const ReaderState(
      words: [],
      currentIndex: 0,
      totalPages: 0,
      currentPage: 0,
    );
  }

  Future<void> _load(String pageId) async {
    final db = ref.read(databaseProvider);
    final words = await db.getWordsForPage(pageId);
    final page = await (db.select(db.pages)
          ..where((p) => p.id.equals(pageId)))
        .getSingle();
    final allPages = await db.getPagesForBook(page.bookId);

    state = ReaderState(
      words: words
          .map((w) => {
                'text': w.textContent,
                'x': w.x,
                'y': w.y,
                'w': w.w,
                'h': w.h,
                'sortIndex': w.sortIndex,
              })
          .toList(),
      currentIndex: 0,
      totalPages: allPages.length,
      currentPage: page.pageNumber,
    );
  }

  void advance(int direction) {
    state = state.advance(direction);
  }

  void jumpTo(int index) {
    state = state.jumpTo(index);
  }
}

final readerProvider =
    NotifierProvider.family<ReaderNotifier, ReaderState, String>(
        ReaderNotifier.new);
```

- [ ] **Step 4: Run tests**

```bash
cd /Users/dsh/repos/privat/focus-read/flutter_app
flutter test test/features/reader/reader_provider_test.dart
```

Expected: ALL PASS

- [ ] **Step 5: Create word overlay widget**

Create `flutter_app/lib/features/reader/word_overlay.dart`:

```dart
import 'package:flutter/material.dart';

class WordOverlay extends StatelessWidget {
  final Rect rect;
  final bool isActive;
  final bool isRead;
  final double dimOpacity;
  final VoidCallback onTap;

  const WordOverlay({
    super.key,
    required this.rect,
    required this.isActive,
    required this.isRead,
    required this.dimOpacity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFFE8A87C).withValues(alpha: 0.4)
                : isRead
                    ? Colors.white.withValues(alpha: dimOpacity * 0.5)
                    : Colors.white.withValues(alpha: dimOpacity),
            border: isActive
                ? Border.all(color: const Color(0xFFE8A87C), width: 2)
                : null,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Create control bar**

Create `flutter_app/lib/features/reader/control_bar.dart`:

```dart
import 'package:flutter/material.dart';

class ControlBar extends StatelessWidget {
  final String currentWord;
  final String progress;
  final bool ttsEnabled;
  final bool isFirstWord;
  final bool isLastWord;
  final double buttonScale;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onTtsToggle;
  final VoidCallback onTtsSpeak;

  const ControlBar({
    super.key,
    required this.currentWord,
    required this.progress,
    required this.ttsEnabled,
    required this.isFirstWord,
    required this.isLastWord,
    required this.buttonScale,
    required this.onPrevious,
    required this.onNext,
    required this.onTtsToggle,
    required this.onTtsSpeak,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = 24.0 * buttonScale;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                ttsEnabled ? Icons.volume_up : Icons.volume_off,
                size: iconSize,
              ),
              onPressed: onTtsToggle,
            ),
            IconButton(
              icon: Icon(Icons.chevron_left, size: iconSize),
              onPressed: isFirstWord ? null : onPrevious,
            ),
            Expanded(
              child: GestureDetector(
                onTap: onTtsSpeak,
                child: Text(
                  currentWord,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.chevron_right, size: iconSize),
              onPressed: isLastWord ? null : onNext,
            ),
            Text(
              progress,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 7: Create reader screen**

Create `flutter_app/lib/features/reader/reader_screen.dart`:

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/database.dart';
import '../../core/tts/tts_service.dart';
import '../../features/settings/settings_provider.dart';
import 'reader_provider.dart';
import 'word_overlay.dart';
import 'control_bar.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final String bookId;
  final String pageId;

  const ReaderScreen({
    super.key,
    required this.bookId,
    required this.pageId,
  });

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  final _imageKey = GlobalKey();
  Size _imageDisplaySize = Size.zero;
  int _imageWidth = 0;
  int _imageHeight = 0;
  String _imagePath = '';

  @override
  void initState() {
    super.initState();
    _loadPageInfo();
  }

  Future<void> _loadPageInfo() async {
    final db = ref.read(databaseProvider);
    final page = await (db.select(db.pages)
          ..where((p) => p.id.equals(widget.pageId)))
        .getSingle();
    setState(() {
      _imagePath = page.imagePath;
      _imageWidth = page.imageWidth;
      _imageHeight = page.imageHeight;
    });
  }

  void _onImageLayout() {
    final renderBox =
        _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      final newSize = renderBox.size;
      if (newSize != _imageDisplaySize) {
        setState(() => _imageDisplaySize = newSize);
      }
    }
  }

  Rect _wordToRect(Map<String, dynamic> word) {
    if (_imageWidth == 0 || _imageHeight == 0) return Rect.zero;
    final scaleX = _imageDisplaySize.width / _imageWidth;
    final scaleY = _imageDisplaySize.height / _imageHeight;
    return Rect.fromLTWH(
      (word['x'] as num).toDouble() * scaleX,
      (word['y'] as num).toDouble() * scaleY,
      (word['w'] as num).toDouble() * scaleX,
      (word['h'] as num).toDouble() * scaleY,
    );
  }

  void _speakCurrentWord(ReaderState readerState) {
    final settings = ref.read(settingsProvider);
    if (!settings.ttsEnabled) return;

    final db = ref.read(databaseProvider);
    // Get book language for TTS
    db.getBook(widget.bookId).then((book) {
      ref.read(ttsServiceProvider).speak(
            readerState.currentWord,
            language: '${book.language}-${book.language.toUpperCase()}',
            rate: settings.ttsSpeed,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final readerState = ref.watch(readerProvider(widget.pageId));
    final settings = ref.watch(settingsProvider);

    // Speak on word change
    ref.listen(readerProvider(widget.pageId), (prev, next) {
      if (prev?.currentIndex != next.currentIndex && next.words.isNotEmpty) {
        _speakCurrentWord(next);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Page ${readerState.currentPage}/${readerState.totalPages}'),
      ),
      body: readerState.isEmpty && readerState.totalPages == 0
          ? const Center(child: CircularProgressIndicator())
          : readerState.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.text_fields_outlined, size: 64),
                      const SizedBox(height: 16),
                      const Text('No words found on this page.'),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Back'),
                      ),
                    ],
                  ),
                )
          : GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity == null) return;
                if (details.primaryVelocity! < -100) {
                  ref.read(readerProvider(widget.pageId).notifier).advance(1);
                } else if (details.primaryVelocity! > 100) {
                  ref.read(readerProvider(widget.pageId).notifier).advance(-1);
                }
              },
              child: Column(
                children: [
                  Expanded(
                    child: _imagePath.isEmpty
                        ? const SizedBox.shrink()
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              WidgetsBinding.instance.addPostFrameCallback(
                                  (_) => _onImageLayout());
                              return InteractiveViewer(
                                minScale: 1.0,
                                maxScale: 4.0,
                                child: Center(
                                  child: Stack(
                                    children: [
                                      Image.file(
                                        File(_imagePath),
                                        key: _imageKey,
                                        fit: BoxFit.contain,
                                      ),
                                      ...readerState.words
                                      .asMap()
                                      .entries
                                      .map((entry) {
                                    final index = entry.key;
                                    final word = entry.value;
                                    return WordOverlay(
                                      rect: _wordToRect(word),
                                      isActive:
                                          index == readerState.currentIndex,
                                      isRead:
                                          index < readerState.currentIndex,
                                      dimOpacity:
                                          settings.ageGroup.dimOpacity,
                                      onTap: () => ref
                                          .read(readerProvider(widget.pageId)
                                              .notifier)
                                          .jumpTo(index),
                                    );
                                  }),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  ControlBar(
                    currentWord: readerState.currentWord,
                    progress: readerState.progress,
                    ttsEnabled: settings.ttsEnabled,
                    isFirstWord: readerState.isFirstWord,
                    isLastWord: readerState.isLastWord,
                    buttonScale: settings.ageGroup.buttonScale,
                    onPrevious: () => ref
                        .read(readerProvider(widget.pageId).notifier)
                        .advance(-1),
                    onNext: () => ref
                        .read(readerProvider(widget.pageId).notifier)
                        .advance(1),
                    onTtsToggle: () => ref
                        .read(settingsProvider.notifier)
                        .setTtsEnabled(!settings.ttsEnabled),
                    onTtsSpeak: () => _speakCurrentWord(readerState),
                  ),
                ],
              ),
            ),
    );
  }
}
```

- [ ] **Step 8: Run tests**

```bash
cd /Users/dsh/repos/privat/focus-read/flutter_app
flutter test
```

- [ ] **Step 9: Commit**

```bash
git add flutter_app/lib/features/reader/ flutter_app/test/features/reader/
git commit -m "feat: add reader screen with word overlays, navigation, and TTS"
```

---

## Task 13: Settings Screen

**Files:**
- Create: `flutter_app/lib/features/settings/settings_screen.dart`

- [ ] **Step 1: Create settings screen**

Create `flutter_app/lib/features/settings/settings_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models.dart';
import 'settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _SectionHeader('General'),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('App Language'),
            subtitle: Text(_languageName(settings.appLanguage)),
            onTap: () => _showLanguagePicker(context, ref, settings),
          ),
          ListTile(
            leading: const Icon(Icons.child_care),
            title: const Text('Age Group'),
            subtitle: Text(_ageGroupName(settings.ageGroup)),
            onTap: () => _showAgeGroupPicker(context, ref, settings),
          ),
          _SectionHeader('Text-to-Speech'),
          SwitchListTile(
            secondary: const Icon(Icons.volume_up),
            title: const Text('Read Aloud'),
            value: settings.ttsEnabled,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setTtsEnabled(v),
          ),
          ListTile(
            leading: const Icon(Icons.speed),
            title: const Text('Speech Speed'),
            subtitle: Slider(
              value: settings.ttsSpeed,
              min: 0.3,
              max: 1.5,
              divisions: 12,
              label: '${settings.ttsSpeed.toStringAsFixed(1)}x',
              onChanged: (v) =>
                  ref.read(settingsProvider.notifier).setTtsSpeed(v),
            ),
          ),
          _SectionHeader('Advanced'),
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('OCR Confidence Threshold'),
            subtitle: Slider(
              value: settings.confidenceThreshold,
              min: 0.5,
              max: 1.0,
              divisions: 10,
              label: '${(settings.confidenceThreshold * 100).round()}%',
              onChanged: (v) => ref
                  .read(settingsProvider.notifier)
                  .setConfidenceThreshold(v),
            ),
          ),
        ],
      ),
    );
  }

  String _languageName(String code) => switch (code) {
        'de' => 'Deutsch',
        'en' => 'English',
        _ => code,
      };

  String _ageGroupName(AgeGroup group) => switch (group) {
        AgeGroup.preschool => 'Preschool (4-6)',
        AgeGroup.earlyPrimary => 'Early Primary (6-8)',
        AgeGroup.latePrimary => 'Late Primary (8-10)',
      };

  void _showLanguagePicker(
      BuildContext context, WidgetRef ref, AppSettings settings) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('App Language'),
        children: [
          _dialogOption(context, 'Deutsch', () {
            ref.read(settingsProvider.notifier).setAppLanguage('de');
            Navigator.pop(context);
          }),
          _dialogOption(context, 'English', () {
            ref.read(settingsProvider.notifier).setAppLanguage('en');
            Navigator.pop(context);
          }),
        ],
      ),
    );
  }

  void _showAgeGroupPicker(
      BuildContext context, WidgetRef ref, AppSettings settings) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Age Group'),
        children: AgeGroup.values.map((group) {
          return _dialogOption(context, _ageGroupName(group), () {
            ref.read(settingsProvider.notifier).setAgeGroup(group);
            Navigator.pop(context);
          });
        }).toList(),
      ),
    );
  }

  Widget _dialogOption(
          BuildContext context, String label, VoidCallback onTap) =>
      SimpleDialogOption(onPressed: onTap, child: Text(label));
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add flutter_app/lib/features/settings/settings_screen.dart
git commit -m "feat: add settings screen with age group, TTS, and language options"
```

---

## Task 14: Wire Up Router

**Files:**
- Modify: `flutter_app/lib/app/router.dart`

- [ ] **Step 1: Update router with all routes**

Replace `flutter_app/lib/app/router.dart`:

```dart
import 'package:go_router/go_router.dart';
import '../features/library/library_screen.dart';
import '../features/book/book_screen.dart';
import '../features/capture/capture_screen.dart';
import '../features/reader/reader_screen.dart';
import '../features/settings/settings_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LibraryScreen(),
    ),
    GoRoute(
      path: '/book/:bookId',
      builder: (context, state) => BookScreen(
        bookId: state.pathParameters['bookId']!,
      ),
    ),
    GoRoute(
      path: '/book/:bookId/capture',
      builder: (context, state) => CaptureScreen(
        bookId: state.pathParameters['bookId']!,
      ),
    ),
    GoRoute(
      path: '/book/:bookId/read/:pageId',
      builder: (context, state) => ReaderScreen(
        bookId: state.pathParameters['bookId']!,
        pageId: state.pathParameters['pageId']!,
      ),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
```

- [ ] **Step 2: Verify full build**

```bash
cd /Users/dsh/repos/privat/focus-read/flutter_app
flutter analyze
flutter test
```

- [ ] **Step 3: Commit**

```bash
git add flutter_app/lib/app/router.dart
git commit -m "feat: wire up all routes (library, book, capture, reader, settings)"
```

---

## Task 15: Android & iOS Build Configuration

**Files:**
- Modify: `flutter_app/android/app/build.gradle` (minSdk, app name)
- Modify: `flutter_app/ios/Runner/Info.plist` (app name, min iOS)

- [ ] **Step 1: Configure Android**

In `flutter_app/android/app/build.gradle`, ensure:
- `minSdkVersion` is 24
- `targetSdkVersion` is 34
- `applicationId` is `com.focusread.focus_read`

- [ ] **Step 2: Configure iOS**

In Xcode project settings or `ios/Runner.xcodeproj/project.pbxproj`:
- Set deployment target to iOS 16.0
- Set display name to "Focus Read"

- [ ] **Step 3: Test build on both platforms**

```bash
cd /Users/dsh/repos/privat/focus-read/flutter_app
flutter build apk --debug
flutter build ios --debug --no-codesign
```

- [ ] **Step 4: Commit**

```bash
git add flutter_app/android/ flutter_app/ios/
git commit -m "feat: configure Android (minSdk 24) and iOS (16.0) build settings"
```

---

## Task 16: Integration Test

**Files:**
- Create: `flutter_app/test/integration/capture_to_read_test.dart`

- [ ] **Step 1: Write integration test**

Create `flutter_app/test/integration/capture_to_read_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:focus_read/core/storage/database.dart';
import 'package:focus_read/core/ocr/word_filter.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('full flow: create book, add page with words, read them back', () async {
    // Create a book
    await db.insertBook(BooksCompanion.insert(
      id: 'book-1',
      title: 'Test Book',
    ));

    // Simulate OCR result
    final rawWords = [
      {'text': 'Der', 'x': 10.0, 'y': 10.0, 'w': 40.0, 'h': 20.0, 'confidence': 0.95},
      {'text': 'Hund', 'x': 60.0, 'y': 10.0, 'w': 50.0, 'h': 20.0, 'confidence': 0.92},
      {'text': 'x3z', 'x': 120.0, 'y': 10.0, 'w': 30.0, 'h': 20.0, 'confidence': 0.90},
      {'text': 'rennt', 'x': 10.0, 'y': 50.0, 'w': 55.0, 'h': 20.0, 'confidence': 0.88},
      {'text': '(1)', 'x': 200.0, 'y': 200.0, 'w': 20.0, 'h': 15.0, 'confidence': 0.99},
    ];

    final filtered = filterAndSortWords(rawWords, confidenceThreshold: 0.85);
    expect(filtered.length, 3); // Der, Hund, rennt — noise filtered out

    // Insert page
    await db.insertPage(PagesCompanion.insert(
      id: 'page-1',
      bookId: 'book-1',
      pageNumber: 1,
      imagePath: '/tmp/test.jpg',
      imageWidth: 800,
      imageHeight: 600,
      ocrCompleted: const Value(true),
    ));

    // Insert filtered words
    await db.insertWords(filtered.map((w) => WordsCompanion.insert(
          id: 'word-${w['sortIndex']}',
          pageId: 'page-1',
          textContent: w['text'] as String,
          x: (w['x'] as num).toDouble(),
          y: (w['y'] as num).toDouble(),
          w: (w['w'] as num).toDouble(),
          h: (w['h'] as num).toDouble(),
          confidence: (w['confidence'] as num).toDouble(),
          sortIndex: w['sortIndex'] as int,
        )).toList());

    // Read back
    final words = await db.getWordsForPage('page-1');
    expect(words.length, 3);
    expect(words[0].text_, 'Der');
    expect(words[1].text_, 'Hund');
    expect(words[2].text_, 'rennt');

    // Verify reading order
    expect(words[0].sortIndex, lessThan(words[1].sortIndex));
    expect(words[1].sortIndex, lessThan(words[2].sortIndex));
  });
}
```

- [ ] **Step 2: Run all tests**

```bash
cd /Users/dsh/repos/privat/focus-read/flutter_app
flutter test
```

Expected: ALL PASS

- [ ] **Step 3: Commit**

```bash
git add flutter_app/test/
git commit -m "test: add integration test for capture-to-read flow"
```

---

## Task 17: Final Polish & Manual Test

- [ ] **Step 1: Run full analysis**

```bash
cd /Users/dsh/repos/privat/focus-read/flutter_app
flutter analyze
flutter test
```

- [ ] **Step 2: Run on iOS simulator or Android emulator**

```bash
cd /Users/dsh/repos/privat/focus-read/flutter_app
flutter run
```

Manual test checklist:
- Library screen shows with "+" card
- Create a book with title and language
- Book detail shows empty state with camera button
- Camera opens (or permission dialog shows in simulator)
- Pick from gallery works
- OCR processes and shows results in reader
- Word navigation works (tap, swipe, buttons)
- TTS speaks current word
- Settings screen saves preferences
- Back navigation works throughout

- [ ] **Step 3: Fix any issues found**

- [ ] **Step 4: Final commit**

```bash
git add -A flutter_app/
git commit -m "feat: complete Focus Read Flutter app v1"
```
