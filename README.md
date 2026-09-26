# Dungeon Soldier — TP LÖVE2D

Juego 2D top-down estilo Zelda clásico hecho en Lua + LÖVE2D, con dos
niveles: el nivel 1 es un mapa de teselas fijo hecho en Tiled (dos salas
conectadas por una puerta interactiva), y el nivel 2 se **genera
proceduralmente** en cada partida (habitaciones y pasillos al azar, con
enemigos y props distribuidos sobre el piso generado). Cámara que sigue al
jugador y máquinas de estado reales tanto para el flujo del juego
(gameplay/victoria/derrota) como para el jugador y los enemigos.

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
| Atacar                        | ESPACIO          |
| Interactuar (puerta/llave/cofre) | F (cerca del objeto) |
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
  constants.lua   -- valores de balance (velocidad, daño, rangos, etc.)
  assets.lua      -- carga centralizada de imagenes y sonidos
  animation.lua   -- reproductor generico de spritesheets
  combat.lua      -- colisiones AABB, hitbox de ataque, movimiento con colision
  systems/
    state_machine.lua -- maquina de estados generica (game + entidades la comparten)
  states/
    gameplay_state.lua -- la partida en si: mueve entidades, resuelve combate
    victory_state.lua  -- pantalla de victoria
    defeat_state.lua   -- pantalla de derrota
  player.lua      -- Soldier: maquina de estados idle/walk/attack/dead
  enemy.lua       -- Blood Monster: maquina de estados idle/chase/attack/hurt/dead
  door.lua        -- puerta interactiva (nivel 1) / stub sin puerta (nivel 2)
  key.lua         -- llave recogible (aparece al matar a todos los enemigos)
  chest.lua       -- cofre: abre con la llave, pasa de nivel o dispara la victoria
  dungeon.lua     -- carga el mapa de teselas (STI, fijo o generado) y expone paredes/spawns/props
  procedural_dungeon.lua -- genera el nivel 2: habitaciones+pasillos al azar, en el mismo formato que exporta Tiled
  ui.lua          -- HUD, cartel de interaccion, mensajes, pantallas de victoria/derrota
  game.lua        -- orquesta todo: maquina de estados del juego, nivel actual, camara, colisiones
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
