function love.load()
    love.window.setMode(1000, 768)

    anim8 = require 'libraries/anim8/anim8'
    sti = require 'libraries/Simple-Tiled-Implementation/sti'
    cameraFile = require 'libraries/hump/camera'

    cam = cameraFile()

    sprites = {}
    sprites.playerSheet = love.graphics.newImage('sprites/playerSheet.png')
    sprites.enemySheet = love.graphics.newImage('sprites/enemySheet.png')

    local grid = anim8.newGrid(205, 203, sprites.playerSheet:getWidth(), sprites.playerSheet:getHeight())
    local enemyGrid = anim8.newGrid(492, 494, 492, 494)

    animations = {}
    animations.idle = anim8.newAnimation(grid('1-1', 1), 0.1)
    animations.run = anim8.newAnimation(grid('2-4', 1), 0.1)
    animations.jump = anim8.newAnimation(grid('5-5', 1), 0.1)
    animations.enemy = anim8.newAnimation(enemyGrid('1-1', 1), 0.1)

    wf = require 'libraries/windfield/windfield'
    world = wf.newWorld(0, 3000, false)
    world:setQueryDebugDrawing(true)

    world:addCollisionClass('Platform')
    world:addCollisionClass('Player')
    world:addCollisionClass('Danger')

    require('player')   
    require('enemy') 

    --dangerZone = world:newRectangleCollider(0, 550, 800, 50, {collision_class = 'Danger'})
    --dangerZone:setType('static')

    platforms = {}

    flagX = 0
    flagY = 0

    currentLevel = "level1"

    loadMap(currentLevel)
end


function love.update(dt)
    world:update(dt)
    gameMap:update(dt)
    playerUpdate(dt) 
    updateEnemies(dt)   

    local px, py = player:getPosition()
    cam:lookAt(px, love.graphics.getHeight()/2)

    -- query for letters and changing levels
    local colliders = world:queryRectangleArea(flagX, flagY, 200, 200, {'Player'})
    if #colliders > 0 then
        if currentLevel == 'level2' then
            loadMap('level1')
        elseif currentLevel == 'level1' then
            loadMap('level2')
        end
    end
end

function love.draw()
    cam:attach()
        gameMap:drawLayer(gameMap.layers["Tile Layer 1"])
        world:draw()
        drawPlayer()
        drawEnemies()
    cam:detach()
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

function spawnPlatform(x, y, width, height)
    if width > 0 and height > 0 then
        local platform = world:newRectangleCollider(x, y, width, height, {collision_class = 'Platform'})
        platform:setType('static')
        table.insert(platforms, platform)
    end
end

function destroyAll()
    local i = #platforms
    while i > -1 do
       if platforms[i] ~= nil then
            platforms[i]:destroy()
       end
       table.remove(platforms, i)
       i = i - 1
    end

    local i = #enemies
    while i > -1 do
       if enemies[i] ~= nil then
            enemies[i]:destroy()
       end
       table.remove(enemies, i)
       i = i - 1
    end
end


function loadMap(mapName)
    currentLevel = mapName
    destroyAll()
    player:setPosition(300, 100)
    gameMap = sti("maps/" .. mapName .. ".lua")
    for i, obj in pairs(gameMap.layers["Platforms"].objects) do
        spawnPlatform(obj.x, obj.y, obj.width, obj.height)
    end
    for i, obj in pairs(gameMap.layers["Enemies"].objects) do
        spawnEnemy(obj.x, obj.y)
    end
    for i, obj in pairs(gameMap.layers["Flag"].objects) do
        flagX = obj.x
        flagY = obj.y
    end
end

