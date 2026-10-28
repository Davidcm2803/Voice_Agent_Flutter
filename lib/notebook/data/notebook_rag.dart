import 'package:voice_agent_flutter/notebook/data/notebook_search.dart';
import 'package:voice_agent_flutter/notebook/models/entry.dart';

class RagResult {
  const RagResult(this.context, this.sources);

  /// Texto que se antepone al mensaje del usuario.
  final String context;

  /// Fuentes usadas (para mostrarlas bajo la respuesta).
  final List<Entry> sources;
}

/// Busca las fuentes del cuaderno más relevantes para un mensaje.
/// Presupuesto chico a propósito: el contexto del modelo es de 4096 tokens.
abstract final class NotebookRag {
  static const int maxEntries = 3;
  static const int maxCharsPerEntry = 450;
  static const int maxTotalChars = 1100;

  /// Puntaje mínimo si el mensaje no menciona el cuaderno (1 acierto en título/etiqueta).
  static const int minScore = 3;

  static const _hints = [
    'cuaderno', 'mis notas', 'mi nota', 'snippet', 'apunte', 'guard', 'anote',
    'notas tengo', 'nota tengo', 'que notas', 'que nota', 'mis snippets',
    'mis fuentes', 'en mi libreta', 'tengo anotado',
  ];

  static const _stop = <String>{
    'que', 'como', 'para', 'por', 'con', 'los', 'las', 'una', 'uno', 'unos',
    'unas', 'del', 'esto', 'esta', 'este', 'eso', 'esa', 'ese', 'mae', 'playo',
    'diay', 'axel', 'pero', 'porque', 'cual', 'cuales', 'cuando', 'donde',
    'quien', 'mas', 'muy', 'hay', 'tengo', 'tiene', 'hace', 'hacer', 'puedo',
    'quiero', 'dime', 'decime', 'dame', 'sobre', 'entre', 'desde', 'hasta',
    'tambien', 'algo', 'todo', 'toda', 'nada', 'hola', 'favor', 'oye', 'vara',
    'cosa', 'jaja', 'jajaja', 'cuaderno', 'notas', 'nota', 'snippet',
    'snippets', 'guardado', 'guardada', 'guarde', 'mis', 'tus', 'sus',
  };

  static String _stem(String t) => t.length > 5 ? t.substring(0, 5) : t;

  static RagResult? retrieve(List<Entry> all, String query) {
    final live = all
        .where((e) => !e.deleted && e.body.trim().isNotEmpty)
        .toList();
    if (live.isEmpty) return null;

    final q = NotebookSearch.normalize(query);
    final hinted = _hints.any(q.contains);
    final tokens = q
        .split(RegExp(r'[^a-z0-9]+'))
        .where((t) => t.length >= 3 && !_stop.contains(t))
        .map(_stem)
        .toSet()
        .toList();

    List<Entry> picked;
    if (tokens.isEmpty) {
      if (!hinted) return null;
      picked = live.take(maxEntries).toList(); // los más recientes
    } else {
      final scored = <(Entry, int)>[];
      for (final e in live) {
        final title = NotebookSearch.normalize(e.title);
        final tags = NotebookSearch.normalize(e.tags.join(' '));
        final body = NotebookSearch.normalize(e.body);
        var score = 0;
        for (final t in tokens) {
          if (title.contains(t) || tags.contains(t)) score += 3;
          if (body.contains(t)) score += 1;
        }
        if (score >= (hinted ? 1 : minScore)) scored.add((e, score));
      }
      if (scored.isEmpty) {
        if (!hinted) return null;
        picked = live.take(maxEntries).toList();
      } else {
        scored.sort((a, b) {
          final c = b.$2.compareTo(a.$2);
          return c != 0 ? c : b.$1.updatedAt.compareTo(a.$1.updatedAt);
        });
        picked = [for (final s in scored.take(maxEntries)) s.$1];
      }
    }

    final buf = StringBuffer(
        '[Datos guardados en el cuaderno del mae. Son suyos y los tienes disponibles. '
        'Si pregunta por su cuaderno o sus notas, responde con estos datos, citando el título. '
        'Si pregunta por su cuaderno o sus notas, responde con estos datos, citando el título. '
        'Si la pregunta no tiene que ver, ignóralos]\n');
    final sources = <Entry>[];
    var used = 0;
    for (var i = 0; i < picked.length; i++) {
      final e = picked[i];
      var body = e.body.trim();
      if (body.length > maxCharsPerEntry) {
        body = '${body.substring(0, maxCharsPerEntry)}...';
      }
      final head = e.language == null ? e.title : '${e.title} (${e.language})';
      final block = '${i + 1}) $head\n$body\n';
      if (used + block.length > maxTotalChars && sources.isNotEmpty) break;
      buf.write(block);
      used += block.length;
      sources.add(e);
    }
    buf.write('[Fin de fuentes]');
    return RagResult(buf.toString(), sources);
  }
}