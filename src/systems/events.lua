-- Bus de eventos personalizado, generico y reutilizable: la pieza que le
-- faltaba al proyecto para que el HUD, el audio y las recompensas puedan
-- reaccionar a lo que le pasa al jugador sin conocerlo directamente (sin
-- que el HUD le pregunte a Player "cual es tu vida" cuadro a cuadro, y sin
-- que Player necesite saber que existe un HUD).
--
-- API: Events:on(nombre, callback) -> handle (para poder desuscribirse)
--      Events:off(handle)
--      Events:emit(nombre, ...)    -- ... se pasa tal cual a cada callback
--
-- Es una unica instancia global (como Game, Dungeon o Assets, que ya son
-- singletons en este proyecto): todos los suscriptores de este TP (HUD,
-- AudioSystem, el spawn del corazon de recompensa) son modulos que se
-- cargan una sola vez con require() y viven toda la partida, asi que
-- suscribirse una vez al cargar el modulo alcanza y sobra -- no hace falta
-- des-suscribirse al cambiar de nivel porque nunca se vuelven a crear.
-- Player/Enemy, en cambio, SI se recrean en cada nivel (Game.setupEntities)
-- pero nunca se suscriben a nada, solo emiten -- asi que tampoco dejan
-- suscripciones colgadas cuando se descartan.

local EventBus = {}
EventBus.__index = EventBus

function EventBus.new()
    return setmetatable({ listeners = {} }, EventBus)
end

-- Devuelve un "handle" opaco que identifica esta suscripcion particular
-- (se necesita para poder sacarla despues con :off, ya que una misma
-- funcion podria suscribirse mas de una vez).
function EventBus:on(eventName, callback)
    self.listeners[eventName] = self.listeners[eventName] or {}
    local handle = { event = eventName, callback = callback }
    table.insert(self.listeners[eventName], handle)
    return handle
end

function EventBus:off(handle)
    if not handle then return end
    local list = self.listeners[handle.event]
    if not list then return end
    for i, h in ipairs(list) do
        if h == handle then
            table.remove(list, i)
            return
        end
    end
end

-- Copia la lista de listeners antes de recorrerla: si un callback se
-- suscribe/desuscribe a si mismo durante el emit (poco comun, pero
-- posible), evita modificar la tabla mientras se esta iterando.
function EventBus:emit(eventName, ...)
    local list = self.listeners[eventName]
    if not list then return end
    local snapshot = {}
    for i, h in ipairs(list) do snapshot[i] = h end
    for _, h in ipairs(snapshot) do
        h.callback(...)
    end
end

-- Instancia unica compartida por todo el juego.
local Events = EventBus.new()

-- Nombres de los eventos del TP, centralizados aca para que ningun modulo
-- tenga que escribir el string a mano (evita typos silenciosos: emitir
-- "PLAYER_HEALED" y suscribirse a "PLAYER_HEALD" no tira ningun error,
-- simplemente nunca se llama al callback).
Events.PLAYER_HEALTH_CHANGED = "PLAYER_HEALTH_CHANGED"   -- (hp, maxHp)
Events.PLAYER_STAMINA_CHANGED = "PLAYER_STAMINA_CHANGED" -- (stamina, maxStamina)
Events.PLAYER_DAMAGED = "PLAYER_DAMAGED"                 -- (amount)
Events.PLAYER_HEALED = "PLAYER_HEALED"                   -- (amount)
Events.ROOM_COMPLETED = "ROOM_COMPLETED"                 -- ()
Events.HEALTH_PICKUP_COLLECTED = "HEALTH_PICKUP_COLLECTED" -- ()

return Events
