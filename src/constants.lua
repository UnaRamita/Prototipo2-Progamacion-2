-- Valores de ajuste centralizados. Tenerlos en un solo lugar facilita
-- explicar y tunear el balance del juego durante la defensa del TP.

local Constants = {}

-- Resolucion logica ("virtual") a la que se dibuja todo el juego (mundo +
-- UI): la ventana real de LOVE puede redimensionarse (ver
-- src/systems/viewport.lua), pero el juego siempre calcula/dibuja como si
-- midiera esto, y despues se escala+centra dentro de la ventana real.
Constants.WINDOW_WIDTH = 1280
Constants.WINDOW_HEIGHT = 720

Constants.BACKGROUND_COLOR = { 0.05, 0.05, 0.07 } -- usado para limpiar tanto el canvas como las franjas del letterbox

Constants.DUNGEON_SCALE = 3   -- escala de los graficos de assets/dungeon (son muy chicos)
Constants.CHARACTER_SCALE = 1.6 -- escala de los sprites de soldier/blood monster (100x100 por frame)
Constants.CHEST_SCALE = Constants.DUNGEON_SCALE -- mismo tamaño visual que el resto del tileset
Constants.KEY_SCALE = 2.6     -- objeto chico para recoger; similar proporcion al resto de props de la dungeon

-- ===== Jugador (Soldier) =====
Constants.PLAYER_SPEED = 210
Constants.PLAYER_MAX_HP = 100
Constants.PLAYER_COLLIDER_W = 28
Constants.PLAYER_COLLIDER_H = 22

Constants.PLAYER_ATTACK_DAMAGE = 20
Constants.PLAYER_ATTACK_RANGE = 50   -- distancia hacia adelante del hitbox de ataque
Constants.PLAYER_ATTACK_WIDTH = 46   -- ancho del hitbox de ataque
Constants.PLAYER_ATTACK_HIT_START = 0.16 -- segundos desde que arranca el swing hasta que el hitbox se activa
Constants.PLAYER_ATTACK_HIT_END = 0.30
Constants.PLAYER_HURT_INVULN_TIME = 0.7

-- ===== Enemigo (Blood Monster) =====
Constants.ENEMY_MAX_HP = 45
Constants.ENEMY_SPEED = 85
Constants.ENEMY_COLLIDER_W = 26
Constants.ENEMY_COLLIDER_H = 20

Constants.ENEMY_DETECT_RANGE = 230
Constants.ENEMY_ATTACK_RANGE = 46
Constants.ENEMY_ATTACK_WIDTH = 44
Constants.ENEMY_ATTACK_DAMAGE = 10
Constants.ENEMY_ATTACK_COOLDOWN = 1.1     -- tiempo minimo entre ataques
Constants.ENEMY_ATTACK_HIT_START = 0.28   -- ventana de daño dentro de la animacion de ataque
Constants.ENEMY_ATTACK_HIT_END = 0.42
Constants.ENEMY_HURT_TIME = 0.25
Constants.ENEMY_FLICKER_TIME = 0.5 -- titileo corto despues de terminar la animacion de muerte, antes de desaparecer
Constants.ENEMY_LOSE_INTEREST_RANGE = 340 -- si el jugador se aleja demasiado, vuelve a IDLE

return Constants
