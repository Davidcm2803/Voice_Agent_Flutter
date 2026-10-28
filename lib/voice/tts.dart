import 'package:flutter_tts/flutter_tts.dart';

/// Voz de salida: habla frase por frase con una cola.
class TtsService {
  final FlutterTts _tts = FlutterTts();
  final List<String> _queue = [];
  bool _ready = false;
  bool _running = false;

  /// Si está en false, no habla nada.
  bool enabled = true;

  Future<void> _init() async {
    if (_ready) return;
    await _tts.awaitSpeakCompletion(true);
    for (final code in ['es-CR', 'es-419', 'es-MX', 'es-US', 'es-ES']) {
      try {
        final ok = await _tts.isLanguageAvailable(code);
        if (ok == true || ok == 1) {
          await _tts.setLanguage(code);
          break;
        }
      } catch (_) {}
    }
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    _ready = true;
  }

  /// Quita markdown y enlaces para que no los lea en voz alta.
  String _clean(String s) => s
      .replaceAll(RegExp(r'https?://\S+'), '')
      .replaceAll(RegExp(r'[*_#`>~|]+'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  Future<void> speak(String text) async {
    if (!enabled) return;
    final clean = _clean(text);
    if (clean.isEmpty) return;
    _queue.add(clean);
    _drain();
  }

  Future<void> _drain() async {
    if (_running) return;
    _running = true;
    try {
      await _init();
      while (_queue.isNotEmpty) {
        await _tts.speak(_queue.removeAt(0));
      }
    } finally {
      _running = false;
    }
  }

  Future<void> stop() async {
    _queue.clear();
    try {
      await _tts.stop();
    } catch (_) {}
  }

  Future<void> dispose() => stop();
}