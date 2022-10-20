-- vec2.lua: A 2d vector library for lua.
-- It supports metamethods both for vectors and scalars so you can
-- vectorA + vectorB * 2
-- Note that those operations create some garbage because it creates a brand new vector with every
-- math operation, But from my testing it seems lua's garbage collector has got it covered.

local vec2 = {__type = "vec2"}
local mt = {__index = vec2}
setmetatable(vec2, mt)

-- Lets you create a new vector by calling the module
function mt.__call(self, ...)
    return vec2.new(...)
end

-- Lets you print vectors
function mt.__tostring(v)
    return "vec2: {"..v.x..", "..v.y.."}"
end

-- Addition
function mt.__add(a, b)
    if type(a) == "number" then
        -- A is scalar
        return vec2.new(b.x + a, b.y + a)
    elseif type(b) == "number" then
        -- B is scalar
        return vec2.new(a.x + b, a.y + b)
    else
        -- Both are vectors
        if a.__type == "vec2" and b.__type == "vec2" then
            return vec2.new(a.x + b.x, a.y + b.y)
        end
    end
end

-- Subtraction
function mt.__sub(a, b)
    if type(a) == "number" then
        -- A is scalar
        return vec2.new(b.x - a, b.y - a)
    elseif type(b) == "number" then
        -- B is scalar
        return vec2.new(a.x - b, a.y - b)
    else
        -- Both are vectors
        if a.__type == "vec2" and b.__type == "vec2" then
            return vec2.new(a.x - b.x, a.y - b.y)
        end
    end
end

-- Multiplication
function mt.__mul(a, b)
    if type(a) == "number" then
        -- A is scalar
        return vec2.new(b.x * a, b.y * a)
    elseif type(b) == "number" then
        -- B is scalar
        return vec2.new(a.x * b, a.y * b)
    else
        -- Both are vectors
        if a.__type == "vec2" and b.__type == "vec2" then
            return vec2.new(a.x * b.x, a.y * b.y)
        end
    end
end

-- Division
function mt.__div(a, b)
    if type(a) == "number" then
        -- A is scalar
        return vec2.new(b.x / a, b.y / a)
    elseif type(b) == "number" then
        -- B is scalar
        return vec2.new(a.x / b, a.y / b)
    else
        -- Both are vectors
        if a.__type == "vec2" and b.__type == "vec2" then
            return vec2.new(a.x / b.x, a.y / b.y)
        end
    end
end

-- Creates and returns a new vector. Defaults to 0x0
function vec2.new(x, y)
    return setmetatable({
        x = x or 0,
        y = y or 0
    }, mt)
end

function vec2:set(x, y)
    self.x = x or self.x
    self.y = y or self.y
end

function vec2:clone()
    return vec2.new(self.x, self.y)
end

-- Returns the distance between 2 vectors
function vec2.distance(a, b)
	return ((b.x-a.x)^2+(b.y-a.y)^2)^0.5
end

-- Returns the angle between 2 vectors
function vec2.angle(a, b)
	return math.atan2(b.y-a.y, b.x-a.x)
end

-- Returns the dot product of 2 vectors
function vec2.dot(a, b)
    return a.x * b.x + a.y * b.y
end

-- Randomizes a vectors components. Takes the same arguments as math.random
function vec2:randomize(...)
    self.x = math.random(...)
    self.y = math.random(...)
    return self
end

function vec2:setAngle(angle)
	local l = self:getLength()
	self.x = math.cos(angle) * l
	self.y = math.sin(angle) * l
end

function vec2:getAngle()
    return math.atan2(self.y, self.x)
end

function vec2:setLength(length)
	local a = self:getAngle()
	self.x = math.cos(a) * length
	self.y = math.sin(a) * length
end

function vec2:getLength()
	return math.sqrt(self.x * self.x + self.y * self.y)
end

function vec2:normalize()
	local l = self:getLength()
	if l > 0 then
		self.x = self.x / l
        self.y = self.y / l
	end
end

return vec2