-- Estado de pausa: se entra con ESC desde Gameplay (ver
-- GameplayState:tecla) y se sale con ESC de vuelta (ver tecla() aca abajo).
--
-- No hay ningun "paused = true" en ningun lado. Lo que congela el juego es
-- simplemente que, mientras la maquina de estados del juego (Game.machine)
-- tiene a este estado como actual, GameplayState:actualizar() no se llama
-- NUNCA -- ni el jugador ni los enemigos se mueven, no hay ataques/daño, y
-- Game.timer (mensajes transitorios) tampoco avanza, porque ese update
-- vive adentro de GameplayState:actualizar(). Es el mismo mecanismo que ya
-- usan Victory/DefeatState para "congelar" el gameplay al ganar/perder.
--
-- Lo unico que hace falta para que "la escena se siga viendo" es volver a
-- dibujar el mundo con lo que tenga guardado en ese momento (posiciones,
-- camara, HUD): GameplayState.drawWorld(game) es exactamente esa funcion,
-- reutilizada tal cual (no se duplica nada del dibujado).

local GameplayState = require("src.states.gameplay_state")
local UI = require("src.ui")

local PauseState = {}

function PauseState.new(game)
    local state = {}

    function state:dibujar()
        GameplayState.drawWorld(game) -- el juego, congelado en su ultima posicion
        UI.drawPauseOverlay()          -- overlay de pausa, encima, sin escalarse con el mundo
    end

    function state:tecla(key)
        if key == "escape" then
            -- resume = true: GameplayState:ingresar no debe recargar el
            -- nivel ni reubicar al jugador, solo "seguir como estaba".
            game.machine:cambiar("gameplay", { resume = true })
        end
    end

    return state
end

return PauseState
