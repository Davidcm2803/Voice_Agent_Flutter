import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class ImportException implements Exception {
  const ImportException(this.message);
  final String message;
}

class PickedItem {
  PickedItem(this.name, this.bytes);
  final String name;
  final Uint8List bytes;

  String get ext =>
      name.contains('.') ? name.split('.').last.toLowerCase() : '';
  String get baseName =>
      name.contains('.') ? name.substring(0, name.lastIndexOf('.')) : name;
}

class ImportedDoc {
  const ImportedDoc(this.title, this.text, this.ext, this.truncated);
  final String title;
  final String text;
  final String ext;
  final bool truncated;
}

abstract final class DocumentImporter {
  /// Tope de texto por documento (para no volver pesado el cuaderno).
  static const int maxChars = 300000;

  static Future<PickedItem?> pickDocument() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'docx', 'txt', 'md'],
    );
    if (files.isEmpty) return null;
    final f = files.single;
    final bytes = await f.readAsBytes();
    return PickedItem(f.name, bytes);
  }

  static Future<PickedItem?> pickPhoto() async {
    final files = await FilePicker.pickFiles(
      type: FileType.image,
    );
    if (files.isEmpty) return null;
    final f = files.single;
    final bytes = await f.readAsBytes();
    return PickedItem(f.name, bytes);
  }
  static Future<ImportedDoc> extract(PickedItem f) async {
    final bytes = f.bytes;
    String raw;
    switch (f.ext) {
      case 'pdf':
        raw = await Isolate.run(() => _pdfText(bytes));
      case 'docx':
        raw = await Isolate.run(() => _docxText(bytes));
      case 'txt':
      case 'md':
        raw = utf8.decode(bytes, allowMalformed: true);
      default:
        throw ImportException(
            'El formato .${f.ext} no estÃ¡ soportado todavÃ­a. UsÃ¡ PDF, Word (.docx) o texto.');
    }

    var t = raw.replaceAll('\r', '').replaceAll('\u00A0', ' ');
    t = t
        .split('\n')
        .map((l) => l.replaceAll(RegExp(r'[ \t]+'), ' ').trim())
        .join('\n');
    t = t.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();

    if (t.isEmpty) {
      throw const ImportException(
          'No encontrÃ© texto en el archivo. Si es un PDF escaneado (solo imagen), todavÃ­a no lo puedo leer: falta OCR.');
    }
    var truncated = false;
    if (t.length > maxChars) {
      t = t.substring(0, maxChars);
      truncated = true;
    }
    return ImportedDoc(f.baseName, t, f.ext, truncated);
  }

  // Corren en otro isolate para no congelar la interfaz.
  static String _pdfText(Uint8List bytes) {
    try {
      final doc = PdfDocument(inputBytes: bytes);
      final text = PdfTextExtractor(doc).extractText();
      doc.dispose();
      return text;
    } catch (_) {
      return '';
    }
  }

  static String _docxText(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final file = archive.findFile('word/document.xml');
      if (file == null) return '';
      var xml = utf8.decode(file.content as List<int>, allowMalformed: true);
      xml = xml
          .replaceAll(RegExp(r'<w:instrText[^>]*>.*?</w:instrText>', dotAll: true), '')
          .replaceAll(RegExp(r'<w:tab\s*/>'), '\t')
          .replaceAll(RegExp(r'<w:br\s*/>'), '\n')
          .replaceAll('</w:p>', '\n')
          .replaceAll('</w:tc>', '\t')
          .replaceAll(RegExp(r'<[^>]+>'), '');
      return _unescape(xml);
    } catch (_) {
      return '';
    }
  }

  static String _unescape(String s) => s
      .replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (m) {
        final v = int.tryParse(m[1]!, radix: 16);
        return v == null ? '' : String.fromCharCode(v);
      })
      .replaceAllMapped(RegExp(r'&#(\d+);'), (m) {
        final v = int.tryParse(m[1]!);
        return v == null ? '' : String.fromCharCode(v);
      })
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&amp;', '&');
}

