-- Animacion generica basada en spritesheets de una sola fila.
-- Todos los sheets de soldier/blood monster son tiras horizontales de
-- frames cuadrados de 100x100, asi que un solo modulo alcanza para todos.

local Animation = {}
Animation.__index = Animation

-- image: love.Image | frameW, frameH: tamaño de cada frame
-- frameCount: cantidad de frames en la tira | frameTime: duracion de cada frame (seg)
-- loop: si al llegar al final vuelve a empezar (true) o se queda en el ultimo frame (false)
-- originY: fila (en pixeles del frame) que representa el "piso" visual del
-- sprite. Muchos spritesheets dejan relleno transparente debajo del
-- personaje, asi que anclar siempre en frameH (el borde de abajo del
-- frame) desalinea la posicion visual respecto de la hitbox. Si no se
-- pasa, se usa frameH (comportamiento anterior).
function Animation.new(image, frameW, frameH, frameCount, frameTime, loop, originY)
    local self = setmetatable({}, Animation)
    self.image = image
    self.frameW = frameW
    self.frameH = frameH
    self.frameCount = frameCount
    self.frameTime = frameTime
    self.loop = (loop == nil) and true or loop
    self.originY = originY or frameH

    self.quads = {}
    local imgW, imgH = image:getWidth(), image:getHeight()
    for i = 0, frameCount - 1 do
        self.quads[i + 1] = love.graphics.newQuad(i * frameW, 0, frameW, frameH, imgW, imgH)
    end

    self.frame = 1
    self.timer = 0
    self.finished = false

    return self
end

function Animation:reset()
    self.frame = 1
    self.timer = 0
    self.finished = false
end

function Animation:update(dt)
    if self.finished then return end

    self.timer = self.timer + dt
    while self.timer >= self.frameTime do
        self.timer = self.timer - self.frameTime
        self.frame = self.frame + 1
        if self.frame > self.frameCount then
            if self.loop then
                self.frame = 1
            else
                self.frame = self.frameCount
                self.finished = true
            end
        end
    end
end

function Animation:isFinished()
    return self.finished
end

-- Dibuja el frame actual anclado por su centro-inferior en (x, y), usando
-- originY (el "piso" visual real del sprite) en vez del borde del frame.
-- flipX invierte horizontalmente (para mirar a la izquierda).
function Animation:draw(x, y, flipX, scale, r, g, b, a)
    scale = scale or 1
    love.graphics.setColor(r or 1, g or 1, b or 1, a or 1)
    local sx = (flipX and -1 or 1) * scale
    local ox = self.frameW / 2
    love.graphics.draw(self.image, self.quads[self.frame], x, y, 0, sx, scale, ox, self.originY)
    love.graphics.setColor(1, 1, 1, 1)
end

return Animation
