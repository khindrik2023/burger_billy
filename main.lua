
-- LOVE.LOAD() --------------------------------------------------
function love.load()
    love.window.setMode(1000, 768)

    -- variables
    gameState = 'titlescreen'
    wordInput = '' -- user input for word that they want to spell
    playerWord = '' -- stores wordInput
    characters = {} -- stores individual characters of wordInput
    wordLength = 0
    charIndex = 0
    currentLevel = 1
    lives = 3
    blinkTimer = 0
    isBlinking = true
    blinkInterval = 0.5
    resetGameBool = false
    congratsBGbool = false

    -- libraries
    anim8 = require 'libraries/anim8/anim8'
    sti = require 'libraries/Simple-Tiled-Implementation/sti'
    cameraFile = require 'libraries/hump/camera'
    -- dictionary for checking validity of user input
    dictionaryFromFile = {}
    for line in love.filesystem.lines("libraries/dictionary/enable1.txt") do
        table.insert(dictionaryFromFile, line)
    end

    cam = cameraFile()

    -- music and sfx
    sounds = {}
    sounds.jump = love.audio.newSource("audio/Alberto Sueri - 8 Bit Fun - Classic Jump Glide Up Bleep.wav", 'static')
    sounds.jump:setVolume(.5)
    sounds.warp = love.audio.newSource("audio/Sound Response - 8 Bit Retro - Power up Trophy .wav", 'static')
    sounds.beep = love.audio.newSource("audio/Gamemaster Audio - Videogame Powerups - Collect Coin 8 bit.wav", 'static')
    sounds.beep:setVolume(.6)
    sounds.newlife = love.audio.newSource("audio/Sound Response - 8 Bit Retro - Arcade Reward Trophy.wav", 'static')
    sounds.newlife:setVolume(.7)
    sounds.dead = love.audio.newSource("audio/Sound Response - 8 Bit Retro - Downwards Fall Loose.wav", 'static')
    sounds.dead:setVolume(6)
    sounds.failed = love.audio.newSource("audio/Sound Response - 8 Bit Jingles - Slide down Lost Experience .wav", 'static')
    sounds.failed:setVolume(2)
    sounds.music = love.audio.newSource("audio/Kashido - Swan Lake Theme.wav", 'stream')
    sounds.music:setLooping(true)
    sounds.music:setVolume(0.6)
    sounds.music:play()
    sounds.endMusic = love.audio.newSource('audio/T. Bless - Froggy Fraud Adventure.wav', 'stream')
    --sounds.die = love.audio.newSource("audio/Sound Response - 8 Bit Retro - Arcade Blip.wav", 'static')
    sounds.finish = love.audio.newSource('audio/Sound Response - 8 Bit Jingles - Glide up Win.wav', 'static')
    finishSoundPlayed = false
    sounds.failedMusic = love.audio.newSource('audio/Kashido - Minuet in G Major.wav', 'stream')
    sounds.failedMusic:setVolume(0.9)


    sprites = {}
    sprites.playerSheet = love.graphics.newImage('sprites/playerSheet.png')
    sprites.enemySheet = love.graphics.newImage('sprites/pixel_art_burger_by_artfritz_dg2krlu-fullview.png')
    sprites.titlescreen = love.graphics.newImage('sprites/titlescreen.png')
    sprites.background = love.graphics.newImage('sprites/background.png')
    sprites.backgroundPlain = love.graphics.newImage('sprites/backgroundPlain.png')
    sprites.backgroundFailed = love.graphics.newImage('sprites/backgroundFailed.png')
    sprites.winterBG = love.graphics.newImage('sprites/winterBG.png')
    sprites.forest = love.graphics.newImage('sprites/forest.png')
    sprites.white = love.graphics.newImage('sprites/white.png')
    sprites.heart = love.graphics.newImage('sprites/heart.png')

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

    -- if player falls, reset
    dangerZone = world:newRectangleCollider(-500, 800, 5000, 50, {collision_class = 'Danger'})
    dangerZone:setType('static')

    platforms = {}
    walls = {}

    -- these tracks the location of warpzone objects
    warpX = 0
    warpY = 0

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
    awesomeFontbigger = love.graphics.newFont('font/Minercraftory.ttf', 80)
    awesomeFonthp = love.graphics.newFont('font/Minercraftory.ttf', 25)


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

        -- checks if user gets damaged 3 times
        if lives <= 0 then
            gameState = 'failed'
        end

        -- query used to check for warpzones to advance to next level 
        local colliders = world:queryRectangleArea(warpX, warpY, 200, 200, {'Player'})
        if #colliders > 0 then
            charIndex = charIndex + 1
            if charIndex < wordLength + 1 then
                currentLevel = string.byte(characters[charIndex]) - 96
                loadMap(currentLevel)
                sounds.warp:play()
            end
        end

        if gameState == 'wordInput' and resetGameBool == false then
            sounds.music:play()
            lives = 3
        end

        if gameState == 'playing' then
            sounds.endMusic:stop()
            sounds.failedMusic:stop()
            sounds.music:play()
        end
 
        if gameState == 'congratulations' then
            lives = 3
            congratsBGbool = true
            if not finishSoundPlayed then
                sounds.finish:play()
                finishSoundPlayed = true
            end       
            player.animation = animations.jump
            sounds.music:stop()
            sounds.endMusic:play()
        end

        if gameState == 'failed' then
            if not failedSoundPlayed then
                sounds.failed:play()
                failedSoundPlayed = true
            end       
            sounds.music:stop() 
            sounds.failedMusic:play() 
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
    if gameState == 'titlescreen' then
        love.graphics.draw(sprites.titlescreen, 0, 0)
        love.graphics.setFont(awesomeFont)
        local textWidth = love.graphics.getWidth() 
        if isBlinking then
            love.graphics.printf('Press "ENTER"', 0, 660, textWidth, 'center') 
        end
    end

    if gameState == 'wordInput' then
        love.graphics.draw(sprites.background, 0, 0)
        love.graphics.setFont(awesomeFont)
        local textWidth = love.graphics.getWidth() 
        love.graphics.printf("Billy can't read because", 0, love.graphics.getHeight()/2 - 180, textWidth, 'center') 
        love.graphics.printf("he's too busy eating burgers.", 0, love.graphics.getHeight()/2 - 145, textWidth, 'center') 
        love.graphics.printf("Help Billy stop eating", 0, love.graphics.getHeight()/2 - 110, textWidth, 'center') 
        love.graphics.printf("and start reading!", 0, love.graphics.getHeight()/2 - 75, textWidth, 'center') 
        love.graphics.printf("Enter a word for Billy to learn...", 0, love.graphics.getHeight()/2, textWidth, 'center') 

        love.graphics.setFont(awesomeFontbig)
        love.graphics.printf(wordInput, 0, love.graphics.getHeight()/2 + 40, textWidth, 'center')
        player.animation:draw(sprites.playerSheet, 500, 550, nil, .5*player.direction, .5, 100, 90)

    
    elseif gameState == 'playing' then
        love.graphics.draw(sprites.background, 0, 0)
        -- winterBG
        if currentLevel == 12 or currentLevel == 13 or currentLevel == 14 or currentLevel == 18 or currentLevel == 19 then
            love.graphics.draw(sprites.winterBG, 0, 0)
        end
        -- forest
        if currentLevel == 4 or currentLevel == 15 or currentLevel == 16 or currentLevel == 20 or currentLevel == 25 then
            love.graphics.draw(sprites.forest, 0, 0)
        end
        -- white
        if currentLevel == 2 or currentLevel == 8 or currentLevel == 21 or currentLevel == 22 or currentLevel == 24 or currentLevel == 26 then
            love.graphics.draw(sprites.white, 0, 0)
        end
    
        cam:attach()
            gameMap:drawLayer(gameMap.layers["Tile Layer 1"])
            drawPlayer()
            drawEnemies()
            --world:draw() -- prints all objects to screen for debugging

        cam:detach()

        -- this prints the current spelled letters on screen so user can keep track of the word
        if charIndex >= 2 and charIndex <= #characters then
            local currentWord = ""
            for i = 1, charIndex - 1 do
                currentWord = currentWord .. characters[i]
            end
            love.graphics.setFont(awesomeFontbigger)
            local textWidth = love.graphics.getWidth() 
            love.graphics.printf(string.upper(currentWord), 38, 70, textWidth, 'left')     
        end

        -- prints health meter
        local textWidth = love.graphics.getWidth() 
        love.graphics.setFont(awesomeFonthp) 
        love.graphics.printf('HP', 40, 41, textWidth, 'left')
        love.graphics.draw(sprites.heart, 88, 45, nil, .045, nil)
        if lives == 2 or lives == 3 then
            love.graphics.draw(sprites.heart, 123, 45, nil, .045, nil)
        end
        if lives == 3 then
            love.graphics.draw(sprites.heart, 158, 45, nil, .045, nil)
        end

        -- check prints for debugging
        --[[
        love.graphics.setFont(testFont)
        local textWidth = love.graphics.getWidth()  
        love.graphics.printf("word: " .. playerWord, 10, 20, textWidth, 'left')
        love.graphics.printf("length: " .. wordLength, 10, 40, textWidth, 'left')
        love.graphics.printf("charIndex: " .. charIndex, 10, 60, textWidth, 'left')
        if charIndex < wordLength + 1 then
            love.graphics.printf("character: " .. characters[charIndex], 10, 80, textWidth, 'left')
            love.graphics.printf("ASCII: " .. string.byte(characters[charIndex])-96, 10, 100, textWidth, 'left')
            love.graphics.printf("lives: " .. lives, 10, 120, textWidth, 'left')
        end
        ]]

    elseif gameState == 'congratulations' then 
        love.graphics.draw(sprites.background, 0, 0)   
        local textWidth = love.graphics.getWidth()  
        if isBlinking then
            love.graphics.setFont(awesomeFontbigger)
            love.graphics.printf(string.upper(playerWord), 0, 110, textWidth, 'center')     
        end
        love.graphics.setFont(awesomeFont)
        love.graphics.printf("Congratulations!", 0, love.graphics.getHeight()/2 - 80, textWidth, 'center')
        love.graphics.printf('Billy learned how to spell "' .. string.upper(playerWord) .. '"', 20, love.graphics.getHeight()/2 - 40, textWidth, 'center')
        love.graphics.printf('Press "ENTER" to learn more words!', 0, love.graphics.getHeight()/2, textWidth, 'center')
        player.animation:draw(sprites.playerSheet, 500, 550, nil, .5*player.direction, .5, 100, 90)
    
    elseif gameState == 'failed' then
        love.graphics.draw(sprites.backgroundFailed, 0, 0)
        local textWidth = love.graphics.getWidth()  
        love.graphics.setFont(awesomeFont)
        love.graphics.printf('Billy ate too many burgers and fell asleep!', 0, love.graphics.getHeight()/2 - 50, textWidth, 'center')
        love.graphics.printf('Please try again.', 0, love.graphics.getHeight()/2 - 10, textWidth, 'center')
        love.graphics.printf('Press "ENTER"', 0, love.graphics.getHeight()/2 + 40, textWidth, 'center')
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
    if gameState == 'titlescreen' then
        if key == 'return' then
            gameState = 'wordInput'
            sounds.beep:play()
            return -- exit function after titlescreen
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
                    sounds.newlife:play()
                    loadMap(currentLevel)
                end
            else
                currentLevel = 1 -- default value if something goes wrong
            end    
        elseif key == 'backspace' then
            wordInput = wordInput:sub(1, -2) -- allows backspaces to remove characters
        end

    elseif gameState == 'congratulations' or gameState == 'failed' then
        if key == 'return' then
            sounds.beep:play()
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
-- the "Platforms", "Walls", "Enemies", and "Warp" objects.
-- the value for "mapName" is determined from a query
-- in love.update()

function loadMap(currentLevel)
    mapName = "level" .. currentLevel
    destroyAll()
    player:setPosition(playerStartX, playerStartY)
    
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
    lives = 3
    finishSoundPlayed = false
    failedSoundPlayed = false
    resetGameBool = true
    congratsBGbool = false

    player:setPosition(150, 100)

    destroyAll()
    loadMap(1) 

    --sounds.endMusic:stop()
    --sounds.music:play()
end

