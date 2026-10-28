import 'package:speech_to_text/speech_to_text.dart';

/// Voz de entrada: reconocimiento del sistema, en español.
class SttService {
  final SpeechToText _stt = SpeechToText();
  bool _ready = false;
  String? _locale;

  bool get isListening => _stt.isListening;

  Future<bool> init({
    void Function(String error)? onError,
    void Function(String status)? onStatus,
  }) async {
    if (_ready) return true;
    _ready = await _stt.initialize(
      onError: (e) => onError?.call(e.errorMsg),
      onStatus: onStatus,
    );
    if (_ready) {
      final locales = await _stt.locales();
      _locale = _pickSpanish(locales.map((l) => l.localeId).toList());
    }
    return _ready;
  }

  /// Prefiere es-CR, luego otros españoles latinos, luego cualquier "es".
  String? _pickSpanish(List<String> ids) {
    String norm(String s) => s.replaceAll('-', '_').toLowerCase();
    for (final want in ['es_cr', 'es_419', 'es_mx', 'es_us', 'es_es']) {
      for (final id in ids) {
        if (norm(id) == want) return id;
      }
    }
    for (final id in ids) {
      if (norm(id).startsWith('es')) return id;
    }
    return null;
  }

  Future<void> listen({
    required void Function(String text, bool isFinal) onResult,
  }) async {
    await _stt.listen(
      onResult: (r) => onResult(r.recognizedWords, r.finalResult),
      listenOptions: SpeechListenOptions(
        localeId: _locale,
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
      ),
    );
  }

  Future<void> stop() => _stt.stop();
  Future<void> cancel() => _stt.cancel();
}