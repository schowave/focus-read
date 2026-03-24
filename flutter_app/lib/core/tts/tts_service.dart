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

  Future<void> speak(
    String text, {
    String language = 'de-DE',
    double rate = 0.8,
  }) async {
    await _ensureInitialized();
    await _tts.setLanguage(language);
    await _tts.setSpeechRate(rate);
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  Future<List<String>> getAvailableLanguages() async {
    await _ensureInitialized();
    final languages = await _tts.getLanguages;
    return (languages as List).map((l) => l.toString()).toList()..sort();
  }

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
