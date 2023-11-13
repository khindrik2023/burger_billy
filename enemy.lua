enemies = {}

function spawnEnemy(x,y)
    local enemy = world:newRectangleCollider(x, y, 70, 70, {collision_class = "Danger"})
    enemy.direction = 1
    enemy.speed = 200
    enemy.animation = animations.enemy
    table.insert(enemies, enemy)
end

function updateEnemies(dt)
    for i,e in ipairs(enemies) do
        e.animation:update(dt)
        local ex, ey = e:getPosition()

        local colliders = world:queryRectangleArea(ex + (40 * e.direction), ey + 30, 20, 20, {'Platform'})
        if #colliders == 0 then
            e.direction = e.direction * -1
        end

        e:setX(ex + e.speed * dt * e.direction)
    end
end

function drawEnemies()
    for i,e in ipairs(enemies) do
        local ex, ey = e:getPosition()
        e.animation:draw(sprites.enemySheet, ex, ey, nil, .15, nil, 250, 250)
    end
end


