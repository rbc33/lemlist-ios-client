# LemPulse

App nativa en SwiftUI (iOS 17+) para controlar tus campañas de lemlist: ver campañas y su estado,
pausarlas/reanudarlas, ver estadísticas básicas, listar los mailboxes conectados con su límite de
envío, ver la puntuación de warmup (deliverability score) y ajustar los parámetros de warmup.

## Poner en marcha el proyecto

Este repo no incluye un `.xcodeproj` — se genera con [XcodeGen](https://github.com/yonaskolb/XcodeGen)
para no tener que arrastrar un pbxproj binario de un lado a otro.

```bash
brew install xcodegen
cd LemPulse
xcodegen generate
open LemPulse.xcodeproj
```

En Xcode: selecciona el target `LemPulse` → pestaña **Signing & Capabilities** → elige tu Team
(tu Apple ID personal vale, igual que haces con Ghostbar/AIclient). Luego build & run, o exporta el
`.ipa` para instalarlo con AltStore como sueles hacer.

Si prefieres no usar XcodeGen: crea un proyecto nuevo en Xcode ("App", interfaz SwiftUI, iOS 17),
borra el `ContentView.swift`/`App.swift` que genera por defecto, y arrastra dentro el contenido de
`Sources/` conservando la estructura de carpetas.

## Cómo funciona

- **Autenticación**: en Ajustes pegas tu API key de lemlist (Settings → Integrations en
  app.lemlist.com). Se guarda en el Keychain del dispositivo, nunca en texto plano ni en UserDefaults.
  La API usa Basic Auth con usuario vacío y la API key como contraseña.
- **Campañas** (`GET /campaigns?version=v2`): lista con estado, filtro por estado, swipe para
  pausar/reanudar (`POST /campaigns/{id}/pause` y `/start`), y detalle con estadísticas de los
  últimos 30 días (`GET /v2/campaigns/{id}/stats`).
- **Mailboxes**: se obtiene la lista de miembros del equipo (`GET /team?version=v2`) y para cada uno
  se piden sus mailboxes (`GET /users/{userId}`), que incluyen el límite diario de envío
  (`lemlist.emailLimit`) y si el warmup está activo. Si el warmup está activo, se pide además
  `GET /lemwarm/{mailboxId}/settings` para la puntuación de deliverability.
- **Warmup**: puedes pausar/reanudar el warmup de cada mailbox y editar el máximo diario de emails
  de warmup y el incremento diario (`PATCH /lemwarm/{mailboxId}/settings`).

### Limitación importante de la API pública

lemlist **no expone un endpoint para modificar el límite diario de envío de campañas**
(`mailbox.lemlist.emailLimit`) — solo se puede ver. Lo único editable vía API relacionado con
límites es la configuración de warmup (`warmEmailMax` / `warmEmailRampup`). La app lo deja claro en
la pantalla de detalle del mailbox: el límite de campañas se muestra de solo lectura, y el bloque de
warmup es el editable. Si algún día lemlist añade un endpoint de escritura para `emailLimit`, solo
hay que añadir un método más en `LemlistAPIClient`.

## Estructura

```
Sources/
  LemPulseApp.swift          — punto de entrada
  App/AppSettings.swift      — estado observable de "¿hay API key guardada?"
  Models/                    — structs Codable (Campaign, Team, Mailbox, LemwarmSettings, Stats)
  Networking/                — KeychainStore, APIError, LemlistAPIClient (actor)
  Views/
    ContentView.swift        — TabView raíz
    Campaigns/                — lista + fila + detalle de campañas
    Mailboxes/                — lista + fila + detalle de mailboxes + gauge de warmup
    Settings/                 — pantalla de Ajustes con la API key
    Shared/                   — vistas de estado vacío/error reutilizables
```
