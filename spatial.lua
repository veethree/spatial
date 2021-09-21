-- spatial.lua - A minimal spacial database for lua
-- Version 1.0
--
-- MIT License
-- 
-- Copyright (c) 2021 Pawel Þorkelsson
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

local spatial = {}
local spatial_meta = {__index = spatial}

-- Shorthands
local floor = math.floor
local insert = table.insert
local remove = table.remove
local f = string.format

----------<< LOCAL METHODS >>----------

local default_filter = function()
    return true
end

-- Returns the cell coordinates of x and y
function spatial:to_grid(x, y)
    return floor(x / self.cell_size)+1, floor(y / self.cell_size)+1
end

-- Iterates over every data point
function spatial:for_each(func)
    for y, col in pairs(self.grid) do
        for x, cell in pairs(col) do
            for i, cell_data in pairs(cell) do
                func(cell_data, x, y, i)
            end
        end
    end
end

function spatial:length()
    local len = 0
    self:for_each(function() len = len + 1 end)
    return len
end

----------<< PUBLIC METHODS >>----------

-- Creates & returns a new database
function spatial.new(cell_size)
    cell_size = cell_size or 64
    return setmetatable({
        cell_size = cell_size,
        grid = {},
        length = 0
    }, spatial_meta)
end

-- Inserts data inro the database.
function spatial:insert(x, y, item)
    local cell_x, cell_y = self:to_grid(x, y)
    item = item or false
    
    self.grid[cell_y] = self.grid[cell_y] or {}
    self.grid[cell_y][cell_x] = self.grid[cell_y][cell_x] or {}
    insert(self.grid[cell_y][cell_x], item)
    self.length = self.length + 1

    return item, cell_x, cell_y
end

-- Removes data from the database.
function spatial:remove(item)
    for i, cell_data in pairs(self.grid[cell_y][cell_x]) do
        if cell_data == item then
            remove(self.grid[cell_y][cell_x], i)
            self.length = self.length - 1
            return true
        end
    end
    return false
end

----------<< QUERYING METHODS >>----------

-- Returns all cells inside the specified rectangle
function spatial:queryRect(x, y, w, h, filter)
    filter = filter or default_filter
    local start_x, start_y = self:to_grid(x, y)
    local end_x, end_y = self:to_grid(x + w, y + h)
    local items, len = {}, 0

    for y = start_y, end_y do
        for x = start_x, end_x do
            if not self.grid[y] then break end
            if self.grid[y][x] then
                for _, cell_data in pairs(self.grid[y][x]) do
                    if filter(cell_data) then
                        insert(items, cell_data)
                        len = len + 1
                    end
                end
            end
        end
    end
    return setmetatable(items, spatial_meta), len, start_x, start_y
end

-- Returns the cell at the specified point
function spatial:queryPoint(x, y, filter)
    return self:queryRect(x, y, 1, 1, filter)
end

-- Collects all data into a table and returns it
function spatial:query(filter)
    filter = filter or default_filter
    local items, len = {}, 0
    self:for_each(function(cell_data)
        if filter(cell_data) then
            insert(items, cell_data)
            len = len + 1
        end
    end)
   
    return setmetatable(items, spatial_meta), len
end

----------<< MANIPULATION METHODS >>----------

-- This is an iterator, It returns the item and it's index, In that order.
-- If the list argument isn't provided, It will iterate over all the items.
function spatial:iter(list)
    local _list, length = self:query()
    list = list or _list
    local index = 0
    return function()
        index = index + 1
        
        if index <= length then
            return list[index], index
        end
    end
end


return spatial