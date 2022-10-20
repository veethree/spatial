-- GLOBALS
lg = love.graphics
fs = love.filesystem
kb = love.keyboard
lm = love.mouse
random = math.random
noise = love.math.noise
sin = math.sin
cos = math.cos
f = string.format

-- Detects intersections between two rectangles
local function rect(x1,y1,w1,h1, x2,y2,w2,h2)
    return x1 < x2+w2 and x2 < x1+w1 and y1 < y2+h2 and y2 < y1+h1
end

-- Adds commas to large numbers for clarity
function comma(amount)
  local formatted = amount
  while true do  
    formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
    if (k==0) then
      break
    end
  end
  return formatted
end

function love.load()
    moved = false -- Used to hide the info text when the player moves
    -- Slightly larger font than the default one
    lg.setFont(lg.newFont(24))
    -- Loading spatial
    spatial = require "spatial"
    vec2 = require "vec2"

    -- Creating a hash
    world = spatial()

    -- Creating a large amount of random items
    worldSize = 200000
    for i=1, 300000 do
        -- Rectangles you can shoot
        local item = {
            type = "thing",
            position = vec2(random(-worldSize, worldSize), random(-worldSize, worldSize)),
            width = random(10, 100),
            height = random(10, 100),
            color = {random(), random(), random()},
            drawMode = random(1, 2)
        }
        world:insert(item, item.position.x, item.position.y, item.width, item.height)
        
        -- Little dots that kinda look like stars
        for i=1, 5 do
            local bg = {
                type = "bg",
                position = vec2(random(-worldSize, worldSize), random(-worldSize, worldSize)),
                width = 1,
                height = 1,
                color = {1, 1, 1},
                drawMode = 1
            }
            world:insert(bg, bg.position.x, bg.position.y, bg.width, bg.height)
        end
    end

    -- Creating the worlds simplest camera
    camera = {
        x = 0,
        y = 0,
        buffer = 100 -- How far beyond the borders of the screen the camera can see.
    }

    -- Creating a player
    player = {
        type = "player",
        position = vec2(lg.getWidth() / 2, lg.getHeight() / 2),
        velocity = vec2(),
        thrust = vec2(),
        angle = 0,
        rotationSpeed = 4,
        width = 32,
        height = 16,
        acceleration = 500,
        topSpeed = 500,
        color = {0, 0.5, 1},
        shootRate = 8,
        shootTick = 0,
    }

    -- Creating an image to use for the player
    player.img = lg.newCanvas(player.width, player.height)
    lg.setCanvas(player.img)
    lg.setColor(1, 1, 1)
    lg.polygon("fill", 0, 0, 0, player.height, player.width, player.height / 2)
    lg.setCanvas()

    world:insert(player, player.position.x, player.position.y, player.width, player.height)

    -- Creating a custom filter function that deals with the fact i'm using vectors instead of simple x,y values
    filter = function(item, x, y, width, height)
        return rect(item.position.x, item.position.y, item.width, item.height, x, y, width, height)
    end
end

-- Shoots a bullet
function shoot()
    local bullet = {
        type = "bullet",
        position = player.position:clone(),
        velocity = vec2(),
        width = 3,
        height = 3,
        color = {0, 1, 1}
    }
    -- Setting the bullet velocity
    bullet.velocity:setLength(player.velocity:getLength() + 500)
    bullet.velocity:setAngle(player.angle)

    -- Adjust the position to account for the player drawing offset
    bullet.position.x = bullet.position.x + (player.width / 2)
    bullet.position.y = bullet.position.y + (player.height / 2)
    world:insert(bullet, bullet.position.x, bullet.position.y, bullet.width, bullet.height)
end

function love.update(dt)
    -- Player movement
    if kb.isDown("d") then
        player.angle = player.angle + player.rotationSpeed * dt        
        if player.angle > math.pi * 2 then player.angle = 0 end
    elseif kb.isDown("a") then
        player.angle = player.angle - player.rotationSpeed * dt        
        if player.angle < 0 then player.angle = math.pi * 2 end
    end

    if kb.isDown("w") then
        player.thrust:setLength(player.acceleration)
        player.thrust:setAngle(player.angle)
        player.velocity = player.velocity + player.thrust * dt
        if player.velocity:getLength() > player.topSpeed then
            player.velocity:setLength(player.topSpeed)
        end
        moved = true
    else
        player.velocity = player.velocity * 0.99
    end

    player.position = player.position + player.velocity * dt
    
    -- Shooting
    if kb.isDown("space") then
        player.shootTick = player.shootTick + dt
        if player.shootTick > 1 / player.shootRate then
            shoot()
            player.shootTick = 0
        end
    else
        player.shootTick = 1 / player.shootRate
    end
    
    -- Notifying spatial about the player position changing
    world:update(player, player.position.x, player.position.y, player.width, player.height)

    -- Making the camera follow the player
    camera.x = player.position.x - (lg.getWidth() / 2)
    camera.y = player.position.y - (lg.getHeight() / 2)

    -- Updating bullets
    -- This query only returns bullets thanks to the filter function
    local bullets, len = world:queryRect(camera.x - camera.buffer, camera.y - camera.buffer, lg.getWidth() + (camera.buffer * 2), lg.getHeight() + (camera.buffer * 2), function(item, x, y, width, height)
        return filter(item, x, y, width, height) and item.type == "bullet"
    end)

    for i,v in ipairs(bullets) do
        v.position = v.position + v.velocity * dt
        world:update(v, v.position.x, v.position.y, v.width, v.height)
        -- Spatial is totally not a collision detection library but here i'm using it to check if the bullets intersect with a thing
        local colliding, len = world:queryPoint(v.position.x, v.position.y, function(item) return item.type == "thing" or false end)
        if len > 0 then
            world:remove(v)
            for _,b in ipairs(colliding) do
                world:remove(b)
            end
        end

        -- Removing bullets that are off screen
        if not rect(v.position.x, v.position.y, v.width, v.height, camera.x, camera.y, lg.getWidth(), lg.getHeight()) then
            world:remove(v)
        end
    end
end

function love.draw()
    -- Grabbing all items seen by the camera
    local items, len = world:queryRect(camera.x, camera.y, lg.getWidth(), lg.getHeight(), filter)

    -- Applying the camera translation
    lg.push()
    lg.translate(-camera.x, -camera.y)

    -- Drawing spatials cells just for giggles
    local cells = world:getCells(camera.x, camera.y, lg.getWidth(), lg.getHeight())
    for i,v in ipairs(cells) do
        local a = #v
        lg.setColor(0.1, 0.5, 1, a * 0.1)
        lg.rectangle("fill", v._CELL.x * world.cellSize, v._CELL.y * world.cellSize, world.cellSize, world.cellSize)
    end

    -- Drawing the items
    local mode = {"fill", "line"}
    for i,v in ipairs(items) do
        lg.setColor(v.color)
        if v.type == "player" then
            lg.draw(v.img, v.position.x + (v.width / 2), v.position.y + (v.height / 2), v.angle, 1, 1, v.width / 2, v.height / 2)
        else
            lg.rectangle(mode[v.drawMode or 1], v.position.x, v.position.y, v.width, v.height)
        end
    end
    lg.pop()

    -- Some text
    lg.setColor(1, 1, 1)
    lg.printf(f("Drawn items: %s/%s\nFPS:%d", len, comma(world.length), love.timer.getFPS()), 0, 12, lg.getWidth(), "center")


    if not moved then
        lg.printf("You can control the spaceship with WASD, And shoot with the space bar. The world contains a total of " ..
            comma(world.length) .. " items, Spread over an area of " .. comma(worldSize * 2) .. "x" .. comma(worldSize * 2) .. " And if i've done this correctly you should be able to navigate this world at a buttery smooth 60 FPS",
            0, lg.getHeight() * 0.6, lg.getWidth(), "center")
    end
end

function love.mousepressed(x, y, b)
    if b == 1 then
        local mouseItems, len = world:queryPoint(camera.x + x, camera.y + y, filter)
        for i,v in ipairs(mouseItems) do
            v.color = {random(), random(), random()}
            v.drawMode = random(1, 2)
        end
    end
end

function love.keypressed(key)
    if key == "escape" then love.event.push("quit") end
end