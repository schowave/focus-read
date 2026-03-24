/// Returns true if the word is likely a real word (not barcode/logo noise).
/// Ported from Python backend/ocr.py `_is_real_word`.
bool isRealWord(String text) {
  final core = text.replaceAll(RegExp(r'[^\w]', unicode: true), '');
  if (core.isEmpty) return false;
  if (core.length == 1 && !{'a', 'i', 'o'}.contains(core.toLowerCase())) {
    return false;
  }
  if (RegExp(r'^\d+$').hasMatch(core)) return false;
  if (core.contains(RegExp(r'\d'))) return false;
  if (text.contains(RegExp(r'[(){}\[\]]'))) return false;
  if (RegExp(r'\w\.\w').hasMatch(text)) return false;
  return true;
}

/// Filter words by confidence and noise, then sort into reading order.
List<Map<String, dynamic>> filterAndSortWords(
  List<Map<String, dynamic>> words, {
  double confidenceThreshold = 0.85,
}) {
  final filtered = words.where((w) {
    final conf = (w['confidence'] as num).toDouble();
    if (conf < confidenceThreshold) return false;
    if (confidenceThreshold > 0.0 && !isRealWord(w['text'] as String)) {
      return false;
    }
    return true;
  }).toList();

  if (filtered.isEmpty) return [];

  final avgHeight =
      filtered.map((w) => (w['h'] as num).toDouble()).reduce((a, b) => a + b) /
          filtered.length;
  final lineTolerance = avgHeight * 0.5;

  filtered.sort((a, b) =>
      (a['y'] as num).toDouble().compareTo((b['y'] as num).toDouble()));

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

  for (final line in lines) {
    line.sort((a, b) =>
        (a['x'] as num).toDouble().compareTo((b['x'] as num).toDouble()));
  }

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
