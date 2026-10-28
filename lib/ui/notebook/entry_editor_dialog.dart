import 'package:flutter/material.dart';
import 'package:voice_agent_flutter/notebook/models/entry.dart';
import 'package:voice_agent_flutter/ui/theme/app_colors.dart';

class EntryEditorResult {
  const EntryEditorResult({
    required this.title,
    required this.language,
    required this.body,
  });

  final String title;
  final String language;
  final String body;
}

/// Crea o edita un snippet. Es dueño de sus controladores, por eso
/// no falla al cerrarse (el bug anterior).
class EntryEditorDialog extends StatefulWidget {
  const EntryEditorDialog({super.key, this.entry});

  final Entry? entry;

  @override
  State<EntryEditorDialog> createState() => _EntryEditorDialogState();
}

class _EntryEditorDialogState extends State<EntryEditorDialog> {
  late final TextEditingController _title;
  late final TextEditingController _lang;
  late final TextEditingController _body;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _title = TextEditingController(text: e?.title ?? '');
    _lang = TextEditingController(text: e?.language ?? 'powershell');
    _body = TextEditingController(text: e?.body ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _lang.dispose();
    _body.dispose();
    super.dispose();
  }

  void _save() {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Pon un título');
      return;
    }
    Navigator.of(context).pop(EntryEditorResult(
      title: title,
      language: _lang.text.trim().toLowerCase(),
      body: _body.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.entry != null;

    return AlertDialog(
      backgroundColor: AppColors.panel,
      title: Text(editing ? 'EDITAR SNIPPET' : 'NUEVO SNIPPET'),
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
            TextField(
              controller: _lang,
              decoration: const InputDecoration(
                labelText: 'Lenguaje (docker, powershell...)',
              ),
            ),
            TextField(
              controller: _body,
              minLines: 4,
              maxLines: 10,
              style: const TextStyle(fontFamily: 'monospace'),
              decoration: const InputDecoration(labelText: 'Código'),
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