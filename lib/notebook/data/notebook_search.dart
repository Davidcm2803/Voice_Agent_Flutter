import 'package:voice_agent_flutter/notebook/models/entry.dart';

/// Búsqueda simple en memoria, sin acentos ni mayúsculas.
/// Más adelante se puede reemplazar por SQLite FTS5 sin tocar la UI.
abstract final class NotebookSearch {
  static String normalize(String s) {
    const from = 'áàäâéèëêíìïîóòöôúùüûñ';
    const to = 'aaaaeeeeiiiioooouuuun';
    var out = s.toLowerCase();
    for (var i = 0; i < from.length; i++) {
      out = out.replaceAll(from[i], to[i]);
    }
    return out;
  }

  static List<Entry> search(List<Entry> all, String query, {int limit = 50}) {
    final tokens = normalize(query)
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return all.take(limit).toList();

    final scored = <(Entry, int)>[];
    for (final e in all) {
      final title = normalize(e.title);
      final tags = normalize(e.tags.join(' '));
      final body = normalize(e.body);
      var score = 0;
      for (final t in tokens) {
        if (title.contains(t)) score += 3;
        if (tags.contains(t)) score += 2;
        if (body.contains(t)) score += 1;
      }
      if (score > 0) scored.add((e, score));
    }
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return [for (final s in scored.take(limit)) s.$1];
  }
}