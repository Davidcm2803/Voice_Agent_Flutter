import 'package:voice_agent_flutter/tools/tool.dart';

/// Registro central de herramientas disponibles.
class ToolRegistry {
  final Map<String, Tool> _tools = {};

  void register(Tool tool) {
    if (_tools.containsKey(tool.name)) {
      throw StateError('Herramienta duplicada: ${tool.name}');
    }
    _tools[tool.name] = tool;
  }

  Tool? find(String name) => _tools[name];

  List<Tool> get all => List.unmodifiable(_tools.values);

  /// Esquemas en formato tipo function-calling para el LLM.
  List<Map<String, Object?>> toSchemas() => [
        for (final t in _tools.values)
          {
            'name': t.name,
            'description': t.description,
            'parameters': t.parameters,
          },
      ];

  Future<ToolResult> run(String name, Map<String, Object?> args) async {
    final tool = _tools[name];
    if (tool == null) return ToolResult.failure('No existe la herramienta $name');
    try {
      return await tool.execute(args);
    } catch (e) {
      return ToolResult.failure('Error en $name: $e');
    }
  }
}