import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models.dart';
import 'settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // General section
          _SectionHeader(title: 'General'),
          ListTile(
            title: const Text('App Language'),
            subtitle: Text(settings.appLanguage == 'de' ? 'Deutsch' : 'English'),
            onTap: () async {
              final result = await showDialog<String>(
                context: context,
                builder: (context) => SimpleDialog(
                  title: const Text('App Language'),
                  children: [
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(context, 'de'),
                      child: const Text('Deutsch'),
                    ),
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(context, 'en'),
                      child: const Text('English'),
                    ),
                  ],
                ),
              );
              if (result != null) {
                await notifier.setAppLanguage(result);
              }
            },
          ),
          ListTile(
            title: const Text('Age Group'),
            subtitle: Text(_ageGroupLabel(settings.ageGroup)),
            onTap: () async {
              final result = await showDialog<AgeGroup>(
                context: context,
                builder: (context) => SimpleDialog(
                  title: const Text('Age Group'),
                  children: [
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(context, AgeGroup.preschool),
                      child: const Text('Preschool (4–6)'),
                    ),
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(context, AgeGroup.earlyPrimary),
                      child: const Text('Early Primary (6–8)'),
                    ),
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(context, AgeGroup.latePrimary),
                      child: const Text('Late Primary (8–10)'),
                    ),
                  ],
                ),
              );
              if (result != null) {
                await notifier.setAgeGroup(result);
              }
            },
          ),
          const Divider(),

          // Text-to-Speech section
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

          // Advanced section
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
      ),
    );
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
