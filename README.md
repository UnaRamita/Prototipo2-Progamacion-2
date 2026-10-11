# Dungeon Soldier — TP LÖVE2D

Juego 2D top-down estilo Zelda clásico, hecho en Lua sobre el framework
LÖVE2D. Un soldado explora una mazmorra de dos niveles, combate enemigos
cuerpo a cuerpo, recoge objetos y progresa hasta completar el juego.

## Cómo ejecutar

1. Instalar [LÖVE2D](https://love2d.org/) (11.x).
2. Desde la carpeta del proyecto:

   ```bash
   love .
   ```

## Controles

| Acción                                   | Tecla                 |
|-------------------------------------------|-----------------------|
| Moverse                                    | WASD o flechas         |
| Atacar                                     | ESPACIO                |
| Interactuar (puerta / llave / cofre / corazón) | F (cerca del objeto) |
| Pausar / continuar                         | ESC                    |
| Reiniciar                                  | R (tras ganar o perder)|

La ventana es redimensionable: el juego se reescala y se centra solo,
manteniendo siempre su proporción original.

## Funcionalidades

### Jugador

El personaje (Soldier) se mueve en las 4 direcciones, ataca cuerpo a cuerpo
con un hitbox direccional, y tiene una barra de vida y una de estamina. Al
recibir daño queda brevemente invulnerable y es empujado en dirección
opuesta al golpe. Su comportamiento está organizado en estados: inactivo,
caminando, atacando y muerto.

### Enemigos

El Blood Monster detecta al jugador por distancia, lo persigue en línea
recta y ataca cuando está lo bastante cerca. Sus estados son: inactivo,
persiguiendo, atacando, lastimado y muerto. Al morir reproduce su
animación y desaparece.

### Combate

Los ataques del jugador y los enemigos usan hitboxes rectangulares
proyectados según la dirección en la que mira cada uno. Los golpes
conectados reproducen un sonido de impacto; un ataque del jugador que no
conecta reproduce un sonido distinto.

### Niveles

El juego tiene dos niveles consecutivos:

- **Nivel 1**: mapa de teselas fijo, creado en el editor Tiled (dos salas
  conectadas por una puerta interactiva que se abre al acercarse e
  interactuar).
- **Nivel 2**: mapa de teselas generado proceduralmente en cada partida —
  habitaciones de tamaño y posición aleatoria conectadas por pasillos, con
  enemigos y elementos decorativos distribuidos sobre el piso generado.
  Las paredes eligen su textura (pared superior/inferior/lateral o esquina)
  según sus celdas vecinas, no según su posición absoluta.

En ambos niveles, derrotar a todos los enemigos hace aparecer una llave;
recogerla y llevarla hasta el cofre lo abre. Abrir el cofre del nivel 1
pasa al nivel 2; abrir el del nivel 2 termina el juego con victoria.

### Cámara

La cámara sigue al jugador y se mantiene dentro de los límites del nivel
actual, sea cual sea su tamaño real.

### Ventana y escalado

La resolución de la ventana puede cambiar libremente (se puede agrandar,
achicar o usar otra proporción). El juego se dibuja siempre a una
resolución fija internamente y esa imagen se escala de forma uniforme y se
centra dentro de la ventana real, sin deformarse y sin recortar el nivel.
El espacio sobrante se rellena con el color de fondo del juego.

### Pausa

Presionar ESC durante la partida congela el juego (nada se mueve, ni
jugador ni enemigos, ni corre ningún temporizador de gameplay) y muestra
una pantalla de pausa superpuesta. Presionar ESC de nuevo continúa la
partida exactamente donde quedó.

### HUD

La vida del jugador se muestra como tres corazones, cada uno con tres
estados posibles (lleno, medio, vacío). La estamina se muestra como una
barra de tres segmentos, cada uno lleno o vacío. Ambos indicadores se
actualizan automáticamente cuando cambia la vida o la estamina real del
jugador.

### Estamina

El jugador tiene 3 unidades de estamina. Atacar consume una unidad; la
estamina se recupera sola con el tiempo si no se sigue atacando.

### Sala completada y corazón de recuperación

Al derrotar a todos los enemigos de un nivel aparece, junto al cofre, un
corazón de recuperación. Al recogerlo, el jugador recupera una porción de
vida (sin superar el máximo).

### Sistema de eventos

Los distintos sistemas del juego (interfaz, audio, generación de
recompensas) se comunican entre sí mediante eventos, en vez de consultarse
directamente unos a otros. Cuando cambia la vida o la estamina del
jugador, cuando el jugador recibe daño o se cura, o cuando se completa una
sala, el juego emite un evento correspondiente; cada sistema interesado
reacciona por su cuenta (la interfaz se redibuja, se reproduce un sonido,
aparece el corazón de recompensa).

### Audio

El juego reproduce sonidos para: golpe conectado (jugador o enemigo),
ataque del jugador que falla, y daño recibido por el jugador. La
recuperación de vida tiene su respuesta visual (un breve destello) y su
mecanismo de sonido ya preparado, a la espera de un archivo de audio de
curación todavía no incluido en el proyecto.

## Estructura del proyecto

```
main.lua          -- callbacks de LOVE, delega todo a src/game.lua
conf.lua          -- configuracion de ventana

lib/
  sti/            -- Simple Tiled Implementation: carga y dibuja mapas de teselas
  hump/           -- camera.lua (camara) y timer.lua (eventos temporales)

Assets/
  maps/           -- dungeon.tmx (editable en Tiled) y dungeon.lua (exportado, usado en runtime)
  dungeon/        -- tileset y sprites de props de la mazmorra
  soldier/        -- spritesheets del jugador
  blood monster/  -- spritesheets del enemigo
  Hud/            -- sprites de corazones y estamina
  sounds/         -- efectos de sonido

src/
  constants.lua           -- valores de balance y configuracion
  assets.lua              -- carga centralizada de imagenes y sonidos
  animation.lua           -- reproductor generico de spritesheets
  combat.lua              -- colisiones, hitboxes, movimiento con colision
  player.lua              -- jugador: movimiento, combate, vida, estamina
  enemy.lua               -- enemigo: IA y combate
  door.lua                -- puerta interactiva
  key.lua                 -- llave recogible
  chest.lua               -- cofre final de cada nivel
  heart_pickup.lua        -- corazon de recuperacion
  dungeon.lua             -- carga y dibuja el mapa de teselas del nivel actual
  procedural_dungeon.lua  -- genera el nivel 2
  ui.lua                  -- HUD, carteles de interaccion, pantallas de pausa/victoria/derrota
  game.lua                -- orquestacion general: entidades, camara, colisiones, niveles
  systems/
    state_machine.lua     -- maquina de estados generica
    events.lua            -- bus de eventos
    audio_system.lua       -- respuestas de audio a eventos del jugador
    viewport.lua           -- escalado/centrado de la ventana
  states/
    gameplay_state.lua     -- partida en curso
    pause_state.lua         -- pausa
    victory_state.lua       -- pantalla de victoria
    defeat_state.lua        -- pantalla de derrota
```

## Cumplimiento de la consigna

### Máquinas de estado

El proyecto usa una máquina de estados genérica y reutilizable
(`src/systems/state_machine.lua`), con cuatro métodos por estado
(`ingresar`, `actualizar`, `dibujar`, `tecla`). Se aplica en tres niveles
distintos:

- **Flujo del juego**: `gameplay` ↔ `pause` ↔ `victory`/`defeat`.
- **Jugador**: `idle` → `walk` → `attack` → `idle`/`walk`, con `dead` como
  interrupción desde cualquiera.
- **Enemigo**: `idle` → `chase` → `attack`, con `hurt` y `dead` como
  interrupciones desde cualquiera.

Los cambios de estado son reales y verificables en tiempo de ejecución
(por ejemplo, morir interrumpe cualquier estado del jugador y lleva a
`dead`; completar el nivel lleva de `gameplay` a `victory`; ESC alterna
entre `gameplay` y `pause`).

### Mapa de teselas y generación procedural

El nivel 1 es un mapa de teselas (Tiled + Simple Tiled Implementation),
con colisiones derivadas de una propiedad del tileset en vez de estar
hardcodeadas. El nivel 2 se genera proceduralmente en cada partida
(cantidad, tamaño y posición de las salas, pasillos, enemigos y
decoración), reutilizando el mismo formato y el mismo sistema de carga y
dibujado que el nivel 1.

### Cámara y ventana

La cámara sigue al jugador respetando los límites del nivel actual. La
ventana es redimensionable; el juego se escala de forma uniforme (sin
deformarse) y se centra dentro de la ventana real, sea cual sea su
tamaño o proporción.

### Pausa

La pausa está implementada como un estado más de la máquina de estados del
juego, no como una variable booleana aislada: mientras el estado de pausa
está activo, la lógica de la partida simplemente no se ejecuta.

### Interfaz de usuario y eventos personalizados

La vida se representa con corazones y la estamina con una barra de
segmentos, ambos actualizados mediante un sistema de eventos personalizado
(`src/systems/events.lua`) en vez de leer las variables del jugador en
cada cuadro. Los eventos del jugador (cambio de vida, cambio de estamina,
daño recibido, curación) y de progreso (sala completada) comunican entre
sí a la interfaz, el sistema de audio y la generación del corazón de
recompensa, sin que esos sistemas se conozcan directamente entre sí.
