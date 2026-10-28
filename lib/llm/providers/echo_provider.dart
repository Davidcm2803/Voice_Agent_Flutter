import 'package:voice_agent_flutter/llm/llm_provider.dart';

/// Proveedor falso para probar la UI sin modelo real.
class EchoProvider implements LlmProvider {
  @override
  String get id => 'echo';

  @override
  String get displayName => 'Eco (pruebas)';

  @override
  Future<void> load() async {}

  @override
  Future<void> dispose() async {}

  @override
  Stream<String> generate(
    List<ChatMessage> messages, {
    LlmOptions options = const LlmOptions(),
  }) async* {
    final last = messages.lastWhere((m) => m.role == ChatRole.user);
    final words = 'Te escucho. Dijiste: "${last.content}". '
            'Aún no tengo cerebro conectado, pero la interfaz ya vive.'
        .split(' ');
    for (final w in words) {
      await Future<void>.delayed(const Duration(milliseconds: 60));
      yield '$w ';
    }
  }
}