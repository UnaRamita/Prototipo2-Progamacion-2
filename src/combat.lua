-- Utilidades de combate compartidas entre Player y Enemy: colisiones AABB
-- y calculo del hitbox rectangular de un ataque segun la direccion en la
-- que mira el atacante. Centralizarlo evita duplicar la misma logica.

local Combat = {}

-- a y b son rects {x, y, w, h} (x,y = esquina superior izquierda)
function Combat.aabbOverlap(a, b)
    return a.x < b.x + b.w and
           a.x + a.w > b.x and
           a.y < b.y + b.h and
           a.y + a.h > b.y
end

-- Devuelve el rect de colision de una entidad a partir de su posicion
-- (x, y = pies/centro inferior) y el tamaño de su collider.
function Combat.colliderRect(entity)
    return {
        x = entity.x - entity.colliderW / 2,
        y = entity.y - entity.colliderH,
        w = entity.colliderW,
        h = entity.colliderH,
    }
end

-- Calcula el rectangulo de ataque proyectado delante del atacante segun
-- su direccion ("up", "down", "left", "right").
function Combat.attackHitbox(entity, range, width)
    local cx, cy = entity.x, entity.y - entity.colliderH / 2

    if entity.facing == "up" then
        return { x = cx - width / 2, y = cy - range, w = width, h = range }
    elseif entity.facing == "down" then
        return { x = cx - width / 2, y = cy, w = width, h = range }
    elseif entity.facing == "left" then
        return { x = cx - range, y = cy - width / 2, w = range, h = width }
    else -- "right"
        return { x = cx, y = cy - width / 2, w = range, h = width }
    end
end

-- Mueve una entidad por (dx, dy) resolviendo colisiones contra una lista de
-- rects solidos, eje por eje (primero X, despues Y) para permitir que el
-- personaje "se deslice" al chocar contra una pared en diagonal.
-- La entidad necesita x, y (pies/centro inferior) y colliderW/colliderH.
function Combat.moveWithCollision(entity, dx, dy, solids)
    entity.x = entity.x + dx
    local r = Combat.colliderRect(entity)
    for _, wall in ipairs(solids) do
        if Combat.aabbOverlap(r, wall) then
            if dx > 0 then
                entity.x = wall.x - entity.colliderW / 2
            elseif dx < 0 then
                entity.x = wall.x + wall.w + entity.colliderW / 2
            end
            r = Combat.colliderRect(entity)
        end
    end

    entity.y = entity.y + dy
    r = Combat.colliderRect(entity)
    for _, wall in ipairs(solids) do
        if Combat.aabbOverlap(r, wall) then
            if dy > 0 then
                entity.y = wall.y
            elseif dy < 0 then
                entity.y = wall.y + wall.h + entity.colliderH
            end
            r = Combat.colliderRect(entity)
        end
    end
end

return Combat
