# Axel Agent · Voice_Agent_Flutter

Asistente personal de voz y notebook inteligente, hecho con Flutter/Dart.


## Dos partes

1. Asistente: chat tipo ChatGPT con chat de voz, herramientas (alarmas, abrir apps, YouTube, WhatsApp) y control de otros dispositivos.
2. Cuaderno (tipo NotebookLM pero mas cool): snippets de Docker/PowerShell, notas, documentos y fotos importantes, sincronizados entre mis dispositivos. El chat general de Axel consulta el cuaderno (RAG) para responder.

## Dispositivos

| Dispositivo | Rol | Notas |
|---|---|---|
| Samsung Galaxy S24+ (SM-S926B) | Principal | Exynos 2400, 12 GB RAM, One UI 8.5, Android 16 (API 36) |
| Tablet Galaxy S10 FE | Secundario | Android, mismo APK. Aún sin probar |
| Laptop Windows 11 | Agente de escritorio y cuaderno | Pendiente: Visual Studio 2022 con "Desktop development with C++" |

Entorno de desarrollo: Flutter 3.47.8, Dart 3.13.7, Android SDK 36/37 (más platform 34 reinstalada), Gradle 9.3.1, AGP 9.1.0, VS Code + PowerShell.

## ESTADO ACTUAL

### Implementado y funcionando

Base y entorno
- Flutter, Android toolchain y licencias en verde. La app compila y corre en el S24+ por USB (build en frío del 26/10: unos 13 min; las siguientes son incrementales y rápidas).
- Proyecto base con estructura de carpetas estandarizada y convenciones (docs/CONVENTIONS.md).
- Interfaz estilo cómic oscuro (negro, rojo, azul, semitonos, paneles con sombra dura): tema, colores, fondo halftone, ComicPanel.
- Icono de la app, nombre "Axel Agent" y logo en la pantalla inicial.
- Dependencia file_picker actualizada a 13.3.0 (ver Lecciones aprendidas). flutter analyze sin errores.

Cerebro
- Gemma 4 E4B local con LiteRT-LM (paquete litertlm). Intenta GPU y cae a CPU. El modelo se precarga al abrir la app y responde en el teléfono.
- Interfaz común de LLM (LlmProvider) con proveedor de pruebas (Eco) y proveedor LiteRT.
- Localizador del modelo: busca un .litertlm en /storage/emulated/0/Axel_models y prefiere el que contenga "E4B".
- Registro de herramientas (Tool, ToolRegistry) con esquemas tipo function-calling. Aún sin herramientas reales.
- Contexto del motor: 4096 tokens (AppConfig.contextTokens = 4096). El system prompt cuenta contra ese límite.

Personalidad (persona compacta)
- lib/core/axel_persona.dart: persona compacta (objetivo menos de 900 tokens). Incluye voz tica, criterio, lectura del momento, memoria y confianza, longitud y 2 ejemplos. Tiene aviso de debug "Persona ~ N tokens" al iniciar.
- lib/core/user_profile.dart: perfil del mae reducido a hechos (unos 300 tokens).
- lib/core/persona_modules.dart: módulos cortos que se anteponen al mensaje según palabras clave (técnico, desahogo, fe, axel, debate). Máximo 2 por mensaje.
- Las versiones completas originales están respaldadas en docs/persona_full.md y docs/profile_full.md (no se cargan al modelo).
- Regla anti-invento: sin internet y con conocimiento posiblemente viejo, Axel no debe decirle al mae que está equivocado con seguridad en política, noticias, fechas, nombres y cifras (caso real: dijo que el presidente de Costa Rica en 2024 no era Rodrigo Chaves). Si el mensaje trae fuentes del cuaderno, se basa en ellas.

Voz
- Voz de entrada: speech_to_text, prefiere es-CR, luego es-419, es-MX, es-US, es-ES. El botón de micrófono dicta, y al terminar de hablar (unos 3 s de silencio) manda el mensaje solo.
- Voz de salida: flutter_tts, habla frase por frase mientras llega el streaming. Quita markdown y enlaces antes de leer. Botón de altavoz en la barra para silenciar. La lista de fuentes bajo la respuesta no se lee.
- Se corta la voz al tocar el micrófono, al enviar un mensaje y al abrir un chat nuevo.
- Pantalla "Voz de Axel" (lib/ui/settings/voice_settings_screen.dart) para elegir voz, velocidad y tono. DECISIÓN PENDIENTE: dejar una sola voz fija en el código (lib/voice/tts.dart tiene constantes voiceName y voiceLocale) y quitar el selector.

Chat
- Pantalla de chat con streaming, burbujas, botón de chat nuevo, altavoz, acceso al cuaderno y a ajustes. Botón de clip para adjuntar archivos.
- RAG del cuaderno en el chat general (ver sección RAG).

Cuaderno
- Un archivo JSON por elemento (entries/<uuid>.json). Los títulos pueden repetirse. Tipos: snippet, nota, foto (foto aún sin interfaz propia).
- Interfaz estilo NotebookLM con estética cómic: pestañas Fuentes y Studio.
  - Fuentes: búsqueda sin acentos ni mayúsculas, chips de filtro (Todo, Código, Notas, Fotos), tarjetas con icono de tipo, fecha, vista previa y etiquetas. Al tocar una tarjeta se abre una hoja inferior con el contenido completo, copiar, editar y borrar. Mantener presionado selecciona varias para borrar con confirmación. Botón AGREGAR con menú: snippet, nota (foto: próximamente).
  - Studio: tarjetas de ejemplo (Resumen, Preguntas de estudio, Índice de snippets, Mapa de etiquetas), todas marcadas "próximamente".
  - Se quitó la pestaña Chat del cuaderno: se pregunta al cuaderno desde el chat general de Axel.
- Editor para snippets y notas, con etiquetas separadas por coma.
- Escritura atómica (archivo temporal y renombrar).
- Deduplicación por id: si hay copias de conflicto de Syncthing, gana el updatedAt más reciente.
- Recarga automática cada 15 s, al volver a la app y al deslizar hacia abajo.
- Opción en Ajustes "Usar carpeta compartida" (/storage/emulated/0/Axel) con permiso de acceso a todos los archivos, copiando lo ya guardado.
- .stignore para que Syncthing no sincronice archivos .tmp.

Importador de documentos (lib/notebook/data/document_importer.dart, flujo en lib/ui/notebook/import_flow.dart)
- Formatos: PDF (syncfusion_flutter_pdf), Word .docx (archive, lee word/document.xml), .txt y .md. La extracción de PDF y docx corre en un Isolate para no congelar la interfaz.
- Limpieza del texto (saltos, espacios, NBSP) y tope de 300000 caracteres por documento (aviso de truncado).
- PDF escaneado (solo imagen): no se puede leer todavía, falta OCR. El importador lo avisa.
- pickPhoto() existe, pero la foto aún no se guarda con texto ni tiene interfaz (ver Pendiente de fotos).
- Con file_picker 13.x los bytes se leen con PlatformFile.readAsBytes() (ya no existe withData).
- Probado en el S24+: el documento de prueba "rag prueba" se importó y el RAG lo cita como fuente.

RAG (Cuaderno + LLM), lib/notebook/data/notebook_rag.dart
- Antes de cada mensaje se buscan hasta 3 fuentes relevantes (máximo 2 fragmentos por entrada) y se inyectan al prompt. Presupuesto real en el código: 450 caracteres por fragmento y 1400 en total (unos 350-450 tokens). Fragmentos de unos 420 caracteres; se indexan hasta 300000 caracteres por entrada.
- Búsqueda por palabras con stemming simple (primeras 5 letras), sin acentos. Título y etiquetas pesan 3, cuerpo pesa 1. Sin disparador necesita puntaje mínimo 3.
- Disparadores (_hints): activan la recuperación siempre. Si no hay coincidencias por palabras, trae las entradas más recientes. Lista ampliada el 28/10 con vocabulario de fotos, archivos y documentos: "foto", "imagen", "archivo", "documento", "pdf", "adjunt", "libreta", "subi", "te pase", "te mande", y frases de búsqueda como "le puse", "le habia puesto", "decia", "buscame", "que dia", "que fecha". Además de los originales ("cuaderno", "mis notas", "notas tengo", "que notas", "snippet", "tengo anotado", etc.). Si alguno dispara contexto sin venir al caso (por ejemplo "subi" o "que dia"), quitarlo de la lista.
- Modo estudio: si el mensaje trae "resum", "pregunt", "estudi", "repas" o "explic" y nombra el título de una entrada, usa fragmentos de ese documento. Documento corto: completo. Documento largo: muestra de inicio, medio y final, o "parte N" si el mae la pide.
- Si el mensaje no tiene que ver con el cuaderno, no se inyecta nada.
- Bajo la respuesta aparece "Fuentes: título · título" (no se lee en voz alta).
- Si el cuaderno falla, el chat sigue sin fuentes.

### EN CURSO (siguiente paso inmediato)

- [ ] Herramienta real "agregar nota" en el chat. HOY ES UN BUG: Axel dice "listo, agregué X a tus notas" pero NO guarda nada (alucinación de acción, no hay herramienta conectada). Debe ejecutar la acción de verdad y confirmar solo después de guardar.
- [ ] Axel dice "no tengo acceso a tu galería" cuando el mae pregunta por fotos o archivos subidos. Falta agregar a la persona una sección corta "Cuaderno y archivos subidos": distinguir la galería del teléfono (sin acceso) de lo que se subió a la app (sí llega por RAG), no decir "no tengo acceso" si hay contexto, y si no llegó nada decir que no aparece en el cuaderno. Medir el costo en tokens antes de aceptarla (la persona debe seguir bajo 900 tokens).
- [ ] Estudiar los documentos importados: validar el modo estudio con un documento real y, en Studio, resumen y preguntas generadas con los fragmentos relevantes (no el documento completo: el contexto es de 4096 tokens).
- [ ] Fechas en el RAG: "qué día subí la foto que dice X" necesita que _build incluya la fecha de cada fuente (hoy solo manda título y texto). Filtrar por "de ayer" o "de la semana" sería lógica aparte.

### Pendiente inmediato del cerebro

- [ ] Anotar backend usado (GPU o CPU), tok/s, calor y si Android cierra la app.
- [ ] Fijar temperatura y top-k (aún no se sabe cómo los expone el paquete).
- [ ] Probar E2B (más liviano), Qwen3 1.7B y FunctionGemma 270M.
- [ ] Commit.

### Pendiente de limpieza de build (no bloquea)

- [ ] gradle.properties tiene android.newDsl=false y android.builtInKotlin=false, ambos deprecados (se eliminan en AGP 10). Migrar cuando los plugins lo permitan.
- [ ] flutter_tts aplica el plugin de Kotlin (KGP). Flutter avisa que futuras versiones fallarán; revisar si hay versión de flutter_tts con Built-in Kotlin.
- [ ] compileSdk 37 es más nuevo que lo probado por AGP 9.1.0 (36.1); se silencia con android.suppressUnsupportedCompileSdk=37.
- [ ] Aviso "SDK XML version 4" por android-37.0: es solo un warning.
- [ ] 15 paquetes tienen versiones nuevas incompatibles con las restricciones actuales (flutter pub outdated).
- [ ] lib/router/intent_router.dart está vacío (no interviene en el RAG).

### NO implementado todavía

Cerebro y voz
- Palabra de activación "Hey Axel" (openWakeWord) y servicio en primer plano.
- Router de intención (reglas + FunctionGemma 270M) y capa de reflejos.
- Historial de conversaciones (conversation_store) y memoria del chat.
- Compresión del contexto: con 4096 tokens, las consultas con fuentes gastan unos 300 tokens cada una y el chat se reinicia antes. Hoy, si el contexto se llena, la conversación se resetea y se pierde el historial.
- Proveedores adicionales: Ollama en la laptop (vía Tailscale) y API compatible con OpenAI.
- Pantalla de ajustes funcional (hoy casi todo es informativo).
- Descarga del modelo desde la propia app (hoy se copia a mano).
- Voz neuronal local (SherpaTTS con Piper) como alternativa a las voces del sistema.

Herramientas del teléfono (archivos vacíos)
- Alarma y temporizador (intent AlarmClock).
- Abrir apps concretas.
- Buscar en YouTube.
- Mensaje de WhatsApp con confirmación obligatoria.
- Puente nativo Kotlin (platform channels).

Cuaderno
- Fotos: copia a almacenamiento privado, interfaz del tipo foto, y sobre todo texto asociado (descripción escrita o OCR). Una entrada con cuerpo vacío no entra al RAG, así que una foto sin texto nunca aparece en las respuestas. Falta decidir: descripción manual, OCR local o ambas.
- OCR para PDF escaneados.
- Etiquetas editables fuera del editor, mapa de etiquetas.
- Contenido real en Studio (resumen, preguntas, índice).
- Búsqueda semántica con embeddings locales (hoy es por palabras).
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

- LLM base: Gemma 4 E4B local en formato .litertlm. Probado en la Gallery: 8,5 tok/s, TTFT 1,1 s, 4,7 GB de RAM (43 %). El contexto real del motor es 4096. Candidato a residente más liviano: E2B (2,6 GB).
- Motor: paquete litertlm (Android y Windows con la misma API, sobre el runtime oficial LiteRT-LM).
- El modelo no va en el APK. Vive en /storage/emulated/0/Axel_models, fuera de la carpeta sincronizada.
- Persona compacta + módulos por situación + perfil compacto. El prompt completo original queda como respaldo en docs/. El perfil largo irá al cuaderno como entradas pequeñas (RAG) cuando se pueda.
- Un solo chat: el chat general de Axel consulta el cuaderno. No hay chat separado dentro del cuaderno.
- Voz: STT y TTS del sistema (speech_to_text, flutter_tts). Whisper vía sherpa-onnx y Piper quedan como plan B.
- Almacenamiento: archivos JSON como fuente de verdad (un archivo por elemento, UUID, borrado lógico, gana el updatedAt más reciente). Nada de pago. SQLite solo como índice local reconstruible, más adelante.
- Sincronización: Syncthing-Fork sobre la carpeta Axel. Limitación conocida: ambos dispositivos deben estar encendidos y con internet a la vez.
- Alternativa en la nube (no implementada): Supabase gratis para el texto. Los límites cambian; confirmar antes de usarla. Las fotos no caben en ese plan.
- Distribución: repositorio privado, APK instalado a mano. El arte (icono y logo) es solo de uso personal.
- Ollama: no es un modelo sino un programa para PC; se usará como "cerebro grande" en la laptop, como proveedor adicional.
- Selector de archivos: file_picker 13.3.0 (se subió desde 8.3.7 para quitar la dependencia de flutter_plugin_android_lifecycle y el choque de compileSdk).

## Arquitectura

```
Voz -> wake word -> STT del sistema -> texto
   v
Persona + módulos + RAG del cuaderno (fuentes relevantes)
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
  core/            config ✔ · axel_persona ✔ · user_profile ✔ · persona_modules ✔
  llm/             llm_provider ✔ · model_locator ✔
    providers/     echo ✔ · litert ✔ · ollama ○ · openai_compat ○
  router/          intent_router ○
  tools/           tool ✔ · tool_registry ✔
    builtin/       alarm ○ · open_app ○ · youtube ○ · whatsapp ○ · add_note (en curso)
  voice/           stt ✔ · tts ✔ · wake_word ○
  memory/          conversation_store ○
  platform/        native_bridge ○
  notebook/
    models/        entry ✔
    data/          entry_store ✔ · notebook_search ✔ · notebook_rag ✔ · storage_location ✔
                   document_importer ✔ (PDF, docx, txt, md) · note_command ✔
    sync/          sync_service ○
  ui/
    theme/         app_colors ✔ · app_theme ✔
    widgets/       comic_panel ✔ · halftone_background ✔ · empty_state ✔ · model_loader ✔
    chat/          chat_screen ✔
    notebook/      notebook_screen ✔ (Fuentes + Studio) · entry_editor_dialog ✔ · import_flow ✔
    settings/      settings_screen ✔ · voice_settings_screen ✔
docs/              PLAN · MODEL_TESTS · SECURITY · DEVICES · CONVENTIONS · NOTEBOOK
                   persona_full.md · profile_full.md (respaldos)
assets/branding/   law.png (logo inicio) · mainapp.jpg (icono) · icon.png · icon_fg.png
```

## Fases

0. Entorno y estructura (hecho)
1. Cascarón de UI, interfaz LLM y registro de herramientas (hecho)
2. Cuaderno: guardar, editar, buscar, copiar, carpeta compartida, interfaz tipo NotebookLM (hecho; falta validar el sync)
3. Cerebro: Gemma local en el chat (hecho; faltan mediciones de tok/s y calor)
4. STT en español y TTS (hecho; falta elegir la voz fija)
5. Cuaderno + LLM: RAG por palabras en el chat general (hecho)
5b. Herramienta agregar nota, importar Word y PDF (importador hecho), estudiar documentos <- EN CURSO
6. Validar sincronización (Syncthing-Fork) y decidir si hace falta nube
7. Herramientas del teléfono (alarma, apps, YouTube, WhatsApp)
8. Wake word "Axel" y servicio en primer plano
9. Historial y compresión de contexto
10. Agente de escritorio (Windows), Wake-on-LAN, escenas, tablet
11. Fotos en el cuaderno (con texto: descripción u OCR)
12. Asistente por defecto y accesibilidad (opcional)

## Lecciones aprendidas (para no repetir)

Gradle y Android
- Gradle fallaba con "immutable workspace modified": rutas demasiado largas (MAX_PATH) en C:\Users\Dell\.gradle. Solución: borrar la caché con prefijo \\?\ o robocopy, activar rutas largas y, si hace falta, mover la caché con GRADLE_USER_HOME=C:\g.
- permission_handler exige compileSdk 37: en android/app/build.gradle.kts se cambió a compileSdk = 37.
- Error "Failed to transform android.jar ... PlatformAttrTransform" en android-34: el android.jar quedó corrupto por una instalación del SDK interrumpida (Ctrl+C durante la descarga). Solución: parar daemons (cd android; .\gradlew --stop), borrar la carpeta platforms\android-34, borrar las cachés transforms* de Gradle, flutter clean y reinstalar "Android SDK Platform 34" completa, sin cancelar. Verificar que android.jar pese unos 26 MB.
- Nunca cancelar con Ctrl+C una descarga del SDK ni una build de Gradle a medias. Tras borrar cachés, la primera build es en frío y tarda unos 13 minutos; es normal que el OpenJDK suba y baje en CPU y memoria.
- Error "Dependency ':flutter_plugin_android_lifecycle' requires ... compile against version 36 or later; :file_picker is currently compiled against android-34": file_picker 8.3.7 fijaba compileSdk 34. Solución aplicada: subir file_picker a 13.3.0, que ya no depende de ese plugin. Alternativa descartada: forzar compileSdk en subprojects desde android/build.gradle.kts (el cast al DSL falla con android.newDsl=false y evaluationDependsOn complica el orden).
- El aviso "SDK XML version 4" lo causa el paquete android-37.0; es solo un warning. El sdkmanager está deprecado y quiere descargar "Android CLI"; si se cuelga, instalar la plataforma desde Android Studio (SDK Manager).
- pubspec.yaml: el bloque flutter_launcher_icons va fuera de la sección flutter, pegado al margen izquierdo.
- adb a veces pierde el teléfono: adb kill-server, adb start-server, adb devices. "Lost connection to device" suele ser cable o pantalla bloqueada; basta con volver a correr flutter run.
- Iconos nuevos y plugins nuevos requieren instalación completa, no hot reload.

file_picker 13.x (cambios de API)
- FilePicker.platform ya no existe: los métodos son estáticos (FilePicker.pickFiles).
- pickFiles devuelve Future<List<PlatformFile>> (ya no FilePickerResult con .files) y no tiene el parámetro withData.
- Los bytes se leen con await file.readAsBytes() (PlatformFile viene de file_picker_platform_interface). También hay xFile y readAsByteStream() para archivos grandes.
- Pendiente de verificar en el teléfono: qué devuelve al cancelar el selector (hoy el código trata la lista vacía como cancelación).

PowerShell
- Escribir archivos: usar UTF-8 sin BOM. En Windows PowerShell 5, Get-Content -Raw sin -Encoding puede convertir tildes en basura (Ã¡). Preferir [System.IO.File]::ReadAllText/WriteAllText con UTF8Encoding($false). Lo que se ve como "Ã¡" al imprimir con Get-Content en la consola suele ser solo cómo la consola muestra el archivo, no un daño real.
- En parches de PowerShell, nunca poner `n (salto de línea de PowerShell) dentro de un string de Dart: lo convierte en un salto real y rompe el string. Usar here-strings (@' ... '@) con Patch-Src, y \n literal dentro del código Dart.
- Select-String no tiene -Recurse. Para buscar en subcarpetas: Get-ChildItem lib -Recurse -Filter *.dart | Select-String -Pattern '...'.
- Ejecutar los comandos de proyecto desde la raíz (Voice_Agent_Flutter); si se ejecuta desde android\, las rutas relativas quedan duplicadas (android\android\...).
- Un README con bloques de código dentro de un bloque de código se rompe al pegar: entregarlo como archivo o con un bloque exterior de cuatro comillas.
- Vecteezy bloquea descargas por script (403): bajar las imágenes desde el navegador.

Modelo, voz y RAG
- Error "Input token ids are too long (4656 >= 4096)": el system prompt original era de unos 4500 tokens. Mantener persona y perfil compactos y medir con el aviso de debug.
- speech_to_text: localeId, listenFor y pauseFor van dentro de SpeechListenOptions (los parámetros sueltos están deprecados).
- Un modelo de 4B atiende mal el historial largo y sin internet inventa datos (nombres, política, cifras). Los datos que importen se guardan como notas del cuaderno para que el RAG los use.
- "Notas" es ambiguo (calificaciones vs. cuaderno). Los disparadores del RAG cubren "notas tengo", "que notas", "mis notas", etc.
- Axel no debe afirmar acciones que no ejecutó: toda acción (agregar nota, enviar mensaje) debe pasar por una herramienta real y confirmar solo después de ejecutarla.
- El RAG solo se activa con un disparador o con coincidencia de título/etiquetas (puntaje 3). "qué fotos tengo ?" no tenía ningún disparador (los verbos y "tengo" son stopwords), no recuperaba nada y Axel contestaba "no tengo acceso a tu galería". Por eso se ampliaron los _hints. Si una consulta natural no recupera nada, mirar primero esa lista.
- El RAG descarta entradas con cuerpo vacío: toda fuente (foto, documento) necesita texto para poder aparecer.

## Límites conocidos

- Android y Windows no permiten que una app desbloquee la pantalla con voz; la voz no es autenticación. Alternativa: encender, abrir programas y desbloquear con huella o rostro.
- Wake-on-LAN depende de la BIOS y del cable Ethernet.
- Samsung puede matar servicios en segundo plano: excluir Axel y Syncthing-Fork de la optimización de batería.
- Modelos locales de 2B a 4B no igualan a Gemini en la nube: razonamiento largo, código y datos actuales son su punto débil. Inicializar el modelo es lento (hay que cargarlo una sola vez).
- Contexto de 4096 tokens: el RAG inyecta pocas fuentes y fragmentos cortos; los documentos grandes (Word, PDF) se parten en fragmentos y solo entran los más relevantes.
- El RAG busca por palabras, no por significado: conviene dar títulos y etiquetas claros a las fuentes.
- Axel no ve imágenes: el modelo local no las interpreta aquí. Una foto solo es útil si tiene texto asociado (descripción u OCR).
- La voz del sistema (TTS) suena más robótica que una IA en la nube.
- Los datos sensibles (claves, contraseñas) no van en texto plano en el cuaderno.
- Google Play restringe el uso de accesibilidad: no se publicará allí.

## Seguridad

- Confirmar antes de enviar mensajes, comprar o borrar.
- Comandos entre dispositivos firmados y cifrados, con emparejamiento por QR.
- No enviar capturas de pantalla sin avisar.
- La voz da la orden, pero no autentica.
- Axel solo confirma una acción cuando una herramienta real la ejecutó.

## Comandos

```
flutter doctor -v
flutter devices
flutter analyze
flutter pub get
flutter pub outdated
flutter clean
flutter run -d R5CX11KC2WH
flutter build apk --release
cd android; .\gradlew --stop        (parar daemons de Gradle)
adb -s R5CX11KC2WH push <archivo> /sdcard/Axel_models/
```

Documentos: docs/CONVENTIONS.md, docs/NOTEBOOK.md, docs/MODEL_TESTS.md, docs/SECURITY.md, docs/DEVICES.md, docs/persona_full.md, docs/profile_full.md.