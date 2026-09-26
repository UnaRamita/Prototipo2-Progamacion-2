-- Puerta interactiva que separa las dos salas de la mazmorra.
-- Estados: "closed" (bloquea el paso) -> el jugador presiona F cerca ->
-- "open" (deja de bloquear y dispara la animacion de apertura + la
-- iluminacion progresiva de la sala 2).
--
-- doorRect puede venir en nil: el nivel 2 (procedural) es un solo espacio
-- conectado, sin puerta que lo separe en dos salas. En ese caso Door.new
-- arma una puerta "stub" ya abierta desde el arranque -- sin rect, sin
-- colision, sin dibujo -- para que Game/GameplayState puedan seguir
-- llamando door:update()/:draw()/:isBlocking() igual que con el nivel 1,
-- sin tener que preguntar "hay puerta?" en un monton de lugares distintos.

local Door = {}
Door.__index = Door

local INTERACT_DISTANCE = 90
local OPEN_ANIM_TIME = 1.2

-- image: sprite de la puerta (assets/dungeon/lateraldoors.png), se estira
-- para llenar exactamente doorRect, dibujada una sola vez (no repetida).
function Door.new(doorRect, image)
    local self = setmetatable({}, Door)
    self.rect = doorRect
    self.image = image

    if doorRect then
        self.scaleX = doorRect.w / image:getWidth()
        self.scaleY = doorRect.h / image:getHeight()
        self.state = "closed" -- "closed" | "open"
        self.openProgress = 0 -- 0..1, usado para el fade visual y la luz de la sala 2
    else
        self.state = "open"
        self.openProgress = 1
    end

    return self
end

function Door:update(dt)
    if not self.rect then return end
    if self.state == "open" and self.openProgress < 1 then
        self.openProgress = math.min(1, self.openProgress + dt / OPEN_ANIM_TIME)
    end
end

-- Distancia del jugador al rect de la puerta (0 si ya esta adentro/superpuesto)
function Door:distanceTo(px, py)
    local cx = math.max(self.rect.x, math.min(px, self.rect.x + self.rect.w))
    local cy = math.max(self.rect.y, math.min(py, self.rect.y + self.rect.h))
    local dx, dy = px - cx, py - cy
    return math.sqrt(dx * dx + dy * dy)
end

function Door:canInteract(player)
    return self.state == "closed" and self:distanceTo(player.x, player.y) <= INTERACT_DISTANCE
end

function Door:interact(player)
    if self:canInteract(player) then
        self.state = "open"
        return true
    end
    return false
end

function Door:isBlocking()
    return self.state == "closed"
end

function Door:getCollisionRect()
    return self.rect
end

function Door:draw()
    if self.state == "open" and self.openProgress >= 1 then return end

    -- La puerta se desliza hacia arriba (como si se metiera en el techo) y
    -- se desvanece a medida que se abre. El recorte de "lo que ya se metio
    -- en el techo" se hace con un Quad (una sub-region del sprite), no con
    -- setScissor: setScissor siempre usa coordenadas de PANTALLA, nunca las
    -- afecta la transformacion de camara, asi que un rect en coordenadas de
    -- MUNDO (self.rect) solo coincidia con la pantalla cuando la camara
    -- quedaba clavada justo en el punto donde mundo y pantalla coinciden
    -- 1:1. El Quad, en cambio, recorta la IMAGEN antes de dibujarla, asi
    -- que el resultado es correcto sin importar donde este la camara.
    local imgW, imgH = self.image:getWidth(), self.image:getHeight()
    local hiddenRows = self.openProgress * imgH -- lo que ya "desaparecio" arriba del marco
    local visibleH = imgH - hiddenRows
    if visibleH <= 0 then return end

    local quad = love.graphics.newQuad(0, hiddenRows, imgW, visibleH, imgW, imgH)
    love.graphics.setColor(1, 1, 1, 1 - self.openProgress)
    love.graphics.draw(self.image, quad, self.rect.x, self.rect.y, 0, self.scaleX, self.scaleY)
    love.graphics.setColor(1, 1, 1, 1)
end

function Door:shouldShowPrompt(player)
    return self:canInteract(player)
end

return Door
