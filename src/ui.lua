-- Interfaz: HUD de vida (corazones) y estamina (3 segmentos), cartel de
-- interaccion con la puerta y las pantallas de pausa/victoria/derrota.
--
-- Los corazones y la estamina NO leen player.hp/player.stamina en cada
-- frame: este modulo se suscribe una sola vez (al cargarse, mas abajo) a
-- los eventos PLAYER_HEALTH_CHANGED/PLAYER_STAMINA_CHANGED (ver
-- src/systems/events.lua) y guarda una copia local de solo-lectura para
-- dibujar. La unica fuente de verdad sigue siendo Player (self.hp/self.
-- stamina); esto es una CACHE para dibujar, no un segundo estado.

local Constants = require("src.constants")
local Assets = require("src.assets")
local Events = require("src.systems.events")

local UI = {}

local bigFont = love.graphics.newFont(48)
local medFont = love.graphics.newFont(22)
local smallFont = love.graphics.newFont(16)

-- Copia local para dibujar (ver comentario de arriba). Arranca en el
-- maximo; Player.new ya emite el valor real apenas se crea el jugador,
-- asi que esto solo importa en el primerisimo frame antes de esa emision.
local playerHealth, playerMaxHealth = Constants.PLAYER_MAX_HP, Constants.PLAYER_MAX_HP
local playerStamina, playerMaxStamina = Constants.PLAYER_MAX_STAMINA, Constants.PLAYER_MAX_STAMINA

Events:on(Events.PLAYER_HEALTH_CHANGED, function(hp, maxHp)
    playerHealth, playerMaxHealth = hp, maxHp
end)
Events:on(Events.PLAYER_STAMINA_CHANGED, function(stamina, maxStamina)
    playerStamina, playerMaxStamina = stamina, maxStamina
end)

-- fillAmount: 0..1, cuanto de ESTE corazon puntual esta lleno. Solo hay 3
-- sprites (lleno/medio/vacio, ver Assets/Hud): cualquier fraccion
-- intermedia se redondea a "medio", no se inventa un cuarto estado.
local function heartImage(fillAmount)
    if fillAmount >= 1 then return Assets.images.heartFull end
    if fillAmount > 0 then return Assets.images.heartHalf end
    return Assets.images.heartEmpty
end

local function drawHearts(x, y)
    local scale = Constants.HUD_HEART_SCALE
    local gap = 6
    -- maxHealth siempre son 3 corazones (ver Constants.HEART_PICKUP_HEAL):
    -- heartsTotal traduce la vida real (0..maxHp) a esa escala de 0..3.
    local heartsTotal = (playerMaxHealth > 0) and (playerHealth / playerMaxHealth * 3) or 0
    local heartW = Assets.images.heartFull:getWidth() * scale

    for i = 1, 3 do
        local fill = math.max(0, math.min(1, heartsTotal - (i - 1)))
        local img = heartImage(fill)
        love.graphics.draw(img, x + (i - 1) * (heartW + gap), y, 0, scale, scale)
    end

    return heartW * 3 + gap * 2 -- ancho total dibujado, para acomodar lo que sigue
end

local function drawStamina(x, y)
    local scale = Constants.HUD_STAMINA_SCALE
    local segments = {
        { full = Assets.images.staminaL, empty = Assets.images.staminaLEmpty },
        { full = Assets.images.staminaM, empty = Assets.images.staminaMEmpty },
        { full = Assets.images.staminaR, empty = Assets.images.staminaREmpty },
    }

    local drawX = x
    for i, seg in ipairs(segments) do
        local img = (i <= playerStamina) and seg.full or seg.empty
        love.graphics.draw(img, drawX, y, 0, scale, scale)
        drawX = drawX + img:getWidth() * scale -- sin gap: los 3 forman una sola barra (L+M+R)
    end
end

function UI.drawHUD(player, hasKey, gameStateName, level)
    local x, y = 24, 20

    love.graphics.setColor(1, 1, 1, 1)
    drawHearts(x, y)

    local staminaY = y + Assets.images.heartFull:getHeight() * Constants.HUD_HEART_SCALE + 10
    drawStamina(x, staminaY)

    -- estado actual de ambas maquinas de estado (juego + jugador), para que
    -- el cambio de estado sea visible en pantalla durante la defensa del TP
    love.graphics.setFont(smallFont)
    local labelsY = staminaY + Assets.images.staminaM:getHeight() * Constants.HUD_STAMINA_SCALE + 10
    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.print("Estado juego: " .. tostring(gameStateName), x, labelsY)
    love.graphics.print("Estado jugador: " .. player.machine.name, x, labelsY + 20)
    if level then
        love.graphics.print("Nivel: " .. level .. (level > 1 and " (procedural)" or " (Tiled)"), x, labelsY + 40)
    end

    if hasKey then
        love.graphics.setColor(1, 0.9, 0.4, 1)
        love.graphics.print("Llave: si", x, labelsY + 60)
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
