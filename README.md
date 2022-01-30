# Spatial.lua
Spatial.lua is a tiny spatial database library for lua.

## Creating a database
```lua 
spatial.new(cell_size)
```
Creates and returns a new spatial database. 
* `cell_size`: the size of the cells spatial sorts your data into. It's pretty arbitrary. Defaults to 64.
## Inserting & removing items
```lua
spatial:insert(x, y, item)
```
Inserts data into your database. Returns a reference to your data.

* `x` & `y`: The position of your data
* `item`: The item you want to insert into the database. Can be anything.

If `item` is a table, A table will be added to it called `_SPATIAL`.
The `_SPATIAL` table has the following things:
* `spatial`: A reference to the database the item is in
* `cell_x` & `cell_y`: The coordinates for the cell the item lives in
* `cell`: A reference to the cell the item lives in.
```lua
spatial:remove(item)
```
Removes `item` from your database.
* `item`: The item to be removed.

```lua
spatial:update_item_cell(x, y, item)
```
Moves the given item to an appropriate cell. You must call this for every item in your world that moves in order for things
to work right. If you don't, The item will always be in its initial cell.
* `x` & `y`: The position of your item
* `item´: A reference to your item

## Querying the database 
```lua
spatial:queryRect(x, y, w, h, filter)
```
Returns a list of items from cells that intersect with a rectangle
* `x, y, w, h`: The rectangle to query by
* `filter`: An optional filter function. 
```lua
spatial:queryPoint(x, y, filter)
```
Same as `spatial:queryRect`, But for a point. Internally, It actually just calls `spatial:queryRect()` with a width and height of 1.
```lua
spatial:query(filter)
```
Retrns a list of all items in the database, Optionally filtered by a filter function.
## About filters
A filter is a function that gets called for every item in a query. It will be called with the following arguments:
* `item`: A reference to the item
* `cell_x` & `cell_y`: The cell the item lives in.
* `index`: The index the item has in the cell

If the function returns true (Or any *truthy* value) the item will be included in the query, Otherwise it's omitted.

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
spatial:to_grid(x, y)
```
Converts coordinates to grid coordinates.
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
