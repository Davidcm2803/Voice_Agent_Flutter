# Convenciones

- Archivos `snake_case.dart`, clases `PascalCase`.
- Imports con `package:voice_agent_flutter/...`.
- Colores solo desde `AppColors`; estilos desde `AppTheme`.
- La UI depende de `LlmProvider`, nunca de un proveedor concreto.
- Cada herramienta extiende `Tool` y se registra en `ToolRegistry`.
- Acciones sensibles: `requiresConfirmation => true`.