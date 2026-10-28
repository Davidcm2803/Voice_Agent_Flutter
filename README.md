# Axel Agent · Voice_Agent_Flutter

Asistente personal de voz y cuaderno inteligente privado, hecho con Flutter/Dart.
Uso personal, presupuesto 0 colones, modelos locales primero, español primero.

Última actualización: 27 de octubre de 2026.

## Dos mitades

1. Asistente: chat tipo ChatGPT, voz ("Hey Axel"), herramientas (alarmas, abrir apps, YouTube, WhatsApp con confirmación) y control de otros dispositivos.
2. Cuaderno (tipo NotebookLM privado): snippets de Docker/PowerShell, notas y fotos importantes, sincronizados entre mis dispositivos. El LLM consulta el cuaderno para responder.

## Dispositivos

| Dispositivo | Rol | Notas |
|---|---|---|
| Samsung Galaxy S24+ (SM-S926B) | Principal | Exynos 2400, 12 GB RAM, One UI 8.5, Android 16 (API 36) |
| Tablet Galaxy S10 FE | Secundario | Android, mismo APK. Aún sin probar |
| Laptop Windows 11 | Agente de escritorio y cuaderno | Pendiente: Visual Studio 2022 con "Desktop development with C++" |

Entorno de desarrollo: Flutter 3.47.8, Dart 3.13.7, Android SDK 36/37, Gradle 9.3.1, VS Code + PowerShell.

## ESTADO ACTUAL

### Implementado y funcionando

- Entorno: Flutter, Android toolchain y licencias en verde. La app corre en el S24+ por USB.
- Proyecto base con estructura de carpetas estandarizada y convenciones (docs/CONVENTIONS.md).
- Interfaz estilo cómic oscuro (negro, rojo, azul, semitonos, paneles con sombra dura): tema, colores, fondo halftone, ComicPanel.
- Icono de la app, nombre "Axel Agent" y logo en la pantalla inicial.
- Pantalla de chat con streaming, burbujas, botón de chat nuevo, acceso al cuaderno y a ajustes.
- Interfaz común de LLM (LlmProvider) con proveedor de pruebas (Eco).
- Registro de herramientas (Tool, ToolRegistry) con esquemas tipo function-calling. Aún sin herramientas reales.
- Cuaderno funcional:
  - Un archivo JSON por elemento (entries/<uuid>.json). Los títulos pueden repetirse.
  - Crear, editar (tocar la tarjeta), copiar y borrar (borrado lógico) snippets.
  - Búsqueda en memoria sin acentos ni mayúsculas.
  - Escritura atómica (archivo temporal y renombrar).
  - Deduplicación por id: si hay copias de conflicto de Syncthing, gana el updatedAt más reciente.
  - Recarga automática cada 15 s, al volver a la app y al deslizar hacia abajo.
  - Opción en Ajustes "Usar carpeta compartida" (/storage/emulated/0/Axel) con permiso de acceso a todos los archivos, copiando lo ya guardado.
  - .stignore para que Syncthing no sincronice archivos .tmp.
- Error rojo al guardar snippets con código: corregido (el diálogo ahora cuida sus propios controladores).

### Escrito pero SIN verificar en el teléfono

- Proveedor LiteRT (lib/llm/providers/litert_provider.dart) con el paquete litertlm: intenta GPU y cae a CPU. Se escribió a partir de los ejemplos de la documentación del paquete; si flutter analyze marca nombres que no existen (Conversation, Backend.cpu, ConversationConfig), hay que ajustarlos.
- Localizador del modelo (lib/llm/model_locator.dart): busca un archivo .litertlm en /storage/emulated/0/Axel_models y prefiere el que contenga "E4B".
- Chat conectado al proveedor LiteRT (carga el modelo en el primer mensaje).
- Entradas de manifiesto para GPU (libOpenCL.so, libvndksupport.so) y permiso MANAGE_EXTERNAL_STORAGE.

### Pendiente inmediato (para cerrar el cerebro)

- [ ] Tener el archivo del modelo completo en el teléfono. La descarga desde Hugging Face quedó al 75 % (2 732 304 677 de 3 659 530 240 bytes); se retoma con curl -C - o se intenta copiar con adb el que ya descargó la Gallery.
- [ ] Copiarlo a /sdcard/Axel_models/ (fuera de la carpeta sincronizada, para que Syncthing no lo mueva).
- [ ] flutter analyze limpio y primera respuesta real de Gemma.
- [ ] Anotar backend usado (GPU o CPU), tok/s, calor y si Android cierra la app.
- [ ] Fijar temperatura y top-k (aún no se sabe cómo los expone el paquete).
- [ ] Commit.

### NO implementado todavía

Cerebro y voz
- Voz de entrada (speech_to_text, español) y botón de micrófono real (hoy dice "próximamente").
- Voz de salida (TTS) frase por frase.
- Palabra de activación "Hey Axel" (openWakeWord) y servicio en primer plano.
- Router de intención (reglas + FunctionGemma 270M) y capa de reflejos.
- Historial de conversaciones (conversation_store) y memoria del chat.
- Compresión del contexto (el modelo solo tiene 4000 tokens).
- Proveedores adicionales: Ollama en la laptop (vía Tailscale) y API compatible con OpenAI.
- Pantalla de ajustes funcional (hoy casi todo es informativo).
- Descarga del modelo desde la propia app (hoy se copia a mano).

Herramientas del teléfono (archivos vacíos)
- Alarma y temporizador (intent AlarmClock).
- Abrir apps concretas.
- Buscar en YouTube.
- Mensaje de WhatsApp con confirmación obligatoria.
- Puente nativo Kotlin (platform channels).

Cuaderno
- Cuaderno + LLM: búsqueda de los 3 a 5 elementos más relevantes e inyección en el prompt.
- Fotos (copia a almacenamiento privado, notas y etiquetas).
- Etiquetas editables, tipos nota y foto en la interfaz.
- Índice SQLite FTS5 local (solo si la búsqueda en memoria se vuelve lenta).
- Cifrado o exclusión de datos sensibles.
- Exportar/respaldar a .zip.

Sincronización
- Validar Syncthing-Fork en el S24+ con Android 16 / One UI 8.5 (carpeta Axel, permisos, ahorro de batería excluido).
- Prueba de aceptación: crear en el teléfono y ver en la laptop; editar en la laptop y ver en el teléfono; crear dos snippets con el mismo título en dos dispositivos sin conflicto.
- Alternativa pendiente de decisión: base en la nube gratis (Supabase) para el texto.

Otros dispositivos
- Plataforma Windows en el proyecto (flutter create --platforms=windows .) y Visual Studio 2022 con C++.
- Agente de escritorio (abrir Visual Studio/VS Code, comandos) con emparejamiento por QR y comandos firmados.
- Wake-on-LAN para encender la laptop.
- Tablet S10 FE: instalar el mismo APK y sincronizar.
- Escenas ("modo trabajo").
- Asistente por defecto del sistema (VoiceInteractionService) y accesibilidad: opcional, fase avanzada.

## Decisiones tomadas

- LLM base: Gemma 4 E4B local en formato .litertlm. Probado en la Gallery: 8,5 tok/s, TTFT 1,1 s, 4,7 GB de RAM (43 %), contexto 4000. Candidato a residente más liviano: E2B (2,6 GB). Pendiente probar E2B, Qwen3 1.7B (si existe en .litertlm) y FunctionGemma 270M.
- Motor: paquete litertlm (Android y Windows con la misma API, sobre el runtime oficial LiteRT-LM).
- El modelo no va en el APK. Vive en /storage/emulated/0/Axel_models, fuera de la carpeta sincronizada. El modelo de la Gallery no sirve directamente porque está en su carpeta privada.
- Voz: STT del sistema (speech_to_text). El micrófono de la Gallery no entiende bien el español; el dictado del teclado sí. Whisper vía sherpa-onnx queda como plan B.
- Almacenamiento: archivos JSON como fuente de verdad (un archivo por elemento, UUID, borrado lógico, gana el updatedAt más reciente). Nada de pago. SQLite solo como índice local reconstruible, más adelante.
- Sincronización: Syncthing-Fork sobre la carpeta Axel. Limitación conocida: ambos dispositivos deben estar encendidos y con internet a la vez; funciona fuera de la misma red (descubrimiento y relays), pero con datos móviles hay que activarlo y gasta plan.
- Alternativa en la nube (no implementada): Supabase gratis para el texto. Según las fuentes consultadas en octubre de 2026: 500 MB de base de datos, 1 GB de archivos y pausa tras una semana sin actividad. Los límites cambian; confirmar antes de usarla. Las fotos no caben en ese plan.
- Distribución: repositorio privado, APK instalado a mano. El arte (icono y logo) es solo de uso personal.
- Ollama: no es un modelo sino un programa para PC; se usará como "cerebro grande" en la laptop, como proveedor adicional.

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

## Estructura (✔ implementado, ○ archivo vacío por llenar)

```
lib/
  main.dart                          ✔
  core/            config ✔ · axel_persona ✔
  llm/             llm_provider ✔ · model_locator ✔
    providers/     echo ✔ · litert (sin verificar) · ollama ○ · openai_compat ○
  router/          intent_router ○
  tools/           tool ✔ · tool_registry ✔
    builtin/       alarm ○ · open_app ○ · youtube ○ · whatsapp ○
  voice/           stt ○ · tts ○ · wake_word ○
  memory/          conversation_store ○
  platform/        native_bridge ○
  notebook/
    models/        entry ✔
    data/          entry_store ✔ · notebook_search ✔ · storage_location ✔
    sync/          sync_service ○
  ui/
    theme/         app_colors ✔ · app_theme ✔
    widgets/       comic_panel ✔ · halftone_background ✔ · empty_state ✔
    chat/          chat_screen ✔
    notebook/      notebook_screen ✔ · entry_editor_dialog ✔
    settings/      settings_screen ✔
docs/              PLAN · MODEL_TESTS · SECURITY · DEVICES · CONVENTIONS · NOTEBOOK
assets/branding/   law.png (logo inicio) · mainapp.jpg (icono) · icon.png · icon_fg.png
```

## Fases

0. Entorno y estructura (hecho)
1. Cascarón de UI, interfaz LLM y registro de herramientas (hecho)
2. Cuaderno: guardar, editar, buscar, copiar, carpeta compartida (hecho; falta validar el sync)
3. Cerebro: Gemma local en el chat (escrito, falta verificar en el teléfono) <- EN CURSO
4. STT en español y botón de micrófono
5. Cuaderno + LLM (consultas sobre mis notas)
6. Validar sincronización (Syncthing-Fork) y decidir si hace falta nube
7. Herramientas del teléfono (alarma, apps, YouTube, WhatsApp)
8. Wake word "Axel" y TTS
9. Agente de escritorio (Windows), Wake-on-LAN, escenas, tablet
10. Fotos en el cuaderno
11. Asistente por defecto y accesibilidad (opcional)

## Lecciones aprendidas (para no repetir)

- Gradle fallaba con "immutable workspace modified": rutas demasiado largas (MAX_PATH) en C:\Users\Dell\.gradle. Solución: borrar la caché con prefijo \\?\ o robocopy, activar rutas largas y, si hace falta, mover la caché con GRADLE_USER_HOME=C:\g.
- permission_handler exige compileSdk 37: en android/app/build.gradle.kts se cambió a compileSdk = 37.
- pubspec.yaml: el bloque flutter_launcher_icons va fuera de la sección flutter, pegado al margen izquierdo.
- Escribir archivos desde PowerShell: usar UTF-8 sin BOM (función Write-Src) para evitar acentos rotos.
- Un README con bloques de código dentro de un bloque de código se rompe al pegar: entregarlo como archivo.
- Vecteezy bloquea descargas por script (403): bajar las imágenes desde el navegador.
- adb a veces pierde el teléfono: adb kill-server, adb start-server, adb devices.
- Iconos nuevos y plugins nuevos requieren instalación completa, no hot reload.

## Límites conocidos

- Android y Windows no permiten que una app desbloquee la pantalla con voz; la voz no es autenticación. Alternativa: encender, abrir programas y desbloquear con huella o rostro.
- Wake-on-LAN depende de la BIOS y del cable Ethernet.
- Samsung puede matar servicios en segundo plano: excluir Axel y Syncthing-Fork de la optimización de batería.
- Modelos locales de 2B a 4B no igualan a Gemini en la nube: razonamiento largo y código son su punto débil. Inicializar el modelo es lento (hay que cargarlo una sola vez).
- Los datos sensibles (claves, contraseñas) no van en texto plano en el cuaderno.
- Google Play restringe el uso de accesibilidad: no se publicará allí.

## Seguridad

- Confirmar antes de enviar mensajes, comprar o borrar.
- Comandos entre dispositivos firmados y cifrados, con emparejamiento por QR.
- No enviar capturas de pantalla sin avisar.
- La voz da la orden, pero no autentica.

## Comandos

```
flutter doctor -v
flutter devices
flutter analyze
flutter run -d R5CX11KC2WH
flutter build apk --release
adb -s R5CX11KC2WH push <archivo> /sdcard/Axel_models/
```

Documentos: docs/CONVENTIONS.md, docs/NOTEBOOK.md, docs/MODEL_TESTS.md, docs/SECURITY.md, docs/DEVICES.md.