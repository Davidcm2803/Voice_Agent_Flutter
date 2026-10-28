import 'package:voice_agent_flutter/notebook/data/notebook_search.dart';

class NoteCommand {
  const NoteCommand(this.content);

  /// null = el mae pidió agregar una nota pero aún no dijo qué.
  final String? content;
}

/// Detecta órdenes como "agrega una nota que diga X" o "anota X".
abstract final class NoteCommands {
  static final _start = RegExp(
    r'^\s*(?:(?:mae|axel|playo|diay|oye|porfa|por favor|ok|okey)[\s,]+)*'
    r'(agrega(?:me|r)?|anade(?:me)?|anadir|anota(?:me|r)?|apunta(?:me|r)?|'
    r'guarda(?:me|r)?|crea(?:me|r)?)\b(.*)$',
    dotAll: true,
  );
  static final _noun =
      RegExp(r'\b(nota|notas|cuaderno|libreta|apunte|apuntes)\b');
  static final _noteColon = RegExp(r'^\s*nota\s*[:\-]\s*(.+)$', dotAll: true);

  static final _nounStep = RegExp(
      r'^\s*(?:una\s+nueva\s+nota|una\s+nota\s+nueva|una\s+nueva|una\s+nota|'
      r'nueva\s+nota|la\s+nota|nota|esto|lo\s+siguiente|un\s+apunte|apunte)\b');
  static final _destStep = RegExp(
      r'^\s*(?:a|en|al|dentro\s+de)\s+(?:mis\s+|mi\s+|las\s+|la\s+|el\s+)?'
      r'(?:notas|nota|cuaderno|libreta)\b');
  static final _queStep =
      RegExp(r'^\s*(?:que\s+(?:diga|dice)|diciendo|que|diga|dice)\b');
  static final _punctStep = RegExp(r'^\s*[:,\-]+');

  static final _lead = [_nounStep, _destStep, _queStep, _punctStep];

  /// Quita los pasos del inicio y devuelve el texto original restante.
  /// normalize() conserva el largo, así los índices coinciden.
  static String _strip(String orig, String norm, int from, List<RegExp> steps) {
    if (orig.length != norm.length) orig = norm;
    var start = from;
    for (final r in steps) {
      final m = r.firstMatch(norm.substring(start));
      if (m != null) start += m.end;
    }
    return orig.substring(start).trim();
  }

  static NoteCommand? parse(String text) {
    final n = NotebookSearch.normalize(text);

    final c = _noteColon.firstMatch(n);
    if (c != null) {
      final content = _strip(text, n, c.end - c.group(1)!.length, const []);
      return NoteCommand(content.length < 2 ? null : content);
    }

    final m = _start.firstMatch(n);
    if (m == null) return null;
    final verb = m.group(1)!;
    final rest = m.group(2)!;
    final strong = verb.startsWith('anota') || verb.startsWith('apunta');
    if (!strong && !_noun.hasMatch(rest)) return null;

    final content = _strip(text, n, m.end - rest.length, _lead);
    return NoteCommand(content.length < 2 ? null : content);
  }

  /// Para el mensaje que sigue a "agrega una nota": quita "que diga", etc.
  static String cleanContent(String text) {
    final n = NotebookSearch.normalize(text);
    return _strip(text, n, 0, [_queStep, _punctStep]);
  }

  static String titleFor(String content) {
    final line = content.trim().split('\n').first.trim();
    var t = line.length <= 48 ? line : line.substring(0, 48);
    if (line.length > 48) {
      final sp = t.lastIndexOf(' ');
      if (sp > 20) t = t.substring(0, sp);
      t = '$t…';
    }
    if (t.isEmpty) return 'Nota';
    return t[0].toUpperCase() + t.substring(1);
  }
}