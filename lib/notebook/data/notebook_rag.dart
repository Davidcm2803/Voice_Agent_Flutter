import 'package:voice_agent_flutter/notebook/data/notebook_search.dart';
import 'package:voice_agent_flutter/notebook/models/entry.dart';

class RagResult {
  const RagResult(this.context, this.sources);

  /// Texto que se antepone al mensaje del usuario.
  final String context;

  /// Fuentes usadas (para mostrarlas bajo la respuesta).
  final List<Entry> sources;
}

class _Passage {
  _Passage(this.entry, this.text, this.index, this.total);
  final Entry entry;
  final String text;
  final int index;
  final int total;
}

/// Busca los fragmentos del cuaderno más relevantes para un mensaje.
/// Presupuesto chico a propósito: el contexto del modelo es de 4096 tokens.
abstract final class NotebookRag {
  static const int maxPassages = 3;
  static const int maxPerEntry = 2;
  static const int maxCharsPerPassage = 450;
  static const int maxTotalChars = 1400;
  static const int chunkSize = 420;
  static const int maxIndexedChars = 300000;

  /// Puntaje mínimo si el mensaje no menciona el cuaderno.
  static const int minScore = 3;

  static const _hints = [
    // cuaderno y notas
    'cuaderno', 'mis notas', 'mi nota', 'snippet', 'apunte', 'guard', 'anote',
    'notas tengo', 'nota tengo', 'que notas', 'que nota', 'mis snippets',
    'mis fuentes', 'en mi libreta', 'tengo anotado', 'libreta',
    // fotos, archivos y documentos
    'foto', 'imagen', 'archivo', 'documento', 'pdf', 'adjunt', 'mis docs',
    // "lo que subí / te pasé"
    'subi', 'te pase', 'te mande', 'tenia una', 'la otra vez', 'el otro dia',
    // buscar por nombre o contenido
    'le puse', 'le habia puesto', 'se llamaba', 'decia', 'dice algo',
    'la que dice', 'buscame', 'encuentra', 'encontra',
    // fechas
    'que dia', 'que fecha', 'de ayer', 'de hoy', 'de la semana', 'del mes',
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

  static final _studyWords = RegExp(r'\b(resum|pregunt|estudi|repas|explic)');

  static String _stem(String t) => t.length > 5 ? t.substring(0, 5) : t;

  /// Parte un texto en fragmentos de ~[size] caracteres.
  static List<String> chunk(String body, {int size = chunkSize}) {
    final text = body.trim();
    if (text.length <= size) return [text];
    final out = <String>[];
    final cur = StringBuffer();
    void flush() {
      final s = cur.toString().trim();
      if (s.isNotEmpty) out.add(s);
      cur.clear();
    }

    for (final para in text.split(RegExp(r'\n+'))) {
      var p = para.trim();
      if (p.isEmpty) continue;
      while (p.length > size) {
        var cut = p.lastIndexOf(RegExp(r'[.!?;:] '), size);
        cut = cut >= size ~/ 3 ? cut + 1 : p.lastIndexOf(' ', size);
        if (cut <= 0) cut = size;
        if (cur.length + cut > size) flush();
        cur
          ..write(p.substring(0, cut).trim())
          ..write(' ');
        p = p.substring(cut).trim();
      }
      if (cur.length + p.length + 1 > size) flush();
      cur
        ..write(p)
        ..write(' ');
    }
    flush();
    return out;
  }

  static List<String> _chunks(String body) => chunk(
      body.length > maxIndexedChars ? body.substring(0, maxIndexedChars) : body);

  static RagResult? retrieve(List<Entry> all, String query) {
    final live =
        all.where((e) => !e.deleted && e.body.trim().isNotEmpty).toList();
    if (live.isEmpty) return null;

    final q = NotebookSearch.normalize(query);

    // Modo estudio: "resumen de «X»", "preguntas de estudio de «X»".
    if (_studyWords.hasMatch(q)) {
      final target = _findTarget(live, q);
      if (target != null) return _study(target, q);
    }

    final hinted = _hints.any(q.contains);
    final tokens = q
        .split(RegExp(r'[^a-z0-9]+'))
        .where((t) => t.length >= 3 && !_stop.contains(t))
        .map(_stem)
        .toSet()
        .toList();

    List<_Passage> picked;
    if (tokens.isEmpty) {
      if (!hinted) return null;
      picked = _recent(live);
    } else {
      final scored = <(_Passage, int)>[];
      for (final e in live) {
        final title = NotebookSearch.normalize(e.title);
        final tags = NotebookSearch.normalize(e.tags.join(' '));
        var base = 0;
        for (final t in tokens) {
          if (title.contains(t) || tags.contains(t)) base += 3;
        }
        final parts = _chunks(e.body);
        for (var i = 0; i < parts.length; i++) {
          final body = NotebookSearch.normalize(parts[i]);
          var score = base;
          for (final t in tokens) {
            if (body.contains(t)) score += 1;
          }
          if (score >= (hinted ? 1 : minScore)) {
            scored.add((_Passage(e, parts[i], i, parts.length), score));
          }
        }
      }
      if (scored.isEmpty) {
        if (!hinted) return null;
        picked = _recent(live);
      } else {
        scored.sort((a, b) {
          final c = b.$2.compareTo(a.$2);
          if (c != 0) return c;
          final d = b.$1.entry.updatedAt.compareTo(a.$1.entry.updatedAt);
          return d != 0 ? d : a.$1.index.compareTo(b.$1.index);
        });
        picked = [];
        final perEntry = <String, int>{};
        for (final s in scored) {
          final n = perEntry[s.$1.entry.id] ?? 0;
          if (n >= maxPerEntry) continue;
          perEntry[s.$1.entry.id] = n + 1;
          picked.add(s.$1);
          if (picked.length >= maxPassages) break;
        }
      }
    }
    return _build(picked);
  }

  static List<_Passage> _recent(List<Entry> live) => [
        for (final e in live.take(maxPassages))
          () {
            final c = _chunks(e.body);
            return _Passage(e, c.first, 0, c.length);
          }(),
      ];

  static Entry? _findTarget(List<Entry> live, String q) {
    Entry? best;
    var bestLen = 0;
    for (final e in live) {
      final t = NotebookSearch.normalize(e.title).trim();
      if (t.length >= 3 && t.length > bestLen && q.contains(t)) {
        best = e;
        bestLen = t.length;
      }
    }
    return best;
  }

  static RagResult _study(Entry e, String q) {
    final parts = _chunks(e.body);
    final n = parts.length;
    final groups = (n / maxPassages).ceil();
    final m = RegExp(r'(?:parte|seccion|bloque)\s+(\d+)').firstMatch(q);

    List<int> idx;
    String label;
    if (n <= maxPassages) {
      idx = [for (var i = 0; i < n; i++) i];
      label = 'documento completo';
    } else if (m != null) {
      final g = (int.tryParse(m.group(1)!) ?? 1).clamp(1, groups).toInt();
      final from = (g - 1) * maxPassages;
      final to = g * maxPassages > n ? n : g * maxPassages;
      idx = [for (var i = from; i < to; i++) i];
      label = 'parte $g de $groups';
    } else {
      idx = {0, (n - 1) ~/ 2, n - 1}.toList()..sort();
      label = 'muestra del inicio, medio y final; el documento tiene $groups '
          'partes y el mae puede pedir "parte 2"';
    }

    final buf = StringBuffer(
        '[Fragmentos de «${e.title}» ($label). Responde solo con estos '
        'fragmentos; si pide resumen o preguntas de estudio, básate en ellos '
        'y no inventes nada más]\n');
    for (var i = 0; i < idx.length; i++) {
      buf.write('Fragmento ${i + 1}: ${parts[idx[i]]}\n');
    }
    buf.write('[Fin de fragmentos]');
    return RagResult(buf.toString(), [e]);
  }

  static RagResult _build(List<_Passage> picked) {
    final buf = StringBuffer(
        '[Datos guardados en el cuaderno del mae. Son suyos y los tienes disponibles. '
        'Si pregunta por su cuaderno o sus notas, responde con estos datos, citando el título. '
        'Si la pregunta no tiene que ver, ignóralos]\n');
    final sources = <Entry>[];
    var used = 0;
    for (var i = 0; i < picked.length; i++) {
      final p = picked[i];
      final e = p.entry;
      var body = p.text.trim();
      if (body.length > maxCharsPerPassage) {
        body = '${body.substring(0, maxCharsPerPassage)}...';
      }
      var head = e.language == null ? e.title : '${e.title} (${e.language})';
      if (p.total > 1) head = '$head [fragmento ${p.index + 1}/${p.total}]';
      final block = '${i + 1}) $head\n$body\n';
      if (used + block.length > maxTotalChars && i > 0) break;
      buf.write(block);
      used += block.length;
      if (!sources.any((s) => s.id == e.id)) sources.add(e);
    }
    buf.write('[Fin de fuentes]');
    return RagResult(buf.toString(), sources);
  }
}