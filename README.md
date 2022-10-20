# Spatial.lua
Spatial.lua is a spatial hasing library for lua.

## Basic usage
```lua 
spatial.new(cellSize)
```
Creates and returns a new spatial hash. 
* `cellSize`: the size of the cells spatial sorts your data into. It's pretty arbitrary. Defaults to 64.
## Inserting & removing items
```lua
spatial:insert(item, x, y, width, height)
```
Inserts an item into the hash. The item needs to be a table.

* `item`: The item to be inserted into the hash.
* `x, y, width, height`: The bounding box for the item.

A table with the key `_SPATIAL` will be added to any item inserted into the hash. The table contains the following keys:
* `cells`: A table of references to the cells the item is placed in.
* `spatial`: A reference to the spatial module
```lua
spatial:remove(item)
```
Removes `item` from your database.
* `item`: The item to be removed.

```lua
spatial:update(item, x, y, width, height)
```
Updates the bounding box for `item`. This should be called everytime an item in your game moves.
* `item`: A reference to your item
* `x, y, width, height`: The new bounding box for your item.

## Querying the database 
```lua
spatial:queryRect(x, y, width, height, filter)
```
Returns a list of items in cells that intersect with a rectangle
* `x, y, width, height`: The bounding box for the query.
* `filter`: An optional filter function.
```lua
spatial:queryPoint(x, y, filter)
```
Same as `spatial:queryRect`, But for a point. Internally, It actually just calls `spatial:queryRect()` with a width and height of 1.
```lua
spatial:query(filter)
```
Retrns a list of all items in the hash, Optionally filtered by a filter function.
## About filters
A filter is a function that gets called for every item in a query. If it returns true, The item will be returned. Otherwise its omitted.
The filter is called with the following arguments:
* `item`: A reference to the item being filtered
* `x, y, width, height`: The bounding box of the query

Spatial comes with 2 built in filters, "default" and "rect".
* `"default"` just returns true, Therefore it doesn't actually filter anything. This filter is used by default if one isn't provided
* `"rect"` will only return items that actually intersect with the query rectangle. For it to work the items must have x, y, width and height values in the root of the table.

```lua
-- This filter would only return items that have a "type" key, And its set to "tile"
local filter = function(item)
  return item.type == "tile"
end

-- This filter would only return items with "type" set to "monster" and "alive" set to true
local filter = function(item)
  if item.type == "monster" and item.alive then
    return true
  end
end
```
## Internal methods
Spatial.lua has a few methods it uses internally, But they're also available to the user.
```lua
spatial:getCells(x, y, width, height)
```
Returns a list of cells that intersect with a rectangle
```lua
spatial:for_each(func)
```
Calls a function on each item in the database. `func` gets passed the following arguments:
* `item`: The current item.
* `cell_x` & `cell_y`: The cell `item` is in.
* `index`: The `item` index within the cell.
```lua
spatial:length()
```
Returns the number of items currently in the database.
## Demo
The demo is made with [löve](https://love2d.org/). It creates 1.000.000 objects randomly scattered across a large area, And uses Spatial.lua to draw only the ones visible on the screen.


![Demo gif](https://github.com/veethree/spatial/blob/main/Demo/demo_gif.gif)

## How does it work?
The spatial database is essentially just a 2d table. Well *technically* 3d, But i prefer to think of it as 2d. It looks *something* like this:
```lua
table = {
    row = {cell = {}, cell = {}, cell = {}},
    row = {cell = {}, cell = {}, cell = {}},
    row = {cell = {}, cell = {}, cell = {}},
}
```

When you insert an item into a database, You specify a position.
```lua
data:insert(x, y, myItem)
```
Then Spatial, Based on the position will figure out which "cell" the item should be put into like so:
```lua
cell_x = floor(x / cell_size)
cell_y = floor(y / cell_size)
```
`cell_x` & `cell_y` are the row and column of the 2d table. So they act like coordinates for the cell the item should be added into. Then your item is added to that cell.


Then when you query the database with `queryRect`, Spatial will convert the 4 corners of the rectangle you specified to cell coordinates, And then it can iterate over just the cells that intersect with the rectangle, And collect all the items from those cells into a table, And thats the table it returns.
Internally, `queryPoint` actually just calls `queryRect` with a width and height of 1.

The `query` function will iterate over all the cells in the table, So it can be a bit slower if you have a large database.

# So what is it useful for?
Spatial was designed with games in mind. You can use it for the common task of only rendering and/or updating things that are currently on the screen.

If you imagine a game like terraria, You have a large world that extends way beyond the limits of your screen. And if you tried to render and update all that stuff every frame, You would get one frame per week. But if you use Spatial you can put all your tiles, monsters, entities and whatever else you have in your game world into a spatial database, And when it comes time to render/update, You query the database with a rectangle at the position of your camera, with the width/height of your window and just render/update those things. That's literally what the demo is doing.
