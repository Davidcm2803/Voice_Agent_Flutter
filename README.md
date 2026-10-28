# Axel Agent · Voice_Agent_Flutter

Asistente personal de voz y **cuaderno inteligente parecido a noteboke llm pero mas cool** privado, hecho con Flutter/Dart.
Uso personal, presupuesto **0 colones**, modelos locales primero, español primero.

## Dos mitades

1. **Asistente**: chat tipo ChatGPT, voz ("Hey Axel"), herramientas (alarmas, abrir apps, YouTube, WhatsApp con confirmación) y control de otros dispositivos.
2. **Cuaderno (tipo NotebookLM privado)**: snippets de Docker/PowerShell, notas y fotos importantes, sincronizados entre mis dispositivos. El LLM consulta el cuaderno para responder.

## Dispositivos

| Dispositivo | Rol | Notas |
|---|---|---|
| Samsung Galaxy S24+ (SM-S926B) | Principal | Exynos 2400, 12 GB RAM, One UI 8.5, Android 16 |
| Tablet Galaxy S10 FE | Secundario | Android, mismo APK |
| Laptop Windows 11 | Agente de escritorio y cuaderno | Pendiente: Visual Studio 2022 con C++ |

## Decisiones tomadas

- **LLM base:** Gemma 4 E4B local (8.5 tok/s, TTFT 1.1 s, 4.7 GB de RAM en la Gallery). E2B candidato a residente. Pendiente probar E2B, Qwen3 1.7B y FunctionGemma 270M.
- **Contexto:** 4000 tokens, por eso el LLM solo recibe los elementos más relevantes del cuaderno.
- **Voz:** STT del sistema (`speech_to_text`). El micrófono de la Gallery no entiende bien el español; el dictado del teclado sí.
- **Almacenamiento:** un JSON por elemento con UUID. Los títulos pueden repetirse. Borrado lógico. Gana el `updatedAt` más reciente.
- **Sincronización:** Syncthing sobre la carpeta `Axel` (fase A, por validar en Android 16). Sync propio por Tailscale si no basta (fase B).
- **Búsqueda:** en memoria al inicio; SQLite FTS5 local como índice reconstruible después.
- **Base de datos:** nada de pago. SQLite es gratis y local; los archivos son la fuente de verdad.
- **Distribución:** repositorio privado, APK instalado a mano.

## Arquitectura

```
Voz -> wake word -> STT del sistema -> texto
   v
Router (reglas + FunctionGemma)
   |- Comando conocido -> herramienta directa
   |- Consulta al cuaderno -> búsqueda -> LLM con los resultados
   |- Charla -> Gemma local
   |- Difícil -> Ollama en la laptop (Tailscale)
   v
Registro de herramientas -> puente Kotlin -> TTS
```

## Estructura

```
lib/
  core/       config y persona de Axel
  llm/        interfaz común + proveedores
  router/     reflejos vs LLM
  tools/      registro y herramientas
  voice/      STT, TTS, wake word
  memory/     historial de chat
  notebook/   modelo, almacén de archivos, búsqueda, sync
  platform/   puente Dart <-> Kotlin
  ui/         tema, widgets, chat, cuaderno, ajustes
docs/         plan, pruebas, seguridad, convenciones, cuaderno
```

## Estética

Estilo cómic oscuro: negro, rojo y azul, semitonos, paneles con sombra dura. Todo el color sale de `AppColors` y `AppTheme`.

## Fases

0. Entorno y estructura (hecho)
1. Cascarón de UI, interfaz LLM y registro de herramientas (hecho)
2. **Cuaderno: guardar, buscar y copiar snippets (en curso)**
3. Proveedor LLM real (LiteRT con Gemma) y STT en español
4. Cuaderno + LLM (consultas sobre mis notas)
5. Sincronización entre dispositivos
6. Herramientas del teléfono (alarma, apps, YouTube, WhatsApp)
7. Wake word "Axel" y TTS
8. Agente de escritorio (Windows), Wake-on-LAN, escenas
9. Fotos en el cuaderno

## Límites conocidos

- Android y Windows no permiten que una app desbloquee la pantalla con voz; la voz no es autenticación.
- Wake-on-LAN depende de BIOS y de cable Ethernet.
- Samsung puede matar servicios en segundo plano: excluir la app de la optimización de batería.
- Los datos sensibles (claves, contraseñas) no van en texto plano en el cuaderno.

## Comandos

```powershell
flutter doctor -v
flutter devices
flutter analyze
flutter run -d R5CX11KC2WH
flutter build apk --release
```

Documentos: `docs/CONVENTIONS.md`, `docs/NOTEBOOK.md`, `docs/MODEL_TESTS.md`, `docs/SECURITY.md`, `docs/DEVICES.md`.
