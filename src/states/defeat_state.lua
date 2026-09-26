-- Estado de derrota: se entra cuando el jugador llega a 0 HP y termina de
-- reproducir su animacion de muerte (ver GameplayState:actualizar). Misma
-- idea que VictoryState: dejar de actualizar/dibujar el gameplay alcanza
-- para "congelarlo", sin banderas extra.

local UI = require("src.ui")

local DefeatState = {}

function DefeatState.new(game)
    local state = {}

    function state:dibujar()
        UI.drawEndScreen("defeat")
    end

    function state:tecla(key)
        if key == "r" then
            game.machine:cambiar("gameplay")
        end
    end

    return state
end

return DefeatState
