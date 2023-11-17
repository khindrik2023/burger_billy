
-- LOVE.LOAD() --------------------------------------------------
function love.load()
    love.window.setMode(1000, 768)
    gameState = 'intro'
    wordInput = '' -- user input for word that they want to spell
    playerWord = '' -- stores wordInput
    characters = {} -- stores individual characters of wordInput
    wordLength = 0
    charIndex = 0
    currentLevel = 1
    previousLevel = 1
    blinkTimer = 0
    isBlinking = true
    blinkInterval = 0.5

    -- libraries
    anim8 = require 'libraries/anim8/anim8'
    sti = require 'libraries/Simple-Tiled-Implementation/sti'
    cameraFile = require 'libraries/hump/camera'
    -- dictionary for checking validity of user input
    dictionaryFromFile = {}
    for line in love.filesystem.lines("libraries/dictionary/popular.txt") do
        table.insert(dictionaryFromFile, line)
    end

    cam = cameraFile()

    -- music and sfx
    sounds = {}
    sounds.jump = love.audio.newSource("audio/Alberto Sueri - 8 Bit Fun - Classic Jump Glide Up Bleep.wav", 'static')
    sounds.jump:setVolume(.5)
    sounds.warp = love.audio.newSource("audio/Sound Response - 8 Bit Retro - Power up Trophy .wav", 'static')
    sounds.music = love.audio.newSource("audio/Kashido - Swan Lake Theme.wav", 'stream')
    sounds.endMusic = love.audio.newSource('audio/T. Bless - Froggy Fraud Adventure.wav', 'stream')
    sounds.die = love.audio.newSource("audio/Sound Response - 8 Bit Retro - Arcade Blip.wav", 'static')
    sounds.finish = love.audio.newSource('audio/Sound Response - 8 Bit Jingles - Glide up Win.wav', 'static')
    finishSoundPlayed = false
    sounds.music:setLooping(true)
    sounds.music:setVolume(0.5)
    sounds.music:play()
    

    sprites = {}
    sprites.playerSheet = love.graphics.newImage('sprites/playerSheet.png')
    sprites.enemySheet = love.graphics.newImage('sprites/pixel_art_burger_by_artfritz_dg2krlu-fullview.png')
    sprites.background = love.graphics.newImage('sprites/background.png')

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
    world:addCollisionClass('Wall')
    world:addCollisionClass('Player')
    world:addCollisionClass('Danger')

    require('player')   
    require('enemy') 

    -- dangerZone = world:newRectangleCollider(0, 550, 800, 50, {collision_class = 'Danger'})
    -- dangerZone:setType('static')

    platforms = {}
    walls = {}

    -- these tracks the location of warpzone objects
    warpX = 0
    warpY = 0
    backX = 0
    backY = 0

    -- keeps track of levels and load initial level
    -- "currentLevel" is updated in love.update()
    if #characters > 0 then
        local char = string.byte(characters[1])
        if char >= 97 and char <=122 then
            currentLevel = char
        else
            currentLevel = 1 -- default level 1 if something goes wrong
        end
    else
        currentLevel = 1 -- assigned default level 1 if something goes wrong
    end

    loadMap(currentLevel)

    testFont = love.graphics.newFont(20)
    awesomeFont = love.graphics.newFont('font/Minercraftory.ttf', 20)
    awesomeFontbig = love.graphics.newFont('font/Minercraftory.ttf', 40)
    awesomeFontbigger = love.graphics.newFont('font/I-pixel-u.ttf', 80)


end

-- LOVE.UPDATE() ------------------------------------------
function love.update(dt)
    world:update(dt)
    gameMap:update(dt)
    playerUpdate(dt) 
    updateEnemies(dt)   

    if player.body then
        local px, py = player:getPosition()
        cam:lookAt(px, love.graphics.getHeight()/2)

        -- checks to see if charIndex == wordLength, 
        -- which means the word has been spelled successfully.
        if charIndex == wordLength + 1 then
            gameState = 'congratulations'
            charIndex = 1
        end

        -- query used to check for warpzones to advance to next level 
        local colliders = world:queryRectangleArea(warpX, warpY, 200, 200, {'Player'})
        if #colliders > 0 then
            previousLevel = currentLevel
            charIndex = charIndex + 1
            if charIndex < wordLength + 1 then
                currentLevel = string.byte(characters[charIndex]) - 96
                loadMap(currentLevel)
                sounds.warp:play()
            end
        end

        if gameState == 'wordInput' or gameState == 'playing' then
            sounds.endMusic:stop()
            sounds.endMusic:play()
        end
 
        if gameState == 'congratulations' then
            if not finishSoundPlayed then
                sounds.finish:play()
                finishSoundPlayed = true
            end       
            player.animation = animations.idle
            sounds.music:stop()
            sounds.endMusic:play()
        end
    end

    blinkTimer = blinkTimer + dt
    if blinkTimer >= blinkInterval then
        isBlinking = not isBlinking  
        blinkTimer = 0 
    end
end

-- LOVE.DRAW() ------------------------------------------------
function love.draw()
    if gameState == 'playing' or gameState == 'congratulations' then
        love.graphics.draw(sprites.background, 0, 0)
    end

    if gameState == 'intro' then
        love.graphics.setFont(testFont)
        local textWidth = love.graphics.getWidth() 
        love.graphics.printf("intro screen", 0, love.graphics.getHeight()/2 - 50, textWidth, 'center') 
    end
    if gameState == 'wordInput' then
        love.graphics.setFont(awesomeFont)
        local textWidth = love.graphics.getWidth() 
        love.graphics.printf("Billy can't read because", 0, love.graphics.getHeight()/2 - 180, textWidth, 'center') 
        love.graphics.printf("he's too busy eating burgers.", 0, love.graphics.getHeight()/2 - 145, textWidth, 'center') 
        love.graphics.printf("Help Billy stop eating", 0, love.graphics.getHeight()/2 - 110, textWidth, 'center') 
        love.graphics.printf("and start reading!", 0, love.graphics.getHeight()/2 - 75, textWidth, 'center') 
        love.graphics.printf("Enter a word for Billy to learn...", 0, love.graphics.getHeight()/2, textWidth, 'center') 

        love.graphics.setFont(awesomeFontbig)
        love.graphics.printf(wordInput, 0, love.graphics.getHeight()/2 + 55, textWidth, 'center')
        
    elseif gameState == 'playing' then
        love.graphics.setFont(testFont)
        local textWidth = love.graphics.getWidth()  
        love.graphics.printf("word: " .. playerWord, 10, 20, textWidth, 'left')
        love.graphics.printf("length: " .. wordLength, 10, 40, textWidth, 'left')
        love.graphics.printf("charIndex: " .. charIndex, 10, 60, textWidth, 'left')
        if charIndex < wordLength + 1 then
            love.graphics.printf("characters: " .. characters[charIndex], 10, 80, textWidth, 'left')
            love.graphics.printf("ASCII: " .. string.byte(characters[charIndex])-96, 10, 100, textWidth, 'left')
        end

        -- this prints the current spelled letters on screen so user can keep track of the word
        if charIndex >= 2 and charIndex <= #characters then
            local currentWord = ""
            for i = 1, charIndex - 1 do
                currentWord = currentWord .. characters[i]
            end
            love.graphics.setFont(awesomeFontbigger)
            love.graphics.printf(string.upper(currentWord), 10, 60, textWidth, 'center')     
        end
    
        cam:attach()
            gameMap:drawLayer(gameMap.layers["Tile Layer 1"])
            world:draw()
            drawPlayer()
            drawEnemies()
        cam:detach()

    elseif gameState == 'congratulations' then    
        local textWidth = love.graphics.getWidth()  
        if isBlinking then
            love.graphics.setFont(awesomeFontbigger)
            love.graphics.printf(string.upper(playerWord), 0, 110, textWidth, 'center')     
        end
        love.graphics.setFont(awesomeFont)
        love.graphics.printf("Congratulations!", 0, love.graphics.getHeight()/2 - 80, textWidth, 'center')
        love.graphics.printf('Billy learned how to spell "' .. string.upper(playerWord) .. '"', 20, love.graphics.getHeight()/2 - 40, textWidth, 'center')
        love.graphics.printf('Press "Enter" to', 0, love.graphics.getHeight()/2, textWidth, 'center')
        love.graphics.printf('teach him some more!', 0, love.graphics.getHeight()/2 + 40, textWidth, 'center')
        player.animation:draw(sprites.playerSheet, 500, 600, nil, .5*player.direction, .5, 100, 90)
    end 
end



-- OTHER FUNCTIONS -----------------------------------------

function isWordValid(word) -- uses a dictionary to check validity of user input
    for _, dictWord in ipairs(dictionaryFromFile) do
        if word == dictWord then
            return true
        end
    end
    return false
end

function love.textinput(t) -- manages text input when user types word
    if gameState == 'wordInput' then
        wordInput = wordInput .. t
    end
end

function love.keypressed(key)
    if gameState == 'intro' then
        if key == 'return' then
            gameState = 'wordInput'
            return -- exit function after intro screen
        end
    end
    if gameState == 'wordInput' then
        if key == 'return' then
            if wordInput ~= nil and wordInput~= "" then
                playerWord = string.lower(wordInput)

                if isWordValid(playerWord) then
                    --separate user input into separate characters
                    characters = {}
                    wordLength = string.len(playerWord)
                    charIndex = 1
                    for i = 1, #playerWord do
                        local letter = wordInput:sub(i, i)
                        table.insert(characters, string.lower(letter))
                    end

                    currentLevel = string.byte(characters[1]) - 96
                    gameState = 'playing'
                    loadMap(currentLevel)
                end
            else
                currentLevel = 1 -- default value if something goes wrong
            end    
        elseif key == 'backspace' then
            wordInput = wordInput:sub(1, -2) -- allows backspaces to remove characters
        end

    elseif gameState == 'congratulations' then
        if key == 'return' then
            resetGame()
        end
    else
        if key == 'up' then
            if player.grounded == true then
                player:applyLinearImpulse(0, -20000)
                player.animation = animations.jump
                sounds.jump:play()
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

function spawnWall(x, y, width, height)
    if width > 0 and height > 0 then
        local wall = world:newRectangleCollider(x, y, width, height, {collision_class = 'Wall'})
        wall:setType('static')
        table.insert(walls, wall)
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

    local i = #walls
    while i > -1 do
       if walls[i] ~= nil then
            walls[i]:destroy()
       end
       table.remove(walls, i)
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


-- LOADMAP ----------------------------------------------
-- this function spawns the graphics for 
-- the "Platforms", "Enemies", and "warpForward" objects.
-- the value for "mapName" is determined from a query
-- in love.update()

function loadMap(currentLevel)
    mapName = "level" .. currentLevel
    destroyAll()
    player:setPosition(150, 100)
    
    gameMap = sti("maps/" .. mapName .. ".lua")

    for i, obj in pairs(gameMap.layers["Platforms"].objects) do
        spawnPlatform(obj.x, obj.y, obj.width, obj.height)
    end
    for i, obj in pairs(gameMap.layers["Walls"].objects) do
        spawnWall(obj.x, obj.y, obj.width, obj.height)
    end  
    for i, obj in pairs(gameMap.layers["Enemies"].objects) do
        spawnEnemy(obj.x, obj.y)
    end
    for i, obj in pairs(gameMap.layers["Warp"].objects) do
        warpX = obj.x
        warpY = obj.y
    end   
end

function resetGame()
    -- Reset all game variables and state to their initial values
    gameState = 'wordInput'
    wordInput = ''
    playerWord = ''
    characters = {}
    wordLength = 0
    charIndex = 0
    finishSoundPlayed = false

    player:setPosition(150, 100)

    destroyAll()
    loadMap(1) 

    sounds.endMusic:stop()
    sounds.music:play()
end

