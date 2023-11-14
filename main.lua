-----------------------------------------------------------------
-- LOVE.LOAD() --------------------------------------------------

function love.load()
    love.window.setMode(1000, 768)

    anim8 = require 'libraries/anim8/anim8'
    sti = require 'libraries/Simple-Tiled-Implementation/sti'
    cameraFile = require 'libraries/hump/camera'

    cam = cameraFile()

    -- music and sfx
    sounds = {}
    sounds.jump = love.audio.newSource("audio/Alberto Sueri - 8 Bit Fun - Classic Jump Glide Up Bleep.wav", 'static')
    sounds.jump:setVolume(.5)
    sounds.warp = love.audio.newSource("audio/Sound Response - 8 Bit Retro - Power up Trophy .wav", 'static')
    sounds.music = love.audio.newSource("audio/Kashido - Swan Lake Theme.wav", 'stream')
    sounds.die = love.audio.newSource("audio/Sound Response - 8 Bit Retro - Arcade Blip.wav", 'static')
    sounds.music:setLooping(true)
    sounds.music:setVolume(0.5)
    sounds.music:play()

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

    -- these tracks the location of warpzone objects
    warpX_forward = 0
    warpY_forward = 0
    warpX_back = 0
    warpX_back = 0

    -- keeps track of levels and load initial level
    -- "currentLevel" is updated in love.update()
    currentLevel = 1
    loadMap(currentLevel)
end

-----------------------------------------------------------
-- LOVE.UPDATE() ------------------------------------------

function love.update(dt)
    world:update(dt)
    gameMap:update(dt)
    playerUpdate(dt) 
    updateEnemies(dt)   

    local px, py = player:getPosition()
    cam:lookAt(px, love.graphics.getHeight()/2)

    -- query used for warpzones that advance to next level 
    -- see "warpForward" in loadMap()
    local colliders = world:queryRectangleArea(warpX_forward, warpY_forward, 200, 200, {'Player'})
    if #colliders > 0 then
        currentLevel = currentLevel + 1
        loadMap(currentLevel)
        sounds.warp:play()

    end

    -- query used for warpzones that go back to previous level 
    -- see "warpBack" in loadMap()
    local colliders = world:queryRectangleArea(warpX_back, warpY_back, 200, 200, {'Player'})
    if #colliders > 0 then
        currentLevel = currentLevel - 1
        loadMap(currentLevel)
    end
end

---------------------------------------------------------------
-- LOVE.DRAW() ------------------------------------------------

function love.draw()
    cam:attach()
        gameMap:drawLayer(gameMap.layers["Tile Layer 1"])
        --world:draw()
        drawPlayer()
        drawEnemies()
    cam:detach()
end

function love.keypressed(key)
    if key == 'up' then
        if player.grounded == true then
            player:applyLinearImpulse(0, -20000)
            player.animation = animations.jump
            sounds.jump:play()
        end
    end
end

--[[
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
]]

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

---------------------------------------------------------
-- LOADMAP ----------------------------------------------
-- this function spawns the graphics for 
-- the "Platforms", "Enemies", and "warpForward" objects.
-- the value for "mapName" is determined from a query
-- in love.update()

function loadMap(currentLevel)
    mapName = "level" .. currentLevel
    destroyAll()
    player:setPosition(300, 100)
    gameMap = sti("maps/" .. mapName .. ".lua")

    warpX_forward = 0
    warpY_forward = 0
    warpX_back = 0
    warpY_back = 0

    for i, obj in pairs(gameMap.layers["Platforms"].objects) do
        spawnPlatform(obj.x, obj.y, obj.width, obj.height)
    end
    for i, obj in pairs(gameMap.layers["Enemies"].objects) do
        spawnEnemy(obj.x, obj.y)
    end
    for i, obj in pairs(gameMap.layers["warpForward"].objects) do
        warpX_forward = obj.x
        warpY_forward = obj.y
    end
    for i, obj in pairs(gameMap.layers["warpBack"].objects) do
        warpX_back = obj.x
        warpY_back = obj.y
    end
end

