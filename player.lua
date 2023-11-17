playerStartX = 150
playerStartY = 100

player = world:newRectangleCollider(playerStartX, playerStartY, 80, 100, {collision_class = 'Player'})
player:setFixedRotation(true)
player.animation = animations.idle
player.speed = 400
player.isMoving = false
player.direction = 1
player.grounded = true


function playerUpdate(dt)

    if player.body then
        local colliders = world:queryRectangleArea(player:getX()-40, player:getY()+50, 80, 2, {'Platform'})
        if #colliders > 0 then
            player.grounded = true
        else
            player.grounded = false
        end

        player.isMoving = False

        local px, py = player:getPosition()
        if love.keyboard.isDown('right') then
            player:setX(px + player.speed * dt)
            player.isMoving = true
            player.direction = 1
        end
        if love.keyboard.isDown('left') then
            player:setX(px - player.speed * dt)
            player.isMoving = true
            player.direction = -1
        end

        if player:enter('Danger') then
            player:setPosition(playerStartX, playerStartY)
            sounds.dead:play()
        end
    end

    if player.grounded == true then
        if player.isMoving == true then
            player.animation = animations.run
        else 
            player.animation = animations.idle
        end
    else
        player.animation = animations.jump
    end

    player.animation:update(dt)
end

function drawPlayer()
    local px, py = player:getPosition()
    player.animation:draw(sprites.playerSheet, px, py, nil, .5*player.direction, .5, 100, 95)
end





