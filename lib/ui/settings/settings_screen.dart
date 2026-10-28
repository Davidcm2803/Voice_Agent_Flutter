import 'package:flutter/material.dart';
import 'package:voice_agent_flutter/core/config.dart';
import 'package:voice_agent_flutter/notebook/data/storage_location.dart';
import 'package:voice_agent_flutter/ui/theme/app_colors.dart';
import 'package:voice_agent_flutter/ui/widgets/comic_panel.dart';
import 'package:voice_agent_flutter/ui/widgets/halftone_background.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _path = '...';
  bool _shared = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final dir = await StorageLocation.current();
    final shared = await StorageLocation.isShared();
    if (!mounted) return;
    setState(() {
      _path = dir.path;
      _shared = shared;
    });
  }

  Future<void> _useShared() async {
    setState(() => _busy = true);
    final error = await StorageLocation.useShared();
    await _load();
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error ?? 'Listo. Reabre el cuaderno para ver los datos.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text('AJUSTES', style: theme.textTheme.titleLarge)),
      body: HalftoneBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 64, 16, 16),
            children: [
              const _SettingTile(label: 'MODELO', value: 'Eco (pruebas)'),
              const _SettingTile(label: 'VOZ (STT)', value: 'Sistema · es'),
              const _SettingTile(
                  label: 'PALABRA DE ACTIVACIÓN',
                  value: 'Hey Axel (pendiente)'),
              _SettingTile(
                label: 'CARPETA DEL CUADERNO',
                value: _path,
                extra: _shared
                    ? Text('Compartida: lista para Syncthing',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: AppColors.cyan))
                    : FilledButton(
                        onPressed: _busy ? null : _useShared,
                        child: Text(_busy
                            ? 'Un momento...'
                            : 'USAR CARPETA COMPARTIDA'),
                      ),
              ),
              const _SettingTile(label: 'VERSIÓN', value: AppConfig.version),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({required this.label, required this.value, this.extra});

  final String label;
  final String value;
  final Widget? extra;

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
            if (extra != null) ...[
              const SizedBox(height: 10),
              extra!,
            ],
          ],
        ),
      ),
    );
  }
}