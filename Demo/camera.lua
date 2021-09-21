-- A super basic camera module.
-- Handles basic camera movement, But limited to translation and zoom
-- Optionally can handle paralax scrolling with it's layer system.

local camera = {
    x = 0,
    y = 0,
    scale = 1,
    layers = {},
    extra_scale = 2
}

local insert = table.insert
local remove = table.remove
local lg = love.graphics

-- Creates a new layer.
-- Scale: multiplier for the movement scale of the layer. Default is 1, 
-- Func: A drawing function for the layer
function camera:newLayer(scale, func)
    local layer = {
        scale = scale,
        func = func
    }
    insert(self.layers, layer)
end

function camera:push()
    lg.push()
    lg.translate(-self.x, -self.y)
    lg.scale(1 / self.scale, 1 / self.scale)
end

function camera:pop()
    lg.pop()
end

-- Moves the camera by x and y
function camera:move(x, y, dt)
    x = x or 0
    y = y or 0
    dt = dt or love.timer.getDelta()
    self.x = self.x + x * dt
    self.y = self.y + y * dt
end

function camera:set(x, y)
    self.x = x
    self.y = y
end

function camera:getMouse()
	return love.mouse.getX() + self.x, love.mouse.getY() + self.y
end

function camera:getBoundingBox()
    local x = self.x - lg.getWidth()
    local y = self.y - lg.getHeight()

    return x, y, lg.getWidth() * self.extra_scale, lg.getHeight() * self.extra_scale
end

function camera:getScreenPosition(e)
    if not e.position or not e.layer then return false end
    --local base_x, base_y = self.x, self.y
    return e.position.x - self.x * e.layer , e.position.y - self.y * e.layer
end

function camera:toScreen(x, y, layer)
    return x - self.x * layer , y - self.y * layer
end

function camera:toWorld(x, y, layer)
    return x + self.x * layer, y + self.y * layer
end

function camera:isVisible(e)
    if not e.position or not e.layer or not e.radius then return false end

    local x, y = self:getScreenPosition(e)
    if x > -(e.radius * 2) and x < lg.getWidth() + (e.radius * 2) and y > -(e.radius * 2) and y < lg.getHeight() + (e.radius * 2) then
        return true
    end
    return false
end

function camera:draw(scale, func, ...)
    local base_x, base_y = self.x, self.y

    self.x = base_x * scale
    self.y = base_y * scale
    self:push()
    func(unpack({...}))
    self:pop()

    self.x = base_x
    self.y = base_y
end

return camera