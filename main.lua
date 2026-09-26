-- Punto de entrada de LOVE2D.
-- Toda la logica del juego vive en src/game.lua; este archivo conecta los
-- callbacks de LOVE con el modulo Game, y con Viewport (src/systems/viewport.lua)
-- para que el juego se vea bien sea cual sea el tamaño de la ventana.

local Game = require("src.game")
local Viewport = require("src.systems.viewport")
local Constants = require("src.constants")

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest") -- mantiene el pixel art nitido al escalar
    math.randomseed(os.time())
    love.math.setRandomSeed(os.time()) -- usado por la generacion procedural del nivel 2 (src/procedural_dungeon.lua)
    Viewport.load()
    Game.load()
end

function love.update(dt)
    -- clamp de dt para evitar saltos grandes si la ventana pierde foco
    if dt > 0.05 then dt = 0.05 end
    Game.update(dt)
end

-- Todo el juego se dibuja a una resolucion logica fija dentro del canvas de
-- Viewport, y ese canvas se estira/centra en la ventana real al final (ver
-- src/systems/viewport.lua). Game.draw() no sabe nada de esto.
function love.draw()
    Viewport.beginFrame(Constants.BACKGROUND_COLOR)
    Game.draw()
    Viewport.endFrame(Constants.BACKGROUND_COLOR)
end

-- La ventana ahora es redimensionable (ver conf.lua): cuando cambia de
-- tamaño, Viewport recalcula su escala/centrado. El mundo/camara del juego
-- ni se enteran -- siguen dibujando a la misma resolucion logica de siempre.
function love.resize(w, h)
    Viewport.resize(w, h)
end

-- isrepeat: LOVE reenvia el auto-repeat del SO como love.keypressed
-- adicionales mientras una tecla queda apretada. Sin filtrarlo, mantener
-- ESC apretado alternaria Gameplay/Pause en cada repeticion. Se ignora
-- aca, una sola vez, para todas las teclas (ESC, espacio, F, R).
function love.keypressed(key, scancode, isrepeat)
    if isrepeat then return end
    Game.keypressed(key)
end
