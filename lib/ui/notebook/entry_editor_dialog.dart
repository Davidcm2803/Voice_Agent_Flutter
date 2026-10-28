import 'package:flutter/material.dart';
import 'package:voice_agent_flutter/notebook/models/entry.dart';
import 'package:voice_agent_flutter/ui/theme/app_colors.dart';

class EntryEditorResult {
  const EntryEditorResult({
    required this.title,
    required this.language,
    required this.body,
    required this.tags,
  });

  final String title;

  /// Vacío para las notas.
  final String language;
  final String body;

  /// Etiquetas ya limpias (incluye el lenguaje si es snippet).
  final List<String> tags;
}

/// Crea o edita un snippet o una nota. Es dueño de sus controladores.
class EntryEditorDialog extends StatefulWidget {
  const EntryEditorDialog({super.key, this.entry, this.type});

  final Entry? entry;

  /// Tipo para una entrada nueva (si [entry] es null).
  final EntryType? type;

  @override
  State<EntryEditorDialog> createState() => _EntryEditorDialogState();
}

class _EntryEditorDialogState extends State<EntryEditorDialog> {
  late final TextEditingController _title;
  late final TextEditingController _lang;
  late final TextEditingController _tags;
  late final TextEditingController _body;
  late final bool _isSnippet;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    final type = e?.type ?? widget.type ?? EntryType.snippet;
    _isSnippet = type == EntryType.snippet;
    _title = TextEditingController(text: e?.title ?? '');
    _lang = TextEditingController(
        text: e?.language ?? (_isSnippet ? 'powershell' : ''));
    final extra = (e?.tags ?? const <String>[])
        .where((t) => t != e?.language)
        .join(', ');
    _tags = TextEditingController(text: extra);
    _body = TextEditingController(text: e?.body ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _lang.dispose();
    _tags.dispose();
    _body.dispose();
    super.dispose();
  }

  void _save() {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Pon un título');
      return;
    }
    final lang = _isSnippet ? _lang.text.trim().toLowerCase() : '';
    final tags = <String>[];
    if (lang.isNotEmpty) tags.add(lang);
    for (final t in _tags.text.split(',')) {
      final c = t.trim().toLowerCase();
      if (c.isNotEmpty && !tags.contains(c)) tags.add(c);
    }
    Navigator.of(context).pop(EntryEditorResult(
      title: title,
      language: lang,
      body: _body.text,
      tags: tags,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.entry != null;
    final what = _isSnippet ? 'SNIPPET' : 'NOTA';

    return AlertDialog(
      backgroundColor: AppColors.panel,
      title: Text(editing ? 'EDITAR $what' : 'NUEVO $what'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _title,
              decoration: InputDecoration(
                labelText: 'Título',
                errorText: _error,
              ),
            ),
            if (_isSnippet)
              TextField(
                controller: _lang,
                decoration: const InputDecoration(
                  labelText: 'Lenguaje (docker, powershell...)',
                ),
              ),
            TextField(
              controller: _tags,
              decoration: const InputDecoration(
                labelText: 'Etiquetas (separadas por coma)',
              ),
            ),
            TextField(
              controller: _body,
              minLines: 5,
              maxLines: 12,
              style: _isSnippet
                  ? const TextStyle(fontFamily: 'monospace')
                  : null,
              decoration: InputDecoration(
                labelText: _isSnippet ? 'Código' : 'Contenido',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _save, child: const Text('Guardar')),
      ],
    );
  }
}