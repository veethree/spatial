-- spatial.lua - A minimal spacial dictionary for lua
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

----------<< PUBLIC METHODS >>----------

-- Creates & returns a new dictionary
function spatial.new(cell_size)
    cell_size = cell_size or 64
    return setmetatable({
        cell_size = cell_size,
        grid = {}
    }, spatial_meta)
end

-- Inserts data inro the dictionary.
function spatial:insert(x, y, data)
    local cell_x, cell_y = self:to_grid(x, y)
    data = data or false
    
    self.grid[cell_y] = self.grid[cell_y] or {}
    self.grid[cell_y][cell_x] = self.grid[cell_y][cell_x] or {}
    insert(self.grid[cell_y][cell_x], data)
    return cell_x, cell_y
end

-- Removes data from the dictionary.
-- If cell_x and cell_y isn't provided, It will search through the whole dictionary
-- which can be slow if it's large.
-- Returns true if the item was sucessfully removed, And false and an error message if not.
function spatial:remove(data, cell_x, cell_y)
    if cell_x and cell_y then
        if not self.grid[cell_y][cell_x] then return false, f("Cell '%dx%d' is empty.", cell_x, cell_y) end
        for i, cell_data in pairs(self.grid[cell_y][cell_x]) do
            if cell_data == data then
                remove(self.grid[cell_y][cell_x], i)
                return true
            end
        end
        return false, f("Cell '%dx%d' doesn't contain this item.", cell_x, cell_y)
    else
        self:for_each(function(cell_data, cell_x, cell_y, i) 
            if cell_data == data then
                remove(self.grid[cell_y][cell_x], i)
                return true
            end
        end)
        return false, "Item not found."
    end
end

-- Returns all cells inside the specified rectangle
function spatial:getRect(x, y, w, h)
    local start_x, start_y = self:to_grid(x, y)
    local end_x, end_y = self:to_grid(x + w, y + h)
    local data, len = {}, 0

    for y = start_y, end_y do
        for x = start_x, end_x do
            if not self.grid[y] then break end
            if self.grid[y][x] then
                for _, cell_data in pairs(self.grid[y][x]) do
                    insert(data, cell_data)
                    len = len + 1
                end
            end
        end
    end
    return data, len, start_x, start_y
end

-- Returns the cell at the specified point
function spatial:getPoint(x, y)
    return self:getRect(x, y, 1, 1)
end

-- Collects all data into a table and returns it
function spatial:getAll()
    local data, len = {}, 0
    self:for_each(function(cell_data)
        insert(data, cell_data)
        len = len + 1
    end)
   
    return data, len
end

return spatial