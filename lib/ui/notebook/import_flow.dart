import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:voice_agent_flutter/notebook/data/document_importer.dart';
import 'package:voice_agent_flutter/notebook/data/entry_store.dart';
import 'package:voice_agent_flutter/notebook/data/notebook_rag.dart';
import 'package:voice_agent_flutter/notebook/models/entry.dart';
import 'package:voice_agent_flutter/ui/theme/app_colors.dart';

/// Importar documentos y fotos al cuaderno. Devuelve el mensaje a mostrar,
/// o null si el mae canceló.
abstract final class ImportFlow {
  static Future<String?> document(BuildContext context, EntryStore store) async {
    try {
      final file = await DocumentImporter.pickDocument();
      if (file == null) return null;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Leyendo ${file.name}...')),
        );
      }
      final doc = await DocumentImporter.extract(file);
      await store.create(
        type: EntryType.note,
        title: doc.title,
        body: doc.text,
        tags: ['documento', doc.ext],
      );
      final n = NotebookRag.chunk(doc.text).length;
      final parts = (n / NotebookRag.maxPassages).ceil();
      final cut = doc.truncated ? ' (era muy largo: guardé los primeros 300 000 caracteres)' : '';
      return 'Listo, guardé «${doc.title}» en el cuaderno: ${doc.text.length} caracteres, '
          '$parts parte(s)$cut. Pedime "resumen de «${doc.title}»" o '
          '"preguntas de estudio de «${doc.title}»".';
    } on ImportException catch (e) {
      return e.message;
    } catch (e) {
      return 'No pude importar el archivo: $e';
    }
  }

  static Future<String?> photo(BuildContext context, EntryStore store) async {
    try {
      final file = await DocumentImporter.pickPhoto();
      if (file == null) return null;
      if (!context.mounted) return null;
      final info = await showDialog<_PhotoInfo>(
        context: context,
        builder: (_) => _PhotoDialog(name: file.baseName, bytes: file.bytes),
      );
      if (info == null) return null;

      final ext = file.ext.isEmpty ? 'jpg' : file.ext;
      final fileName = '${Entry.newId()}.$ext';
      await store.attachments.create(recursive: true);
      await File('${store.attachments.path}/$fileName')
          .writeAsBytes(file.bytes, flush: true);
      final e = await store.create(
        type: EntryType.photo,
        title: info.title,
        body: info.description,
        tags: const ['foto'],
      );
      await store.save(e.copyWith(attachment: fileName));
      return 'Listo, guardé la foto «${info.title}» en el cuaderno.';
    } on ImportException catch (e) {
      return e.message;
    } catch (e) {
      return 'No pude guardar la foto: $e';
    }
  }
}

class _PhotoInfo {
  const _PhotoInfo(this.title, this.description);
  final String title;
  final String description;
}

class _PhotoDialog extends StatefulWidget {
  const _PhotoDialog({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;

  @override
  State<_PhotoDialog> createState() => _PhotoDialogState();
}

class _PhotoDialogState extends State<_PhotoDialog> {
  late final TextEditingController _title;
  late final TextEditingController _desc;
  String? _error;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.name);
    _desc = TextEditingController();
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  void _save() {
    final t = _title.text.trim();
    if (t.isEmpty) {
      setState(() => _error = 'Pon un título');
      return;
    }
    Navigator.of(context).pop(_PhotoInfo(t, _desc.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.panel,
      title: const Text('NUEVA FOTO'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(widget.bytes, height: 140, fit: BoxFit.cover),
            ),
            TextField(
              controller: _title,
              decoration: InputDecoration(labelText: 'Título', errorText: _error),
            ),
            TextField(
              controller: _desc,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Descripción (así Axel la encuentra)',
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