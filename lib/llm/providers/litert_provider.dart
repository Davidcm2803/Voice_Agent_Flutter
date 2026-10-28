import 'package:litertlm/litertlm.dart';
import 'package:voice_agent_flutter/llm/llm_provider.dart';
import 'package:voice_agent_flutter/llm/model_locator.dart';

/// Gemma local con LiteRT-LM. Intenta GPU y cae a CPU si falla.
class LiteRtProvider implements LlmProvider {
  Engine? _engine;
  Conversation? _conversation;
  String backendUsed = '';

  @override
  String get id => 'litert';

  @override
  String get displayName => 'Gemma local (LiteRT)';

  bool get isLoaded => _engine != null;

  @override
  Future<void> load() async {
    if (_engine != null) return;

    final path = await ModelLocator.findModel();
    if (path == null) throw StateError(ModelLocator.help);

    Engine? engine;
    try {
      engine = Engine(
        engineConfig: EngineConfig(modelPath: path, backend: Backend.gpu()),
      );
      await engine.initialize();
      backendUsed = 'GPU';
    } catch (_) {
      await engine?.dispose();
      engine = Engine(
        engineConfig: EngineConfig(modelPath: path, backend: Backend.cpu()),
      );
      await engine.initialize();
      backendUsed = 'CPU';
    }
    _engine = engine;
  }

  /// Empieza una charla nueva (borra el contexto del modelo).
  Future<void> resetConversation() async {
    await _conversation?.dispose();
    _conversation = null;
  }

  @override
  Future<void> dispose() async {
    await resetConversation();
    await _engine?.dispose();
    _engine = null;
  }

  @override
  Stream<String> generate(
    List<ChatMessage> messages, {
    LlmOptions options = const LlmOptions(),
  }) async* {
    await load();

    // La conversación del motor ya recuerda el historial:
    // el system prompt se manda una vez y luego solo el último mensaje.
    if (_conversation == null) {
      final system = messages
          .where((m) => m.role == ChatRole.system)
          .map((m) => m.content)
          .join('\n');
      _conversation = await _engine!.createConversation(
        ConversationConfig(
          systemMessage: system.isEmpty ? null : Message.system(system),
        ),
      );
    }

    final last = messages.lastWhere((m) => m.role == ChatRole.user);

    try {
      await for (final chunk
          in _conversation!.sendMessageStream(Message.user(last.content))) {
        final text = chunk.text;
        if (text.isNotEmpty) yield text;
      }
    } catch (_) {
      // Si el contexto (4000 tokens) se llenó o algo falló, la próxima
      // vez se crea una conversación limpia.
      await resetConversation();
      rethrow;
    }
  }
}