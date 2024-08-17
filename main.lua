function love.load()
    math.randomseed(os.time())

    GameState = 
    {
        idle = 1,
        running = 2,
        paused = 3,
        over = 4,
        timeOver = 5
    }
    currentGameState = GameState.idle

    sprites = {}
    sprites.player = love.graphics.newImage('sprites/player.png')
    sprites.zombie = love.graphics.newImage('sprites/zombie.png')
    sprites.bullet = love.graphics.newImage('sprites/bullet.png')
    sprites.background = love.graphics.newImage('sprites/background.png')

    player = {}
    player.x = love.graphics.getWidth() / 2
    player.y = love.graphics.getHeight() / 2
    player.w = sprites.player:getWidth()
    player.h = sprites.player:getHeight()
    player.speed = 180
    player.directionX = 0
    player.directionY = 0

    zombies = {}
    zombieSpawnRate = 2
    zombieSpawnTimer = zombieSpawnRate
    zombieCollisionCount = 0
    zombieKilledCount = 0
    score = 0
    
    gameTimer = 30

    bullets = {}

    gameFont = love.graphics.newFont(40)
    scoreFont = love.graphics.newFont(20)
end

function love.update(dt)
    if currentGameState == GameState.idle then
        gameTimer = 30
        score = 0
        player.x = love.graphics.getWidth() / 2
        player.y = love.graphics.getHeight() / 2
    elseif currentGameState == GameState.running then
        onRunning(dt)
    elseif currentGameState == GameState.paused then

    elseif currentGameState == GameState.over then
        player.x = love.graphics.getWidth() / 2
        player.y = love.graphics.getHeight() / 2
    elseif currentGameState == GameState.timeOver then
        player.x = love.graphics.getWidth() / 2
        player.y = love.graphics.getHeight() / 2
    end
end

function love.draw()
    love.graphics.draw(sprites.background, 0, 0)

    if currentGameState == GameState.idle then
        love.graphics.setColor(1, 0, 0)
        love.graphics.rectangle("fill", 0, love.graphics.getHeight() / 2 - 40, love.graphics.getWidth(), 80)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(gameFont)
        love.graphics.printf("Press space to begin or esc to quit!", 0, love.graphics.getHeight()/2 - 20, love.graphics.getWidth(), "center")
    elseif currentGameState == GameState.running then
        love.graphics.draw(sprites.player, player.x, player.y, playerMouseAngle(), nil, nil, player.w / 2, player.h / 2)

        for i,z in ipairs(zombies) do 
            love.graphics.draw(sprites.zombie, z.x, z.y, zombiePlayerAngle(z), nil, nil, z.w / 2, z.h / 2)
        end
        love.graphics.setFont(scoreFont)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Score: " .. score, 5, 5)
        love.graphics.print("Time: " .. math.ceil(gameTimer), 5, 30)
    
        for i,b in ipairs(bullets) do
            love.graphics.draw(sprites.bullet, b.x, b.y, nil, 0.5, nil, b.w / 2, b.h / 2)
        end
    elseif currentGameState == GameState.paused then
        love.graphics.setColor(1, 0, 0)
        love.graphics.rectangle("fill", 0, love.graphics.getHeight() / 2 - 40, love.graphics.getWidth(), 120)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(gameFont)
        love.graphics.printf("Paused, press space to continue, enter to restart or esc to quit!", 0, love.graphics.getHeight()/2 - 20, love.graphics.getWidth(), "center")
    elseif currentGameState == GameState.over then
        love.graphics.setColor(1, 0, 0)
        love.graphics.rectangle("fill", 0, love.graphics.getHeight() / 2 - 40, love.graphics.getWidth(), 120)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(gameFont)
        love.graphics.print("Score: " .. score, love.graphics.getWidth() / 2 - 65, 5)
        love.graphics.printf("Game over! Press enter to restart or esc to quit!", 0, love.graphics.getHeight()/2 - 20, love.graphics.getWidth(), "center")
    elseif currentGameState == GameState.timeOver then
        love.graphics.setColor(1, 0, 0)
        love.graphics.rectangle("fill", 0, love.graphics.getHeight() / 2 - 40, love.graphics.getWidth(), 120)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(gameFont)
        love.graphics.print("Score: " .. score, love.graphics.getWidth() / 2 - 65, 5)
        love.graphics.printf("Time out! Press enter to restart or esc to quit!", 0, love.graphics.getHeight()/2 - 20, love.graphics.getWidth(), "center")
    end
end

function onRunning(dt)
    gameTimer = gameTimer - dt

    if gameTimer < 0 then
        currentGameState = GameState.timeOver
    end

    player.directionX = 0
    player.directionY = 0

    if love.keyboard.isDown("w") and player.y - player.h / 2 > 0 then
        player.directionY = player.directionY - 1
    end
    if love.keyboard.isDown("s") and player.y + player.h / 2 < love.graphics.getHeight() then
        player.directionY = player.directionY + 1
    end
    if love.keyboard.isDown("a") and player.x - player.w / 2 > 0 then
        player.directionX = player.directionX - 1
    end
    if love.keyboard.isDown("d") and player.x + player.w / 2 < love.graphics.getWidth() then
        player.directionX = player.directionX + 1
    end

    player.velocityX = player.directionX * player.speed * dt
    player.velocityY = player.directionY * player.speed * dt

    player.x = player.x + player.velocityX
    player.y = player.y + player.velocityY

    for i,b in ipairs(bullets) do
        local b = bullets[i]
        b.x = b.x + math.cos(b.direction) * b.speed * dt
        b.y = b.y + math.sin(b.direction) * b.speed * dt
    end

    zombieSpawnTimer = zombieSpawnTimer - dt
    if zombieSpawnTimer <= 0 then
        spawnZombie()
        zombieSpawnRate = 0.95 * zombieSpawnRate -- consertar
        zombieSpawnTimer = zombieSpawnRate
    end

    for i,z in ipairs(zombies) do
        local z = zombies[i]
        z.x = z.x + math.cos(zombiePlayerAngle(z)) * z.speed * dt
        z.y = z.y + math.sin(zombiePlayerAngle(z)) * z.speed * dt
        if checkCollision(player.x, player.y, player.w - 5, player.h, z.x, z.y, z.w - 25, z.h) then
            zombieCollisionCount = zombieCollisionCount + 1
            z.dead = true   
        end
        for j,b in ipairs(bullets) do
            if checkCollision(z.x, z.y, z.w - 10, z.h - 10, b.x, b.y, b.w / 2, b.h / 2) then
                zombieKilledCount = zombieKilledCount + 1
                z.dead = true
                b.dead = true
            end
        end
    end

    for i = #zombies, 1, -1 do
        local z = zombies[i]

        if z.dead == true then
            table.remove(zombies, i)
        end
    end

    for i = #bullets, 1, -1 do
        local b = bullets[i]

        if b.dead == true or b.x < 0 or b.x > love.graphics.getWidth() or b.y < 0 or b.y > love.graphics.getHeight() then
            table.remove(bullets, i)
        end
    end

    score = zombieKilledCount - zombieCollisionCount

    if score < 0 then
        currentGameState = GameState.over
    end
end

function love.keypressed(key)
    if currentGameState == GameState.idle then
        if key == 'space' then 
            currentGameState = GameState.running
        elseif key == 'escape' then
            love.event.quit()
        end
    elseif currentGameState == GameState.running then
        if key == 'escape' then
            currentGameState = GameState.paused
        end
    elseif currentGameState == GameState.paused then
        if key == 'escape' then
            love.event.quit()
        elseif key == 'return' then
            currentGameState = GameState.idle
        elseif key == 'space' then
            currentGameState = GameState.running
        end
    elseif currentGameState == GameState.over then
        if key == 'escape' then
            love.event.quit()
        elseif key == 'return' then
            currentGameState = GameState.idle
        end
    elseif currentGameState == GameState.timeOver then
        if key == 'escape' then
            love.event.quit()
        elseif key == 'return' then
            currentGameState = GameState.idle
        end
    end
end

function love.mousepressed(x, y, button)
    if currentGameState == GameState.running then
        if button == 1 then
            spawnBullet()
        end
    end
end

function playerMouseAngle()
    return math.atan2(love.mouse.getY() - player.y, love.mouse.getX() - player.x)
end

function spawnZombie()
    local zombie = {}
    zombie.x = 0
    zombie.y = 0
    zombie.w = sprites.zombie:getWidth()
    zombie.h = sprites.zombie:getHeight()
    zombie.speed = 120
    zombie.dead = false
    
    local screenSide = math.random(1, 4)
    if screenSide == 1 then
        zombie.x = -32
        zombie.y = math.random(0, love.graphics.getHeight())
    elseif screenSide == 2 then
        zombie.x = math.random(0, love.graphics.getWidth())
        zombie.y = -32
    elseif screenSide == 3 then
        zombie.x = love.graphics.getWidth() + 32
        zombie.y = math.random(0, love.graphics.getHeight())
    elseif screenSide == 4 then
        zombie.x = math.random(0, love.graphics.getWidth())
        zombie.y = love.graphics.getHeight() + 32
    end

    table.insert(zombies, zombie)
end

function zombiePlayerAngle(enemy)
    return math.atan2(player.y - enemy.y, player.x - enemy.x)
end

function spawnBullet()
    local bullet = {}
    bullet.x = player.x
    bullet.y = player.y
    bullet.w = sprites.bullet:getWidth()
    bullet.h = sprites.bullet:getHeight()
    bullet.speed = 350
    bullet.direction = playerMouseAngle()
    bullet.dead = false

    table.insert(bullets, bullet)
end

function checkCollision(xa, ya, wa, ha, xb, yb, wb, hb)
    local maxXa = xa + wa
    local maxYa = ya + ha
    local maxXb = xb + wb
    local maxYb = yb + hb

    local collisionX = maxXa >= xb and maxXb >= xa
    local collisionY = maxYa >= yb and maxYb >= yb

    return collisionX and collisionY
end