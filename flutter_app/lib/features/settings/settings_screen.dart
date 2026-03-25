import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models.dart';
import '../../shared/adaptive/adaptive_scaffold.dart';
import '../../shared/adaptive/adaptive_slider.dart';
import '../../shared/adaptive/adaptive_switch.dart';
import '../../shared/adaptive/adaptive_dialog.dart';
import '../../shared/adaptive/platform_utils.dart';
import 'settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return AdaptiveScaffold(
      title: 'Settings',
      body: isIOSPlatform
          ? _buildCupertinoBody(context, settings, notifier)
          : _buildMaterialBody(context, settings, notifier),
    );
  }

  Widget _buildCupertinoBody(
    BuildContext context, AppSettings settings, SettingsNotifier notifier,
  ) {
    return ListView(
      children: [
        CupertinoListSection.insetGrouped(
          header: const Text('General'),
          children: [
            CupertinoListTile(
              title: const Text('App Language'),
              additionalInfo: Text(settings.appLanguage == 'de' ? 'Deutsch' : 'English'),
              trailing: const CupertinoListTileChevron(),
              onTap: () => _selectLanguage(context, notifier),
            ),
            CupertinoListTile(
              title: const Text('Age Group'),
              additionalInfo: Text(_ageGroupLabel(settings.ageGroup)),
              trailing: const CupertinoListTileChevron(),
              onTap: () => _selectAgeGroup(context, notifier),
            ),
          ],
        ),
        CupertinoListSection.insetGrouped(
          header: const Text('Text-to-Speech'),
          children: [
            CupertinoListTile(
              title: const Text('Read Aloud'),
              trailing: AdaptiveSwitch(
                value: settings.ttsEnabled,
                onChanged: (value) => notifier.setTtsEnabled(value),
              ),
            ),
            CupertinoListTile(
              title: const Text('Speech Speed'),
              subtitle: Text('${settings.ttsSpeed.toStringAsFixed(1)}x'),
              additionalInfo: SizedBox(
                width: 180,
                child: AdaptiveSlider(
                  value: settings.ttsSpeed,
                  min: 0.3,
                  max: 1.5,
                  divisions: 12,
                  onChanged: settings.ttsEnabled
                      ? (value) => notifier.setTtsSpeed(value)
                      : null,
                ),
              ),
            ),
          ],
        ),
        CupertinoListSection.insetGrouped(
          header: const Text('Advanced'),
          children: [
            CupertinoListTile(
              title: const Text('OCR Confidence'),
              subtitle: Text('${(settings.confidenceThreshold * 100).round()}%'),
              additionalInfo: SizedBox(
                width: 180,
                child: AdaptiveSlider(
                  value: settings.confidenceThreshold,
                  min: 0.5,
                  max: 1.0,
                  divisions: 10,
                  onChanged: (value) => notifier.setConfidenceThreshold(value),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMaterialBody(
    BuildContext context, AppSettings settings, SettingsNotifier notifier,
  ) {
    return ListView(
      children: [
        _SectionHeader(title: 'General'),
        ListTile(
          title: const Text('App Language'),
          subtitle: Text(settings.appLanguage == 'de' ? 'Deutsch' : 'English'),
          onTap: () => _selectLanguage(context, notifier),
        ),
        ListTile(
          title: const Text('Age Group'),
          subtitle: Text(_ageGroupLabel(settings.ageGroup)),
          onTap: () => _selectAgeGroup(context, notifier),
        ),
        const Divider(),
        _SectionHeader(title: 'Text-to-Speech'),
        SwitchListTile(
          title: const Text('Read Aloud'),
          value: settings.ttsEnabled,
          onChanged: (value) => notifier.setTtsEnabled(value),
        ),
        ListTile(
          title: const Text('Speech Speed'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${settings.ttsSpeed.toStringAsFixed(1)}x'),
              Slider(
                value: settings.ttsSpeed,
                min: 0.3,
                max: 1.5,
                divisions: 12,
                label: '${settings.ttsSpeed.toStringAsFixed(1)}x',
                onChanged: settings.ttsEnabled
                    ? (value) => notifier.setTtsSpeed(value)
                    : null,
              ),
            ],
          ),
        ),
        const Divider(),
        _SectionHeader(title: 'Advanced'),
        ListTile(
          title: const Text('OCR Confidence Threshold'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${(settings.confidenceThreshold * 100).round()}%'),
              Slider(
                value: settings.confidenceThreshold,
                min: 0.5,
                max: 1.0,
                divisions: 10,
                label: '${(settings.confidenceThreshold * 100).round()}%',
                onChanged: (value) => notifier.setConfidenceThreshold(value),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _selectLanguage(BuildContext context, SettingsNotifier notifier) async {
    final result = await showAdaptiveChoiceDialog<String>(
      context: context,
      title: 'App Language',
      choices: const [
        AdaptiveChoice(value: 'de', label: 'Deutsch'),
        AdaptiveChoice(value: 'en', label: 'English'),
      ],
    );
    if (result != null) {
      await notifier.setAppLanguage(result);
    }
  }

  Future<void> _selectAgeGroup(BuildContext context, SettingsNotifier notifier) async {
    final result = await showAdaptiveChoiceDialog<AgeGroup>(
      context: context,
      title: 'Age Group',
      choices: const [
        AdaptiveChoice(value: AgeGroup.preschool, label: 'Preschool (4–6)'),
        AdaptiveChoice(value: AgeGroup.earlyPrimary, label: 'Early Primary (6–8)'),
        AdaptiveChoice(value: AgeGroup.latePrimary, label: 'Late Primary (8–10)'),
      ],
    );
    if (result != null) {
      await notifier.setAgeGroup(result);
    }
  }

  String _ageGroupLabel(AgeGroup group) => switch (group) {
        AgeGroup.preschool => 'Preschool (4–6)',
        AgeGroup.earlyPrimary => 'Early Primary (6–8)',
        AgeGroup.latePrimary => 'Late Primary (8–10)',
      };
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
