-- Spatial - A minimal spacial hashing library for lua.
-- Version 2.0
--
-- MIT License
-- 
-- Copyright (c) 2022 Pawel Þorkelsson
-- 
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
-- 
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

--:: SHORTHANDS ::--
local floor, insert, remove, f = math.floor, table.insert, table.remove, string.format

--:: LOCAL FUNCTUONS ::--
-- Returns true if 2 rectangles are intersecting
local function rect(x1,y1,w1,h1, x2,y2,w2,h2)
    return x1 < x2+w2 and x2 < x1+w1 and y1 < y2+h2 and y2 < y1+h1
end

-- Returns true of table "tab" contains item "item"
local function contains(tab, item)
    for k,v in pairs(tab) do
        if v == item then
            return true, k
        end
    end
    return false
end

local spatial = {
    filters = {
        default = function() return true end, 
        rect = function(item, x, y, width, height) 
            return rect(item.x, item.y, item.width, item.height, x, y, width, height)
        end
    }
}
local mt = {__index = spatial}
setmetatable(spatial, mt)

-- Making the module callable
function mt.__call(self, ...)
    return self.new(...)  
end

--:: INTERNAL METHODS ::--

--- Returns cell coordinates for every cells a rectangle intersects with
function spatial:getCellCoordinates(x, y, width, height)
    -- Finding the min and max cell that intersects
    local minX, maxX = floor(x / self.cellSize), floor((x + width) / self.cellSize)
    local minY, maxY = floor(y / self.cellSize), floor((y + height) / self.cellSize)
    
    -- Gathering coordinates
    local cells = {}
    for i=minY, maxY do
        for j=minX, maxX do
            insert(cells, {x = j, y = i})
        end
    end
    return cells
end

-- Returns all cells a rectangle intersects with. Skips non existing cells.
function spatial:getCells(x, y, width, height)
    local cellCoordinates = self:getCellCoordinates(x, y, width, height)
    local cells = {}
    for i,v in ipairs(cellCoordinates) do
        if self.grid[v.y] then
            if self.grid[v.y][v.x] then
                insert(cells, self.grid[v.y][v.x])
            end
        end
    end
    return cells
end

-- Inserts "item" into the cell at cellX x cellY
-- Also creates the cell if it does not exist and checks for duplicates
-- Returns false in case of a dubplicate.
function spatial:addToCell(item, cellX, cellY)
    -- Making sure the cell exists
    self.grid[cellY] = self.grid[cellY] or {}
    self.grid[cellY][cellX] = self.grid[cellY][cellX] or {_CELL = {x = cellX, y = cellY}}

    -- Checking for dubplicates
    if contains(self.grid[cellY][cellX], item) then return false end

    --Inserting
    insert(self.grid[cellY][cellX], item)
    insert(item._SPATIAL.cells, self.grid[cellY][cellX])
    self.totalLength = self.totalLength + 1
end

-- Iterates over every item in every cell
function spatial:forEach(func)
    for y, col in pairs(self.grid) do
        for x, cell in pairs(col) do
            for index, item in pairs(cell) do
                func(item, self.grid[y][x], index)
            end
        end
    end
end

-- Makes sure a given filter exists.
function spatial:validateFilter(filter)
    filter = filter or "default"
    if type(filter) == "string" then
        assert(self.filters[filter], f("Invalid filter '%s'", filter))
        filter = self.filters[filter]
    elseif type(filter) == "function" then
        filter = filter
    else
        error(f("Invalid filter '%s'", tostring(filter)))
    end

    return filter
end

--:: PUBLIC METHODS ::--
-- Creates and returns a new instance
function spatial.new(cellSize)
    return setmetatable({
        cellSize = cellSize or 64,
        grid = {},
        length = 0, -- Number of items, not counting duplicates
        totalLength = 0 -- Total number of items, Including duplicates
    }, mt)
end

-- Adds a custom filter to the filters table
function spatial.newFilter(name, func)
    spatial.filters[name] = func
end

-- Inserts an item into the grid.
function spatial:insert(item, x, y, width, height)
    -- Getting cells
    local cells = self:getCellCoordinates(x, y, width or 1, height or 1)

    -- A _SPATIAL table is added to the item with useful stuff
    item._SPATIAL = {
        cells = {}, -- The cells the item lives in
        spatial = self
    }

    -- Inserting item into appropriate cells
    for i,v in ipairs(cells) do
        self:addToCell(item, v.x, v.y)
    end
    self.length = self.length + 1
    return item
end

-- Removes an item from the grid
function spatial:remove(item)
    local removed = false
    if item._SPATIAL then
        for _,cell in ipairs(item._SPATIAL.cells) do
            local exists, key = contains(cell, item)
            if exists then
                remove(cell, key)
                removed = true
                self.totalLength = self.totalLength - 1
            end
        end
    end
    if removed then
        self.length = self.length - 1
        return true
    end
end

-- Updates an items position on the grid.
function spatial:update(item, x, y, width, height)
    self:remove(item)
    self:insert(item, x, y, width, height)
end

--:: QUERY FUNCTIONS ::--
-- General query function. Returns every item that passes the filter
-- Unlike queryRect/queryPoint, This function has to iterate over every single item in the hash.
-- This can be slow if you have a large quantity of items in there.
function spatial:query(filter)
    filter = self:validateFilter(filter)
    local items, len = {}, 0
    self:forEach(function(item, x, y, i)
        if filter(item) then
            if not contains(items, item) then
                insert(items, item)
                len = len + 1
            end 
        end
    end)
    return items, len
end

--- Returns all the items in a rectangle
function spatial:queryRect(x, y, width, height, filter)
    filter = self:validateFilter(filter)
    local cells = self:getCells(x, y, width, height)
    local items, len = {}, 0

    for i,v in ipairs(cells) do
        for _, item in ipairs(v) do -- Looping through items
            if not contains(items, item) then -- Checking for duplicates
                if filter(item, x, y, width, height) then -- Checking if filter passes
                    insert(items, item)
                    len = len + 1
                end
            end
        end
    end

    return items, len
end

-- Returns all items in a point
function spatial:queryPoint(x, y, filter)
    return self:queryRect(x, y, 1, 1, filter)
end

return spatial