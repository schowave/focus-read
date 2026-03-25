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
    this.ttsSpeed = 0.4,
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
      ttsSpeed: prefs.getDouble('ttsSpeed') ?? 0.4,
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
