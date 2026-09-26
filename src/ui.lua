-- Interfaz: barra de vida, cartel de interaccion con la puerta y las
-- pantallas de victoria/derrota.

local Constants = require("src.constants")

local UI = {}

local bigFont = love.graphics.newFont(48)
local medFont = love.graphics.newFont(22)
local smallFont = love.graphics.newFont(16)

function UI.drawHUD(player, hasKey, gameStateName, level)
    local x, y = 24, 20
    local w, h = 260, 26

    love.graphics.setFont(smallFont)

    -- fondo de la barra
    love.graphics.setColor(0.15, 0.05, 0.05, 0.9)
    love.graphics.rectangle("fill", x, y, w, h, 4, 4)

    -- vida actual
    local pct = math.max(0, player.hp / player.maxHp)
    local barColor = { 0.75, 0.15, 0.15 }
    if pct > 0.6 then barColor = { 0.2, 0.7, 0.25 }
    elseif pct > 0.3 then barColor = { 0.85, 0.65, 0.15 } end

    love.graphics.setColor(barColor[1], barColor[2], barColor[3], 1)
    love.graphics.rectangle("fill", x, y, w * pct, h, 4, 4)

    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.rectangle("line", x, y, w, h, 4, 4)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(
        string.format("HP: %d / %d", math.max(0, player.hp), player.maxHp),
        x, y + 4, w, "center"
    )

    -- estado actual de ambas maquinas de estado (juego + jugador), para que
    -- el cambio de estado sea visible en pantalla durante la defensa del TP
    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.print("Estado juego: " .. tostring(gameStateName), x, y + h + 6)
    love.graphics.print("Estado jugador: " .. player.machine.name, x, y + h + 26)
    if level then
        love.graphics.print("Nivel: " .. level .. (level > 1 and " (procedural)" or " (Tiled)"), x, y + h + 46)
    end

    if hasKey then
        love.graphics.setColor(1, 0.9, 0.4, 1)
        love.graphics.print("Llave: si", x, y + h + 66)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

-- Mensaje transitorio centrado (ej: "¡Llave obtenida!", "Necesitas una llave")
function UI.drawMessage(text)
    love.graphics.setFont(medFont)
    local w = 420
    local x = (Constants.WINDOW_WIDTH - w) / 2
    local y = 64

    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", x, y, w, 40, 6, 6)
    love.graphics.setColor(1, 0.9, 0.4, 1)
    love.graphics.printf(text, x, y + 9, w, "center")
    love.graphics.setColor(1, 1, 1, 1)
end

function UI.drawPrompt(text, worldX, worldY)
    love.graphics.setFont(medFont)
    local w = 260
    local x = worldX - w / 2
    local y = worldY

    love.graphics.setColor(0, 0, 0, 0.65)
    love.graphics.rectangle("fill", x, y - 30, w, 36, 6, 6)
    love.graphics.setColor(1, 0.9, 0.4, 1)
    love.graphics.printf(text, x, y - 24, w, "center")
    love.graphics.setColor(1, 1, 1, 1)
end

-- Overlay de pausa: mismo estilo simple que drawEndScreen (rect
-- semitransparente + titulo grande + instruccion chica), asi se ve
-- consistente con el resto de la interfaz sin agregar elementos nuevos.
function UI.drawPauseOverlay()
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, Constants.WINDOW_WIDTH, Constants.WINDOW_HEIGHT)

    love.graphics.setFont(bigFont)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("PAUSA", 0, Constants.WINDOW_HEIGHT / 2 - 70, Constants.WINDOW_WIDTH, "center")

    love.graphics.setFont(medFont)
    love.graphics.printf("Presiona ESC para continuar", 0, Constants.WINDOW_HEIGHT / 2 + 10, Constants.WINDOW_WIDTH, "center")

    love.graphics.setColor(1, 1, 1, 1)
end

function UI.drawEndScreen(kind)
    love.graphics.setColor(0, 0, 0, 0.65)
    love.graphics.rectangle("fill", 0, 0, Constants.WINDOW_WIDTH, Constants.WINDOW_HEIGHT)

    local title = kind == "victory" and "!VICTORIA!" or "DERROTA"
    local color = kind == "victory" and { 0.4, 1, 0.5 } or { 1, 0.3, 0.3 }

    love.graphics.setFont(bigFont)
    love.graphics.setColor(color[1], color[2], color[3], 1)
    love.graphics.printf(title, 0, Constants.WINDOW_HEIGHT / 2 - 70, Constants.WINDOW_WIDTH, "center")

    love.graphics.setFont(medFont)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Presiona R para reiniciar", 0, Constants.WINDOW_HEIGHT / 2 + 10, Constants.WINDOW_WIDTH, "center")

    love.graphics.setColor(1, 1, 1, 1)
end

return UI
