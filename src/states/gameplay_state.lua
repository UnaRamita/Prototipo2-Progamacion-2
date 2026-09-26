-- Estado principal del juego: la partida en si. Es el unico estado que
-- mueve al jugador/enemigos, resuelve colisiones y decide cuando se pasa a
-- victoria, derrota o pausa. Se le pasa "game" (src/game.lua), que funciona
-- como el "mundo": entidades compartidas + helpers (buildSolids,
-- resolveCombat, etc.) que ya existian y siguen viviendo ahi porque son
-- datos del nivel, no de este estado puntual.
--
-- GameplayState.drawWorld(game) (el dibujado del mundo+HUD) es una funcion
-- de MODULO, no un metodo de la instancia: PauseState la reutiliza tal
-- cual para poder mostrar la escena "congelada" detras de su overlay, sin
-- duplicar ni un poco del dibujado (ver src/states/pause_state.lua).

local Assets = require("src.assets")
local Constants = require("src.constants")
local Dungeon = require("src.dungeon")
local Key = require("src.key")
local UI = require("src.ui")

local GameplayState = {}

-- Dibuja el mundo (mapa + entidades) y el HUD, con la camara/posiciones que
-- tengan en ESE momento game.camera/game.player/game.enemies/etc. No avanza
-- ninguna logica -- por eso sirve igual para el frame normal de gameplay y
-- para redibujar el frame "congelado" mientras el juego esta en pausa.
function GameplayState.drawWorld(game)
    -- w,h explicitos: sin esto, camera:attach() usa por defecto
    -- love.graphics.getWidth()/getHeight(), que ahora son el tamaño real de
    -- la ventana (puede redimensionarse, ver src/systems/viewport.lua) y no
    -- coinciden con la resolucion virtual fija a la que dibuja el juego.
    game.camera:attach(0, 0, Constants.WINDOW_WIDTH, Constants.WINDOW_HEIGHT)

    Dungeon.drawFloorAndWalls()
    Dungeon.drawCandles(game.door.openProgress)

    -- Jugador, enemigos, cofre y llave ordenados por Y para dar sensacion de profundidad
    local drawables = {}
    for _, e in ipairs(game.enemies) do drawables[#drawables + 1] = e end
    drawables[#drawables + 1] = game.player
    drawables[#drawables + 1] = game.chest
    if game.key then drawables[#drawables + 1] = game.key end
    table.sort(drawables, function(a, b) return a.y < b.y end)
    for _, d in ipairs(drawables) do d:draw() end

    game.door:draw()
    Dungeon.drawRoom2Darkness(1 - game.door.openProgress)

    -- Los carteles de interaccion son mundo, no pantalla: tienen que
    -- moverse con la camara, asi que se dibujan antes del detach().
    if game.door:shouldShowPrompt(game.player) then
        local d = Dungeon.doorRect
        UI.drawPrompt("Presiona F para abrir", d.x + d.w / 2, d.y + d.h / 2)
    elseif game.key and game.key:shouldShowPrompt(game.player) then
        UI.drawPrompt("Presiona F para recoger", game.key.x, game.key.y - 40)
    elseif game.chest:shouldShowPrompt(game.player) then
        UI.drawPrompt("Presiona F para abrir", game.chest.x, game.chest.y - 60)
    end

    game.camera:detach()

    UI.drawHUD(game.player, game.hasKey, game.machine.name, game.level)
    if game.message then
        UI.drawMessage(game.message.text)
    end
end

function GameplayState.new(game)
    local state = {}

    -- Carga el mapa del nivel (params.level; 1 si no se especifica) y arma
    -- las entidades sobre el, despues centra la camara en el jugador. Se
    -- llama al arrancar el juego, al pasar de nivel (cofre del nivel 1) y
    -- al reiniciar despues de ganar/perder (ver Victory/DefeatState) --
    -- este ultimo caso siempre vuelve a nivel 1 porque no se pasa "params".
    --
    -- params.resume = true: se vuelve de una pausa (ver PauseState). No hay
    -- que recargar el nivel ni reubicar nada -- el mundo entero vive en
    -- "game", no en esta instancia de estado, asi que simplemente seguir
    -- sin tocar nada alcanza para "continuar donde se dejo".
    function state:ingresar(params)
        if params and params.resume then return end

        local level = params and params.level or 1
        game.setupLevel(level)
        game.camera:lookAt(game.player.x, game.player.y)

        if level > 1 then
            game.showMessage("Nivel " .. level .. " -- mazmorra generada proceduralmente", 3.5)
        end
    end

    function state:actualizar(dt)
        -- Timers de gameplay (mensajes transitorios): si esto se actualizara
        -- fuera de este estado (como antes), seguirian corriendo durante la
        -- pausa. Aca se congelan solos, junto con todo lo demas de este metodo.
        game.timer:update(dt)

        game.door:update(dt)
        game.chest:update(dt)

        local solids = game.buildSolids()
        game.player:update(dt, solids)
        game.updateCamera()

        if game.player.machine:es("dead") then
            -- Condicion de derrota: se espera a que termine la animacion de muerte
            if game.player:isDeathAnimFinished() then
                game.machine:cambiar("defeat")
            end
            return
        end

        -- Los enemigos de la sala 2 (active = false) no ejecutan su IA hasta
        -- que se abre la puerta; los de la sala 1 siempre estuvieron activos.
        -- Los enemigos muertos siguen recibiendo update() (para terminar de
        -- reproducir su animacion de muerte y titilar) hasta que "removed".
        local doorOpen = game.door.state == "open"
        for _, enemy in ipairs(game.enemies) do
            if not enemy:isAlive() then
                if not enemy.removed then
                    enemy:update(dt, game.player, solids)
                end
            elseif enemy.active or doorOpen then
                enemy:update(dt, game.player, solids)
            end
        end

        game.resolveCombat()

        -- La llave solo aparece cuando TODOS los enemigos de ambas salas murieron.
        if not game.keySpawned and game.allEnemiesDead() then
            game.keySpawned = true
            game.key = Key.new(Dungeon.keySpawnPos.x, Dungeon.keySpawnPos.y, Assets.images.key, Constants.KEY_SCALE)
        end
    end

    function state:dibujar()
        GameplayState.drawWorld(game)
    end

    function state:tecla(key)
        if key == "space" then
            game.player:tryAttack()
        elseif key == "escape" then
            game.machine:cambiar("pause")
        elseif key == "f" then
            if game.door:interact(game.player) then
                -- puerta abierta: nada mas que hacer este frame
            elseif game.key and game.key:canInteract(game.player) then
                game.key:collect()
                game.hasKey = true
                game.showMessage("¡Llave obtenida!", 2.5)
            elseif game.chest:canInteract(game.player) then
                if game.chest:tryOpen(game.hasKey) then
                    if game.hasNextLevel() then
                        game.machine:cambiar("gameplay", { level = game.level + 1 })
                    else
                        game.machine:cambiar("victory")
                    end
                else
                    game.showMessage("Necesitas una llave", 2)
                end
            end
        end
    end

    return state
end

return GameplayState
