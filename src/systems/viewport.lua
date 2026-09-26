-- Escalado + centrado del juego dentro de la ventana real de LOVE.
--
-- El juego entero (mundo, camara, UI, pausa) se dibuja siempre a una
-- resolucion LOGICA fija (Constants.WINDOW_WIDTH x WINDOW_HEIGHT): nada de
-- eso sabe ni le importa que la ventana ahora pueda redimensionarse. Este
-- modulo es la UNICA pieza que conoce el tamaño real de la ventana: dibuja
-- todo a un canvas de esa resolucion fija y despues estira ese canvas hacia
-- la ventana real con una escala UNIFORME (misma en X e Y, para no
-- deformar nada) y centrado, dejando franjas del color de fondo del juego
-- a los costados (o arriba/abajo) en vez de barras negras.
--
-- Nada de esto toca coordenadas de mundo, colisiones o posiciones de
-- entidades -- esas siguen existiendo solo en el sistema de coordenadas de
-- siempre. Esto es pura representacion en pantalla.

local Constants = require("src.constants")

local Viewport = {}

local VIRTUAL_W, VIRTUAL_H = Constants.WINDOW_WIDTH, Constants.WINDOW_HEIGHT

local canvas = nil
local scale, offsetX, offsetY = 1, 0, 0

local function recompute()
    local winW, winH = love.graphics.getDimensions()

    -- Escala UNICA (no scaleX/scaleY distintos): asi el nivel crece o achica
    -- proporcionalmente pero nunca se ve estirado/aplastado.
    scale = math.min(winW / VIRTUAL_W, winH / VIRTUAL_H)

    offsetX = (winW - VIRTUAL_W * scale) / 2
    offsetY = (winH - VIRTUAL_H * scale) / 2
end

function Viewport.load()
    canvas = love.graphics.newCanvas(VIRTUAL_W, VIRTUAL_H)
    canvas:setFilter("nearest", "nearest") -- mantiene el pixel art nitido al escalar el canvas entero
    recompute()
end

-- Lo llama love.resize (ver main.lua) cuando el usuario cambia el tamaño
-- de la ventana. Recalcula la escala/offset para la nueva ventana.
function Viewport.resize(_, _)
    recompute()
end

-- A partir de aca (beginFrame) y hasta endFrame, todo lo que se dibuje va
-- al canvas virtual, no a la ventana real.
function Viewport.beginFrame(color)
    love.graphics.setCanvas(canvas)
    love.graphics.clear(color[1], color[2], color[3], 1)
end

-- Cierra el canvas virtual y lo dibuja en la ventana real, escalado y
-- centrado. Limpia la ventana real primero con el mismo color de fondo del
-- juego, asi las franjas del letterbox/pillarbox no quedan negras.
function Viewport.endFrame(color)
    love.graphics.setCanvas()
    love.graphics.clear(color[1], color[2], color[3], 1)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(canvas, offsetX, offsetY, 0, scale, scale)
end

return Viewport
