function love.load()
    anim8 = require 'libraries/anim8/anim8'

    sprites = {}
    sprites.playerSheet = love.graphics.newImage('sprites/playerSheet.png')

    local grid = anim8.newGrid(205, 203, sprites.playerSheet:getWidth(), sprites.playerSheet:getHeight())

    animations = {}
    animations.idle = anim8.newAnimation(grid('1-1', 1), 0.1)
    animations.run = anim8.newAnimation(grid('2-4', 1), 0.1)
    animations.jump = anim8.newAnimation(grid('5-5', 1), 0.1)

    wf = require 'libraries/windfield/windfield'
    world = wf.newWorld(0, 3000, false)
    world:setQueryDebugDrawing(true)

    world:addCollisionClass('Platform')
    world:addCollisionClass('Player')
    world:addCollisionClass('Danger')

    require('player')    
    
    platform = world:newRectangleCollider(250, 400, 300, 100, {collision_class = 'Platform'})
    platform:setType('static')

    dangerZone = world:newRectangleCollider(0, 550, 800, 50, {collision_class = 'Danger'})
    dangerZone:setType('static')
end

function love.update(dt)
    world:update(dt)
    playerUpdate(dt)
end

function love.draw()
    world:draw()
    drawPlayer()
end

function love.keypressed(key)
    if key == 'up' then
        if player.grounded == true then
            player:applyLinearImpulse(0, -20000)
            player.animation = animations.jump
        end
    end
end

function love.mousepressed(x, y, button)
    if button == 1 then
        local colliders = world:queryCircleArea(x, y, 200, {'Platform', 'Danger'})
        if #colliders > 0 then
            for i,c in ipairs(colliders) do
                c:destroy()
            end
        end
    end
end