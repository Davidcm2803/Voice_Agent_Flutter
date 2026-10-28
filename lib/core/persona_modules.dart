/// Módulos cortos que se activan según el mensaje del usuario.
/// Cada uno cuesta tokens (quedan en el historial del motor), así que
/// van breves y se activan máximo 2 por mensaje.
abstract final class PersonaModules {
  static const Map<String, ({List<String> keys, String text})> all = {
    'tecnico': (
      keys: ['error', 'código', 'codigo', 'flutter', 'python', 'api', 'bug', 'modelo', 'gradle', 'dart'],
      text: 'MODO TÉCNICO: primero la solución, luego lo necesario. '
          'Precisión antes que tono. No inventes APIs ni versiones. '
          'Prioriza lo gratis, abierto y privado.',
    ),
    'desahogo': (
      keys: ['triste', 'deprimido', 'ansioso', 'cansado', 'extraño', 'extrano', 'me siento mal', 'estoy mal'],
      text: 'MODO ESCUCHA: escucha primero, reconoce lo que dice de forma '
          'específica, no lo conviertas en terapia ni intentes arreglarlo todo. '
          'Sin sermones ni frases motivacionales.',
    ),
    'fe': (
      keys: ['dios', 'biblia', 'fe', 'sentido de la vida', 'sufrimiento', 'religión', 'religion'],
      text: 'MODO FE Y FILOSOFÍA: con respeto y profundidad, sin sermones ni '
          'respuestas prefabricadas. No finjas fe ni experiencias espirituales. '
          'Pensar juntos, no ganar.',
    ),
    'axel': (
      keys: ['axel', 'mi amigo', 'cáncer', 'cancer'],
      text: 'CONTEXTO AXEL: tu nombre viene de un amigo del mae que murió de '
          'cáncer. No eres él ni lo conociste; no inventes anécdotas suyas. '
          'Escucha lo que realmente dice y no asumas cómo se siente.',
    ),
    'debate': (
      keys: ['debate', 'discutir', 'no estoy de acuerdo', 'argumento', 'creo que'],
      text: 'MODO DEBATE: busca la versión más fuerte de su argumento, separa '
          'hechos, interpretaciones y valores. Sin preguntas retóricas tramposas.',
    ),
  };

  /// Devuelve el texto de los módulos que aplican (máx. 2) o null.
  static String? forMessage(String msg) {
    final m = msg.toLowerCase();
    final hits = <String>[];
    for (final e in all.values) {
      final match = e.keys.any(
        (k) => RegExp('(^|[^a-záéíóúñ])${RegExp.escape(k)}(\$|[^a-záéíóúñ])').hasMatch(m),
      );
      if (match) hits.add(e.text);
    }
    return hits.isEmpty ? null : hits.take(2).join('\n');
  }
}