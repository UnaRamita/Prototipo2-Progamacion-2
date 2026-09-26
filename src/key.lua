-- Llave que aparece en el mapa recien cuando todos los enemigos del nivel
-- (sala 1 + sala 2) fueron derrotados. El jugador la recoge con F, con el
-- mismo esquema de interaccion por distancia que ya usa la puerta.

local Key = {}
Key.__index = Key

local INTERACT_DISTANCE = 70

function Key.new(x, y, image, scale)
    local self = setmetatable({}, Key)
    self.x, self.y = x, y
    self.image = image
    self.scale = scale
    self.collected = false
    self.spawnTime = love.timer.getTime() -- referencia para el flotado
    return self
end

function Key:distanceTo(px, py)
    local dx, dy = px - self.x, py - self.y
    return math.sqrt(dx * dx + dy * dy)
end

function Key:canInteract(player)
    return not self.collected and self:distanceTo(player.x, player.y) <= INTERACT_DISTANCE
end

function Key:shouldShowPrompt(player)
    return self:canInteract(player)
end

function Key:collect()
    self.collected = true
end

-- offsetY: desplazamiento vertical puramente visual (flotado). Se suma solo
-- al dibujar; self.x / self.y (usados por distanceTo/canInteract) nunca se
-- tocan, asi que la animacion no afecta la interaccion ni la colision.
local function floatOffset(spawnTime)
    return math.sin((love.timer.getTime() - spawnTime) * 1.6) * 4
end

function Key:draw()
    if self.collected then return end

    local offsetY = floatOffset(self.spawnTime)
    local w, h = self.image:getWidth() * self.scale, self.image:getHeight() * self.scale

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.image, self.x - w / 2, self.y - h + offsetY, 0, self.scale, self.scale)
end

return Key
