-- Estado de victoria: se entra cuando el jugador abre el cofre con la
-- llave (ver GameplayState:tecla). Al dejar de ser GameplayState el que se
-- actualiza/dibuja, el gameplay queda "congelado" automaticamente -- no
-- hace falta ninguna bandera de pausa, es la maquina la que decide que
-- corre y que no.

local UI = require("src.ui")

local VictoryState = {}

function VictoryState.new(game)
    local state = {}

    function state:dibujar()
        UI.drawEndScreen("victory")
    end

    function state:tecla(key)
        if key == "r" then
            game.machine:cambiar("gameplay")
        end
    end

    return state
end

return VictoryState
