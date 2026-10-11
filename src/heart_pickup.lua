-- Corazon de recuperacion: aparece junto a la salida (el cofre) cuando se
-- completa una sala (ver Events.ROOM_COMPLETED, src/systems/events.lua y
-- la suscripcion en src/game.lua). Mismo esquema de interaccion por
-- distancia que la puerta/llave/cofre (tecla F), y el mismo flotado visual
-- que ya usa Key (src/key.lua) -- este modulo esta calcado de ese.

local Constants = require("src.constants")
local Events = require("src.systems.events")

local HeartPickup = {}
HeartPickup.__index = HeartPickup

local INTERACT_DISTANCE = 70

function HeartPickup.new(x, y, image, scale)
    local self = setmetatable({}, HeartPickup)
    self.x, self.y = x, y
    self.image = image
    self.scale = scale
    self.collected = false
    self.spawnTime = love.timer.getTime() -- referencia para el flotado
    return self
end

function HeartPickup:distanceTo(px, py)
    local dx, dy = px - self.x, py - self.y
    return math.sqrt(dx * dx + dy * dy)
end

function HeartPickup:canInteract(player)
    return not self.collected and self:distanceTo(player.x, player.y) <= INTERACT_DISTANCE
end

function HeartPickup:shouldShowPrompt(player)
    return self:canInteract(player)
end

-- Le pide a Player que se cure (la unica fuente de verdad de la vida sigue
-- siendo Player.hp; este objeto no toca esa variable directamente). Se
-- deja recoger aunque el jugador ya este al maximo -- Player:heal ya
-- clampea sola y simplemente no emite PLAYER_HEALED si no curo nada (ver
-- comentario en Player:heal) -- asi el corazon nunca queda pegado ahi para
-- siempre esperando que el jugador este lastimado.
-- Devuelve cuanta vida se recupero realmente (0 si el jugador ya estaba al
-- maximo), para que quien llama pueda elegir el mensaje/feedback acorde.
function HeartPickup:collect(player)
    if self.collected then return 0 end
    self.collected = true
    local applied = player:heal(Constants.HEART_PICKUP_HEAL)
    Events:emit(Events.HEALTH_PICKUP_COLLECTED)
    return applied
end

local function floatOffset(spawnTime)
    return math.sin((love.timer.getTime() - spawnTime) * 1.6) * 4
end

function HeartPickup:draw()
    if self.collected then return end

    local offsetY = floatOffset(self.spawnTime)
    local w, h = self.image:getWidth() * self.scale, self.image:getHeight() * self.scale

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.image, self.x - w / 2, self.y - h + offsetY, 0, self.scale, self.scale)
end

return HeartPickup
