-- Maquina de estados generica y reutilizable (ver el patron State de
-- gameprogrammingpatterns.com/state.html). Se usa tanto para el flujo
-- general del juego (gameplay/victoria/derrota) como para el comportamiento
-- de las entidades (jugador, enemigos): en ambos casos el problema es el
-- mismo -- "que codigo corre ahora y que pasa al cambiar" -- asi que
-- alcanza con una sola implementacion.
--
-- Los estados se registran como funciones fabrica (sin argumentos desde el
-- punto de vista de la maquina): al cambiar de estado se descarta la
-- instancia anterior (llamando a su salir()) y se crea una instancia nueva
-- llamando a la fabrica, para asegurarse de que cada vez que se entra a un
-- estado arranca con datos limpios (temporizadores, flags, etc.).

local StateMachine = {}
StateMachine.__index = StateMachine

local function noop() end
local BASE_STATE = { ingresar = noop, salir = noop, actualizar = noop, dibujar = noop, tecla = noop }

-- stateFactories: tabla { nombre = function() -> instancia de estado }
-- Cada instancia de estado es una tabla con los metodos ingresar/salir/
-- actualizar/dibujar/tecla; no hace falta implementarlos todos (los que
-- falten se resuelven con BASE_STATE, que no hacen nada).
function StateMachine.new(stateFactories)
    local self = setmetatable({}, StateMachine)
    self.stateFactories = stateFactories or {}
    self.name = nil
    self.current = BASE_STATE
    return self
end

-- Registra o reemplaza la fabrica de un estado (util si algun modulo
-- quiere sumar estados despues de crear la maquina).
function StateMachine:registrar(nombre, factory)
    self.stateFactories[nombre] = factory
end

function StateMachine:cambiar(nombreEstado, parametros)
    local factory = self.stateFactories[nombreEstado]
    assert(factory, "Estado desconocido: " .. tostring(nombreEstado))

    self.current:salir()
    self.name = nombreEstado
    self.current = setmetatable(factory(), { __index = BASE_STATE })
    self.current:ingresar(parametros)
end

function StateMachine:es(nombreEstado)
    return self.name == nombreEstado
end

function StateMachine:actualizar(dt)
    self.current:actualizar(dt)
end

function StateMachine:dibujar()
    self.current:dibujar()
end

function StateMachine:tecla(key)
    self.current:tecla(key)
end

return StateMachine
