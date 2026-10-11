# Dungeon Soldier — TP LÖVE2D

Juego 2D top-down estilo Zelda clásico hecho en Lua + LÖVE2D, con dos
niveles: el nivel 1 es un mapa de teselas fijo hecho en Tiled (dos salas
conectadas por una puerta interactiva), y el nivel 2 se **genera
proceduralmente** en cada partida (habitaciones y pasillos al azar, con
enemigos y props distribuidos sobre el piso generado). Cámara que sigue al
jugador y máquinas de estado reales tanto para el flujo del juego
(gameplay/pausa/victoria/derrota) como para el jugador y los enemigos. El
HUD (corazones de vida + segmentos de estamina) se actualiza mediante un
sistema de eventos personalizado, no leyendo las variables del jugador
cuadro a cuadro (ver "HUD y sistema de eventos" más abajo).

## Cómo ejecutar

1. Instalar [LÖVE2D](https://love2d.org/) (11.x).
2. Desde la carpeta del proyecto:

   ```bash
   love .
   ```

   O arrastrar la carpeta `D:\OBJ2D` sobre `love.exe`.

## Controles

| Acción                        | Tecla            |
|-------------------------------|------------------|
| Moverse                       | WASD o flechas   |
| Atacar (gasta 1 de estamina)  | ESPACIO          |
| Interactuar (puerta/llave/cofre/corazón) | F (cerca del objeto) |
| Pausar / continuar            | ESC              |
| Reiniciar                     | R (tras ganar/perder) |

## Estructura del proyecto

```
main.lua          -- callbacks de LOVE, delega todo a src/game.lua
conf.lua          -- configuracion de ventana

lib/               -- librerias externas (vendored, no se tocan)
  sti/            -- Simple Tiled Implementation: carga y dibuja el mapa de teselas
  hump/           -- camera.lua (camara) y timer.lua (eventos temporales)

Assets/maps/
  dungeon.tmx     -- mapa fuente, editable con el editor Tiled
  dungeon.lua     -- el mismo mapa exportado a Lua (lo que carga STI en runtime)

src/
  constants.lua   -- valores de balance (velocidad, daño, rangos, estamina, HUD, etc.)
  assets.lua      -- carga centralizada de imagenes y sonidos
  animation.lua   -- reproductor generico de spritesheets
  combat.lua      -- colisiones AABB, hitbox de ataque, movimiento con colision
  systems/
    state_machine.lua -- maquina de estados generica (game + entidades la comparten)
    events.lua         -- bus de eventos personalizado (on/off/emit), instancia unica global
    audio_system.lua   -- escucha PLAYER_DAMAGED/PLAYER_HEALED y reproduce el sonido correspondiente
    viewport.lua        -- escalado/centrado del juego dentro de la ventana real
  states/
    gameplay_state.lua -- la partida en si: mueve entidades, resuelve combate, emite ROOM_COMPLETED
    pause_state.lua     -- pausa (ESC): congela el gameplay sin ningun flag "paused"
    victory_state.lua  -- pantalla de victoria
    defeat_state.lua   -- pantalla de derrota
  player.lua      -- Soldier: maquina de estados idle/walk/attack/dead; vida/estamina; emite eventos
  enemy.lua       -- Blood Monster: maquina de estados idle/chase/attack/hurt/dead
  door.lua        -- puerta interactiva (nivel 1) / stub sin puerta (nivel 2)
  key.lua         -- llave recogible (aparece al matar a todos los enemigos)
  heart_pickup.lua -- corazon de recuperacion (aparece al completar una sala, ver ROOM_COMPLETED)
  chest.lua       -- cofre: abre con la llave, pasa de nivel o dispara la victoria
  dungeon.lua     -- carga el mapa de teselas (STI, fijo o generado) y expone paredes/spawns/props
  procedural_dungeon.lua -- genera el nivel 2: habitaciones+pasillos al azar, en el mismo formato que exporta Tiled
  ui.lua          -- HUD (corazones/estamina via eventos), cartel de interaccion, mensajes, pausa, victoria/derrota
  game.lua        -- orquesta todo: maquina de estados del juego, nivel actual, camara, colisiones, "RewardSystem"

Assets/Hud/       -- sprites del HUD: corazones (full/half/empty.png) y estamina (L/M/R stamina.png + sus "empty")
```

## Mapeo con la consigna

- **Personaje interactivo** → `player.lua` (movimiento 4 direcciones, ataque,
  vida, estado, animación).
- **Entidades preprogramadas** → `enemy.lua` (Blood Monster con IA de
  detección/persecución/ataque), `door.lua` (puerta interactiva), `key.lua`
  y `chest.lua` (objetivo final).
- **Interacción del jugador** → ataque con SPACE (`player.lua`) y F para
  interactuar con puerta / llave / cofre (`Game.keypressed`), con carteles
  contextuales ("Presiona F para abrir", "Presiona F para recoger").
- **Comportamiento del enemigo** → `enemy.lua`, máquina de estados
  IDLE → CHASE → ATTACK, con HURT y DEAD como interrupciones. Los enemigos
  de la sala 2 nacen con `active = false` y no ejecutan `update()` (o sea,
  ninguna lógica de IA) hasta que la puerta pasa a estado `"open"`
  (`Game.update`).
- **Secuencia de victoria** → matar a todos los enemigos → aparece la
  llave (`Game.allEnemiesDead`) → recogerla con F (`key.lua`) → ir hasta
  el cofre y presionar F (`chest.lua`); sin la llave el cofre muestra
  "Necesitas una llave" y no se abre. Abrir el cofre del nivel 1 pasa al
  nivel 2 (`GameplayState:tecla`, `game.machine:cambiar("gameplay", {level=2})`);
  abrir el cofre del nivel 2 (el último) dispara la victoria real.
- **Condición de derrota** → HP del jugador llega a 0, se reproduce la
  animación de muerte y luego se muestra "DERROTA" (`Game.update`).
- **Feedback visual** → parpadeo del jugador al recibir daño, flash blanco
  del enemigo al ser golpeado, animaciones de ataque/muerte, oscurecimiento
  de la sala 2 hasta abrir la puerta (con velas que se encienden).
- **Feedback auditivo** → `assets/sounds/hit.mp3` (golpe conectado, tanto del
  jugador como del enemigo) y `assets/sounds/misshit.mp3` (ataque del
  jugador que no conecta).

## HUD y sistema de eventos

### Corazones (vida)

Tres corazones (`Assets/Hud/full.png` / `half.png` / `empty.png`), cada uno
representando `PLAYER_MAX_HP / 3` de vida real. La vida **sigue siendo**
`Player.hp` (0-100, sin tocar daño ni balance): `UI.lua` traduce esa vida a
una escala de 0 a 3 "corazones" (`hp/maxHp*3`) y, para cada uno de los 3
corazones, calcula cuánto de *ese* corazón puntual está lleno
(`clamp(heartsTotal - (i-1), 0, 1)`) para elegir el sprite — lleno, medio o
vacío. No hay una segunda variable de vida: si mañana cambia `PLAYER_MAX_HP`,
los corazones se siguen calculando bien solos.

### Estamina

No existía ningún sistema de estamina en el proyecto. Se agregó uno simple,
integrado con lo que ya había: 3 unidades (`Constants.PLAYER_MAX_STAMINA`),
se gasta 1 por ataque (`Player:tryAttack`) y se regenera 1 unidad sola cada
`STAMINA_REGEN_INTERVAL` segundos sin gastar. **Decisión de diseño:** no
bloquea el ataque al llegar a 0 — agregar esa restricción cambiaría el
combate ya balanceado, y la consigna de este TP pide integrar eventos/HUD,
no rediseñar el combate (queda documentado también en el comentario de
`Constants.PLAYER_MAX_STAMINA`). Cada uno de los 3 segmentos del HUD
(`L/M/R stamina.png`, con sus versiones `empty`) solo tiene 2 estados
posibles (lleno/vacío, no hay sprite de "medio" para estamina), así que no
se inventó ningún estado intermedio.

### Qué es un evento personalizado acá

`src/systems/events.lua` es un bus de eventos (publicador/suscriptor)
genérico, una única instancia global (`Events`), igual de "singleton" que
`Game`/`Dungeon`/`Assets`, que ya eran así en el proyecto:

```lua
local handle = Events:on(Events.PLAYER_HEALTH_CHANGED, function(hp, maxHp) ... end)
Events:emit(Events.PLAYER_HEALTH_CHANGED, hp, maxHp)
Events:off(handle)
```

- `Events:on(nombre, callback)` suscribe `callback` y devuelve un `handle`
  opaco (necesario para poder des-suscribirse después, porque una misma
  función podría suscribirse más de una vez).
- `Events:emit(nombre, ...)` llama a todos los suscriptores de ese evento,
  pasándoles `...` tal cual.
- `Events:off(handle)` saca esa suscripción puntual.

Los nombres de evento están centralizados como constantes en el propio
módulo (`Events.PLAYER_HEALTH_CHANGED`, etc.) para que ningún archivo tenga
que escribir el string a mano y arriesgarse a un typo silencioso.

### Eventos implementados

| Evento | Lo emite | Payload | Lo escucha |
|---|---|---|---|
| `PLAYER_HEALTH_CHANGED` | `Player:takeDamage` / `Player:heal` / `Player.new` | `hp, maxHp` | `ui.lua` (corazones) |
| `PLAYER_STAMINA_CHANGED` | `Player:consumeStamina` / regen en `Player:update` / `Player.new` | `stamina, maxStamina` | `ui.lua` (segmentos) |
| `PLAYER_DAMAGED` | `Player:takeDamage` (solo si el daño se aplicó de verdad) | `amount` | `systems/audio_system.lua` |
| `PLAYER_HEALED` | `Player:heal` (solo si curó algo) | `amount` | `systems/audio_system.lua` |
| `ROOM_COMPLETED` | `GameplayState:actualizar` (mismo punto donde ya aparecía la llave) | — | `game.lua` ("RewardSystem": genera el corazón de recuperación) |
| `HEALTH_PICKUP_COLLECTED` | `HeartPickup:collect` | — | (disponible para quien lo necesite; hoy no tiene suscriptor propio) |

### Comunicación entre objetos

Nadie se conoce directamente: `Player` no sabe que existe un HUD, `ui.lua`
no sabe que existe un `Player`, y `GameplayState` no sabe que existe un
corazón de recuperación.

```text
Player:takeDamage()
        │
        ├─ modifica Player.hp (unica fuente de verdad)
        └─ Events:emit(PLAYER_HEALTH_CHANGED, hp, maxHp)
                │                         └─ Events:emit(PLAYER_DAMAGED, amount)
                ▼                                   ▼
        ui.lua actualiza su copia            audio_system.lua reproduce
        local (para dibujar corazones)       Assets.sounds.hit
```

```text
GameplayState:actualizar()  (sala completada: allEnemiesDead() paso a true)
        │
        └─ Events:emit(ROOM_COMPLETED)
                │
                ▼
        game.lua (suscrito desde que se carga el modulo)
        crea HeartPickup en Dungeon.healSpawnPos
```

`ui.lua` y `systems/audio_system.lua` se suscriben **una sola vez**, al
cargarse el módulo (con `require`, que en Lua solo ejecuta el archivo la
primera vez) — viven toda la partida, así que no hace falta
des-suscribirlos nunca ni correr riesgo de duplicar la suscripción.
`Player`/`Enemy`, en cambio, se recrean en cada nivel (`Game.setupEntities`)
pero nunca se *suscriben* a nada, solo emiten — así que tampoco dejan
suscripciones colgadas cuando se descartan. Por eso no hace falta
desuscribir nada en este proyecto en particular, aunque `Events:off` existe
y funciona para el caso en que sí hiciera falta.

### Corazón de recuperación (sala completada)

Reutiliza la condición que ya existía para la llave
(`Game.allEnemiesDead()`, en `GameplayState:actualizar`) — no hay una
segunda detección de "sala completada". En ese mismo punto se emite
`ROOM_COMPLETED`; quien escucha (`game.lua`) instancia un `HeartPickup` en
`Dungeon.healSpawnPos`, un punto fijo definido junto al cofre tanto en el
mapa fijo (`Assets/maps/dungeon.lua`/`.tmx`, verificado contra la grilla
real de paredes para que no caiga encima de una) como en el generador
procedural (`addObject("heal_spawn", cx, cy + 1, {})`, al lado opuesto de
`key_spawn` para no superponerse). Se recoge con F, igual que la llave/el
cofre/la puerta (mismo mecanismo de interacción por proximidad que ya usaba
todo el proyecto). **Si el jugador ya está al máximo de vida**, igual se
puede recoger (no queda bloqueado esperando a que el jugador esté
lastimado) pero no se cura nada de más — `Player:heal` clampea sola al
máximo y solo emite `PLAYER_HEALED` si realmente curó algo.

### Respuestas visuales y sonoras

| Evento | Visual | Sonido |
|---|---|---|
| Daño recibido | Parpadeo rojo del jugador (`Player.hurtFlashTimer`, ya existía) | `Assets.sounds.hit`, ahora disparado por `audio_system.lua` escuchando `PLAYER_DAMAGED` |
| Vida recuperada | Parpadeo verdoso breve (`Player.healFlashTimer`, nuevo) | Preparado (`audio_system.lua` ya escucha `PLAYER_HEALED`) pero **sin sonido real**: el proyecto no tiene ningún archivo de audio de curación (solo `hit.mp3`/`misshit.mp3`, ambos de combate) — no se inventó ninguna ruta. Para activarlo alcanza con agregar el archivo y una línea en `assets.lua` (`Assets.sounds.heal = love.audio.newSource(...)`). |
| Estamina cambia | Los 3 segmentos del HUD se redibujan solos (vía evento) | No hay sonido apropiado existente para esto; no se agregó ninguno |

El sonido de "jugador recibe daño" **ya existía** pero se reproducía
directo desde `Game.resolveCombat` en el mismo momento en que se llamaba a
`player:takeDamage`, incluso si el jugador estaba invulnerable y
`takeDamage` no aplicaba nada. Al migrarlo a escuchar `PLAYER_DAMAGED`
(emitido solo cuando el daño se aplica de verdad), de paso se corrigió ese
caso: ya no suena el golpe si el jugador estaba invulnerable.

## Decisiones de diseño a mencionar en la defensa

- **Generación procedural del nivel 2** (`src/procedural_dungeon.lua`):
  algoritmo clásico de roguelike simple — coloca entre 4 y 6 habitaciones
  rectangulares de tamaño al azar sin que se superpongan (reintentando
  posiciones), las conecta en cadena con pasillos rectos en "L", y convierte
  en pared sólida cualquier celda vacía pegada a una celda de piso (así
  cualquier forma de sala/pasillo queda automáticamente rodeada sin tener
  que razonar caso por caso). Entre 5 y 8 enemigos y algunas velas se
  reparten sobre celdas de piso al azar. El resultado **no es un nivel
  paralelo aparte**: `ProceduralDungeon.generate()` arma una tabla Lua con
  el mismo formato que exporta Tiled (mismos `tilesets`/`layers` que
  `Assets/maps/dungeon.lua`), y se la pasa directo a `sti(map)` — STI acepta
  tanto una ruta a archivo como una tabla ya construida. Por eso todo lo
  demás (paredes por la propiedad `collidable`, spawns por la capa de
  objetos, dibujado, colisiones, cámara) es el mismo código que usa el
  nivel 1, sin duplicar nada.
- Los sprites de Soldier y Blood Monster son tiras de una sola dirección
  (miran a la derecha). Para el movimiento en 4 direcciones se usa flip
  horizontal automático y una variable `facing` independiente (arriba/abajo/
  izquierda/derecha) que posiciona el hitbox de ataque correctamente incluso
  en los movimientos verticales.
- Cámara (`lib/hump/camera.lua`): el mapa (1392x576 px de mundo) es más
  ancho que la ventana (1280x720), así que la cámara sigue al jugador y se
  recorta a los límites del mapa (`Game.updateCamera`, en `src/game.lua`)
  para que nunca se vea "fuera" de la dungeon.
- La sala 2 se dibuja oscurecida (overlay negro semitransparente) hasta que
  se abre la puerta; al abrirla, la oscuridad se desvanece y las velas de
  piso pasan de apagadas a encendidas — es la puesta en práctica visual de
  "la puerta separa las dos partes y al abrirla se ilumina".
- **Por qué las hitboxes se sentían desalineadas (y cómo se corrigió):** los
  spritesheets de Soldier y Blood Monster miden 100px de alto por frame,
  pero el personaje dibujado ocupa apenas hasta la fila ~57-60 — el resto
  es relleno transparente. `Animation` anclaba siempre en la fila 100
  (`frameH`), asi que el punto usado para colisionar (`entity.y`) quedaba
  ~40px por debajo de los pies reales del sprite. Eso hacía que el jugador
  pareciera atravesar una pared antes de chocar (por arriba) o frenar antes
  de tocarla (por abajo) — no era un problema de las paredes en sí (su rect
  de colisión y de dibujado siempre fueron el mismo), sino del punto de
  referencia del personaje. La corrección (`Assets.footRow`, calculado leyendo
  los píxeles reales de cada spritesheet en `assets.lua`) mide en píxeles
  dónde termina de verdad cada sprite y usa esa fila como origen de anclaje
  en `Animation:draw`, sin tocar ninguna hitbox a mano.
