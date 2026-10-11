-- Personaje controlado por el jugador (Soldier). Su comportamiento esta
-- manejado por una maquina de estados real (src/systems/state_machine.lua)
-- con 4 estados: idle -> walk -> attack -> idle/walk, y dead como
-- interrupcion desde cualquiera de los anteriores (ver Player:takeDamage).
-- No hay estado "hurt" separado (el jugador no queda aturdido al recibir
-- daño, solo parpadea e invulnerable un rato), asi que agregarlo solo
-- sumaria complejidad sin cambiar el comportamiento real.

local Animation = require("src.animation")
local Combat = require("src.combat")
local Constants = require("src.constants")
local StateMachine = require("src.systems.state_machine")
local Timer = require("lib.hump.timer")
local Events = require("src.systems.events")

local Player = {}
Player.__index = Player

-- Lee el input de movimiento crudo (sin normalizar), -1/0/1 por eje.
local function readMovement()
    local dx, dy = 0, 0
    if love.keyboard.isDown("w", "up") then dy = dy - 1 end
    if love.keyboard.isDown("s", "down") then dy = dy + 1 end
    if love.keyboard.isDown("a", "left") then dx = dx - 1 end
    if love.keyboard.isDown("d", "right") then dx = dx + 1 end
    return dx, dy
end

-- ===== Estados del jugador =====
-- Cada fabrica cierra sobre "player" y devuelve una instancia con
-- ingresar/actualizar (ver StateMachine). El knockback y la invulnerabilidad
-- se resuelven de forma centralizada en Player:update, antes de delegar a
-- la maquina, porque aplican sin importar el estado actual (incluso
-- atacando se puede recibir un empujon).
local PlayerStates = {}

function PlayerStates.idle(player)
    return {
        ingresar = function()
            player.currentAnim = player.idleAnim
        end,
        actualizar = function()
            local dx, dy = readMovement()
            if dx ~= 0 or dy ~= 0 then
                player.machine:cambiar("walk")
            end
        end,
    }
end

function PlayerStates.walk(player)
    return {
        ingresar = function()
            player.currentAnim = player.walkAnim
        end,
        actualizar = function(_, dt)
            local dx, dy = readMovement()
            if dx == 0 and dy == 0 then
                player.machine:cambiar("idle")
                return
            end

            if dx ~= 0 and dy ~= 0 then
                dx, dy = dx * 0.7071, dy * 0.7071
            end
            if math.abs(dx) > math.abs(dy) then
                player.facing = dx > 0 and "right" or "left"
            else
                player.facing = dy > 0 and "down" or "up"
            end
            if dx ~= 0 then player.flipX = dx < 0 end

            Combat.moveWithCollision(player, dx * player.speed * dt, dy * player.speed * dt, player.solids)
            player.walkAnim:update(dt)
        end,
    }
end

function PlayerStates.attack(player)
    return {
        ingresar = function()
            player.attackTimer = 0
            player.attackHitActive = false
            player.attackHitEnemies = {}
            player.attackAnim:reset()
            player.currentAnim = player.attackAnim
        end,
        actualizar = function(_, dt)
            player.attackTimer = player.attackTimer + dt
            player.attackAnim:update(dt)

            local wasHitActive = player.attackHitActive
            player.attackHitActive = player.attackTimer >= Constants.PLAYER_ATTACK_HIT_START
                and player.attackTimer <= Constants.PLAYER_ATTACK_HIT_END

            -- El golpe "falla" en cuanto se cierra la ventana de daño, no
            -- cuando termina toda la animacion (sonaba desfasado del swing).
            if wasHitActive and not player.attackHitActive then
                player.attackWindowJustClosed = true
            end

            if player.attackAnim:isFinished() then
                local dx, dy = readMovement()
                if dx ~= 0 or dy ~= 0 then
                    player.machine:cambiar("walk")
                else
                    player.machine:cambiar("idle")
                end
            end
        end,
    }
end

function PlayerStates.dead(player)
    return {
        ingresar = function()
            player.attackHitActive = false
            player.deathAnim:reset()
            player.currentAnim = player.deathAnim
        end,
        actualizar = function(_, dt)
            player.deathAnim:update(dt)
        end,
    }
end

function Player.new(assets, x, y)
    local self = setmetatable({}, Player)
    local imgs = assets.images
    local footRow = assets.footRow

    self.x, self.y = x, y
    self.colliderW = Constants.PLAYER_COLLIDER_W
    self.colliderH = Constants.PLAYER_COLLIDER_H
    self.speed = Constants.PLAYER_SPEED
    self.scale = Constants.CHARACTER_SCALE

    self.maxHp = Constants.PLAYER_MAX_HP
    self.hp = self.maxHp

    self.maxStamina = Constants.PLAYER_MAX_STAMINA
    self.stamina = self.maxStamina
    self.staminaRegenElapsed = 0 -- segundos acumulados desde la ultima unidad recuperada
    self.healFlashTimer = 0 -- parpadeo breve al recuperar vida (ver Player:heal/Player:draw)

    self.facing = "down"   -- "up" | "down" | "left" | "right" (para el hitbox de ataque)
    self.flipX = false     -- solo se actualiza con movimiento horizontal (sprites miran a la derecha)

    self.walkAnim = Animation.new(imgs.soldierWalk, 100, 100, 8, 0.09, true, footRow.soldierWalk)
    self.idleAnim = Animation.new(imgs.soldierWalk, 100, 100, 1, 999, false, footRow.soldierWalk)
    self.attackAnim = Animation.new(imgs.soldierAttack, 100, 100, 6, 0.07, false, footRow.soldierAttack)
    self.deathAnim = Animation.new(imgs.soldierDeath, 100, 100, 4, 0.15, false, footRow.soldierDeath)
    self.currentAnim = self.idleAnim

    self.attackTimer = 0
    self.attackHitActive = false
    self.attackHitEnemies = {}  -- enemigos ya golpeados en el swing actual (evita golpear 2 veces al mismo)
    self.attackWindowJustClosed = false -- true un frame, cuando se cierra la ventana de golpe (para el sonido de fallo)

    self.invulnerable = false
    self.hurtFlashTimer = 0
    self.knockbackX, self.knockbackY = 0, 0
    self.knockbackTimer = 0
    self.solids = {} -- lista de rects solidos del frame actual (la setea Player:update)

    self.timer = Timer.new() -- usado para la ventana de invulnerabilidad al recibir daño

    self.machine = StateMachine.new({
        idle = function() return PlayerStates.idle(self) end,
        walk = function() return PlayerStates.walk(self) end,
        attack = function() return PlayerStates.attack(self) end,
        dead = function() return PlayerStates.dead(self) end,
    })
    self.machine:cambiar("idle")

    -- Estado inicial para quien escuche (el HUD): sin esto, los corazones/
    -- segmentos de estamina quedarian en blanco hasta el primer cambio.
    Events:emit(Events.PLAYER_HEALTH_CHANGED, self.hp, self.maxHp)
    Events:emit(Events.PLAYER_STAMINA_CHANGED, self.stamina, self.maxStamina)

    return self
end

function Player:tryAttack()
    if self.machine:es("dead") or self.machine:es("attack") then return end
    self:consumeStamina(Constants.STAMINA_COST_ATTACK)
    self.machine:cambiar("attack")
end

-- No bloquea el ataque si no hay estamina (ver nota en constants.lua):
-- simplemente no deja que baje de 0. El gasto es lo que dispara el evento
-- que actualiza los 3 segmentos del HUD.
function Player:consumeStamina(amount)
    local newStamina = math.max(0, self.stamina - amount)
    if newStamina == self.stamina then return end
    self.stamina = newStamina
    self.staminaRegenElapsed = 0
    Events:emit(Events.PLAYER_STAMINA_CHANGED, self.stamina, self.maxStamina)
end

-- Recupera vida sin superar el maximo (ver HeartPickup). Si el jugador ya
-- estaba al maximo, "applied" da 0: igual se deja recoger el objeto (no se
-- bloquea la recoleccion), pero no se emite PLAYER_HEALED ni se reproduce
-- sonido/parpadeo de curacion, porque en los hechos no se curo nada.
function Player:heal(amount)
    local before = self.hp
    self.hp = math.min(self.maxHp, self.hp + amount)
    local applied = self.hp - before

    Events:emit(Events.PLAYER_HEALTH_CHANGED, self.hp, self.maxHp)
    if applied > 0 then
        self.healFlashTimer = 0.5
        Events:emit(Events.PLAYER_HEALED, applied)
    end

    return applied
end

function Player:isAttackHitActive()
    return self.machine:es("attack") and self.attackHitActive
end

function Player:getAttackHitbox()
    return Combat.attackHitbox(self, Constants.PLAYER_ATTACK_RANGE, Constants.PLAYER_ATTACK_WIDTH)
end

function Player:hasHit(enemy)
    return self.attackHitEnemies[enemy] == true
end

function Player:registerHit(enemy)
    self.attackHitEnemies[enemy] = true
end

function Player:didLandAnyHit()
    return next(self.attackHitEnemies) ~= nil
end

function Player:isDeathAnimFinished()
    return self.deathAnim:isFinished()
end

-- fromX/fromY: posicion del atacante, usada para el pequeño knockback.
function Player:takeDamage(amount, fromX, fromY)
    if self.machine:es("dead") or self.invulnerable then return end

    local before = self.hp
    self.hp = math.max(0, self.hp - amount)
    local applied = before - self.hp
    self.hurtFlashTimer = 0.5

    Events:emit(Events.PLAYER_HEALTH_CHANGED, self.hp, self.maxHp)
    if applied > 0 then
        Events:emit(Events.PLAYER_DAMAGED, applied)
    end

    self.invulnerable = true
    self.timer:after(Constants.PLAYER_HURT_INVULN_TIME, function()
        self.invulnerable = false
    end)

    if fromX and fromY then
        local dx, dy = self.x - fromX, self.y - fromY
        local len = math.sqrt(dx * dx + dy * dy)
        if len > 0.001 then
            self.knockbackX = (dx / len) * 140
            self.knockbackY = (dy / len) * 140
            self.knockbackTimer = 0.15
        end
    end

    if self.hp <= 0 then
        self.machine:cambiar("dead")
    end
end

function Player:update(dt, solids)
    self.solids = solids
    self.attackWindowJustClosed = false

    self.timer:update(dt)
    if self.hurtFlashTimer > 0 then self.hurtFlashTimer = self.hurtFlashTimer - dt end
    if self.healFlashTimer > 0 then self.healFlashTimer = self.healFlashTimer - dt end

    -- Regeneracion pasiva de estamina: una unidad cada STAMINA_REGEN_INTERVAL
    -- segundos sin gastar (consumeStamina reinicia este contador). No regenera
    -- muerto, por prolijidad (el combate ya no importa en ese momento).
    if self.stamina < self.maxStamina and not self.machine:es("dead") then
        self.staminaRegenElapsed = self.staminaRegenElapsed + dt
        if self.staminaRegenElapsed >= Constants.STAMINA_REGEN_INTERVAL then
            self.staminaRegenElapsed = self.staminaRegenElapsed - Constants.STAMINA_REGEN_INTERVAL
            self.stamina = math.min(self.maxStamina, self.stamina + 1)
            Events:emit(Events.PLAYER_STAMINA_CHANGED, self.stamina, self.maxStamina)
        end
    end

    -- El empujon al recibir daño se resuelve aca, no en cada estado, porque
    -- aplica sin importar que este haciendo el jugador (salvo ya estar muerto).
    if self.knockbackTimer > 0 and not self.machine:es("dead") then
        self.knockbackTimer = self.knockbackTimer - dt
        Combat.moveWithCollision(self, self.knockbackX * dt, self.knockbackY * dt, solids)
    end

    self.machine:actualizar(dt)
end

function Player:draw()
    local r, g, b = 1, 1, 1
    -- parpadeo rojo mientras esta invulnerable/lastimado; parpadeo
    -- verdoso breve al recuperar vida (respuesta visual de PLAYER_HEALED,
    -- ver Player:heal). El de daño tiene prioridad si coincidieran.
    if self.hurtFlashTimer > 0 and math.floor(self.hurtFlashTimer * 14) % 2 == 0 then
        r, g, b = 1, 0.35, 0.35
    elseif self.healFlashTimer > 0 and math.floor(self.healFlashTimer * 14) % 2 == 0 then
        r, g, b = 0.5, 1.6, 0.6
    end
    self.currentAnim:draw(self.x, self.y, self.flipX, self.scale, r, g, b, 1)
end

return Player
