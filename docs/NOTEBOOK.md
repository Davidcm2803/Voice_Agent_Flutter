# Cuaderno y sincronización

Uso personal y privado. Mismo código en S24+, tablet S10 FE y laptop Windows.

## Reglas
- Todo elemento se identifica por UUID; el título puede repetirse.
- Un archivo JSON por elemento: `Axel/entries/<id>.json`.
- Fotos en `Axel/attachments/<id>_<n>.jpg`.
- Conflictos: gana el `updatedAt` más reciente; el otro se conserva como copia.
- Borrado lógico (`deleted: true`) para que el borrado también se sincronice.
- Datos sensibles (claves, contraseñas) no se guardan en texto plano.

## Sincronización
1. Fase A: Syncthing sobre la carpeta `Axel` (validar acceso en Android 16).
2. Fase B (si hace falta): sync propio por Tailscale con la laptop como hub.

## Luego
- Búsqueda por texto y etiquetas.
- El LLM consulta el cuaderno (resumir, encontrar un comando, responder sobre tus notas).
