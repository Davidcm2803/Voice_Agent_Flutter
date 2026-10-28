/// Resultado de ejecutar una herramienta.
class ToolResult {
  const ToolResult({required this.ok, required this.message});

  const ToolResult.success(String message) : this(ok: true, message: message);
  const ToolResult.failure(String message) : this(ok: false, message: message);

  final bool ok;
  final String message;
}

/// Contrato de toda herramienta de Axel.
abstract class Tool {
  const Tool();

  /// Identificador único en snake_case, p. ej. `set_alarm`.
  String get name;

  /// Descripción para que el LLM sepa cuándo usarla.
  String get description;

  /// Esquema JSON de los parámetros.
  Map<String, Object?> get parameters;

  /// Si es true, la UI debe pedir confirmación antes de ejecutar.
  bool get requiresConfirmation => false;

  Future<ToolResult> execute(Map<String, Object?> args);
}