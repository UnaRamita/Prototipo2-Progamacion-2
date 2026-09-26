-- Cofre final de la mazmorra. Es el objeto que dispara la victoria, pero
-- solo se puede abrir si el jugador ya tiene la llave. Mismo esquema de
-- interaccion por distancia que la puerta y la llave.

local Chest = {}
Chest.__index = Chest

local INTERACT_DISTANCE = 80

function Chest.new(x, y, image, scale)
    local self = setmetatable({}, Chest)
    self.x, self.y = x, y
    self.image = image
    self.scale = scale
    self.opened = false
    return self
end

function Chest:distanceTo(px, py)
    local dx, dy = px - self.x, py - self.y
    return math.sqrt(dx * dx + dy * dy)
end

function Chest:canInteract(player)
    return not self.opened and self:distanceTo(player.x, player.y) <= INTERACT_DISTANCE
end

function Chest:shouldShowPrompt(player)
    return self:canInteract(player)
end

-- Intenta abrir el cofre. Devuelve true solo si estaba cerrado y el
-- jugador tiene la llave (en ese caso lo abre). false en cualquier otro
-- caso (para que el llamador pueda mostrar "Necesitas una llave").
function Chest:tryOpen(hasKey)
    if self.opened or not hasKey then return false end
    self.opened = true
    return true
end

function Chest:update()
end

function Chest:draw()
    local w, h = self.image:getWidth() * self.scale, self.image:getHeight() * self.scale

    -- No existe un sprite de "cofre abierto" en los assets: la solucion
    -- visual sencilla es un tinte dorado permanente una vez abierto.
    local r, g, b = 1, 1, 1
    if self.opened then r, g, b = 1, 0.85, 0.35 end

    love.graphics.setColor(r, g, b, 1)
    love.graphics.draw(self.image, self.x - w / 2, self.y - h, 0, self.scale, self.scale)
    love.graphics.setColor(1, 1, 1, 1)
end

return Chest
