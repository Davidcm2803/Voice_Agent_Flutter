import 'package:flutter/material.dart';
import 'package:voice_agent_flutter/core/config.dart';
import 'package:voice_agent_flutter/ui/theme/app_colors.dart';
import 'package:voice_agent_flutter/ui/widgets/comic_panel.dart';
import 'package:voice_agent_flutter/ui/widgets/halftone_background.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('AJUSTES', style: theme.textTheme.titleLarge),
      ),
      body: HalftoneBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 64, 16, 16),
            children: const [
              _SettingTile(label: 'MODELO', value: 'Eco (pruebas)'),
              _SettingTile(label: 'VOZ (STT)', value: 'Sistema · es'),
              _SettingTile(label: 'PALABRA DE ACTIVACIÓN', value: 'Hey Axel (pendiente)'),
              _SettingTile(label: 'VERSIÓN', value: AppConfig.version),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ComicPanel(
        shadowColor: AppColors.blue,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelSmall),
            const SizedBox(height: 4),
            Text(value, style: theme.textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}