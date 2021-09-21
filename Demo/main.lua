local lg = love.graphics
local lk = love.keyboard
local random = math.random
local floor = math.floor
local f = string.format

function love.load()
    lg.setBackgroundColor(0.1, 0.1, 0.1)
    spatial = require("spatial")
    camera = require("camera")

    -- Creating a database
    data = spatial.new(cell_size)

    -- Populating the database with random objects
    objects = 1000000
    for i=1, objects do
        local object = {
            x = random(-(lg.getWidth() * 100), lg.getWidth() * 100),
            y = random(-(lg.getHeight() * 100), lg.getHeight() * 100),
            radius = random(2, 6),
            color = {random(), random(), random()}
        }
        data:insert(object.x, object.y, object)
    end

    local w = lg.getWidth() * 200
    local h = lg.getHeight() * 200

    title_font = lg.newFont(24)
    hud_font = lg.newFont(16)

    start_message = f("Welcome to the Spatial.lua demo. There are %d objects, Scattered across an area of %dx%d\nUse the arrow keys to move around the world.", objects, w, h)
    
end


function love.update(dt)
    local left, right, up, down = lk.isDown("left"), lk.isDown("right"), lk.isDown("up"), lk.isDown("down")
    local camera_speed = 1000
    if left then
        camera:move(-camera_speed, 0)
    elseif right then
        camera:move(camera_speed)
    end 

    if up then
        camera:move(0, -camera_speed)
    elseif down then
        camera:move(0, camera_speed)
    end 
end

function love.draw()
    -- Querying the database for ojecects currently visible on the screen.
    local list, len = data:queryRect(camera.x, camera.y, lg.getWidth(), lg.getHeight())

    -- Drawing objects
    camera:push()
    for i,v in ipairs(list) do
        lg.setColor(v.color)
        lg.circle("fill", v.x, v.y, v.radius)
    end
    camera:pop()

    -- Info
    lg.setColor(0.9, 0.9, 0.9)
    lg.setFont(title_font)
    lg.printf(start_message, 0, lg.getHeight() * 0.6, lg.getWidth(), "center")
    
    local str = f("FPS: %d\nDrawn objects: %d / %d\nCamera: %dx%d", love.timer.getFPS(), len , objects, camera.x, camera.y)
    lg.setFont(hud_font)
    lg.printf(str, 12, 12, lg.getWidth(), "left")
end

function love.keypressed(key)
    if key == "escape" then love.event.push("quit") end
    start_message = ""
end