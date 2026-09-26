function love.conf(t)
    t.identity = "dungeon_soldier_tp"
    t.version = "11.4"
    t.console = false

    t.window.title = "Dungeon Soldier - Trabajo Practico"
    t.window.width = 1280
    t.window.height = 720
    t.window.resizable = true
    t.window.minwidth = 320  -- solo para evitar una ventana degenerada; el juego escala a cualquier tamaño (ver src/systems/viewport.lua)
    t.window.minheight = 240
    t.window.vsync = 1

    t.modules.joystick = false
    t.modules.physics = false
    t.modules.video = false
end
