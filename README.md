# Spatial.lua
Spatial.lua is a spatial hashing library for lua

## Basic usage
```lua
spatial = require "spatial"
myStuff = spatial()
myThing = {x = 0, y = 0, width = 32, height = 32, color = {0, 1, 1}}
myStuff:insert(myThing, myThing.x, myThing.y, myThing.width, myThing.height)

local someOfMyStuff, len = myStuff:queryRect(0, 0, 800, 600)
```

## Reference
### Creating a spatial hash
```lua
myHash = spatial.new(cellSize)
```
or
```lua
myHash = spatial(cellSize)
```
* `cellSize` is the size of the cells in the underlying grid. The default is 64.

Returns a spatial hash object.

### Adding, Removing and managing items
```lua
myHash:insert(item, x, y, width, height)
```
* `item` must be a table.
* `x`, `y`, `width`, `height`: The bounding box for the item

Returns `item`.
```lua
myHash:remove(item)
```
* `item`: Reference to the item to be removed.

Return `true` if an item was removed.
```lua
myHash:update(item, x, y, width, height)
```
* `item`: Reference to the item to be removed.
* `x`, `y`, `width`, `height`: The new bounding box for the item.

You should call this every time an item in your game moves.
### Querying the hash
To get items back out of the has, You need to query it. Spatial.lua has 3 (technically speaking 2) methods for this.
```lua
myHash:queryRect(x, y, width, height, filter)
```
This is the main querying function. It will return a list of all items in cells that intersect with a rectangular area.
* `x`, `y`, `width`, `height`: The rectangle for the query
* `filter`: A function to filter the resulting list, Can be `"default"`, `"rect"` or your own filter function. If omitted defaults to `"default"` 
```lua
myHash:queryPoint(x, y, filter)
```
Internally this is just a shorthand for `queryRect(x, y, 1, 1)`. 
```lua
myHash:query(filter)
```
This is the slowest query function, If you have a large amount of items in your hash i'd avoid it. If no filter is provided, It will return every item currently in the hash.
### About filter functions
Spatial.lua has 2 built in filter functions.
* `"default"`: This is the default one. It just returns true. Therefore it doesn't actually filter anything.
* `"rect"`: Only returns items that actually intersect with the query rectangle. For it to work your items need to have the following values in the root of the item table: `x`, `y`, `width`, `height` 

You can also provide your own filter function. The filter function is called for every item a query would return. The item will only be added to the list if the filter function returns true. The filter function is called with the following arguments
```lua
filter(item, x, y, width, height)
```
where `x`, `y`, `w`, `h` refer to the query rectangle, And `item` refers to the current item.
## Other stuff
### `_SPATIAL` table
Spatial.lua adds a table to every item added to the hash called `_SPATIAL`. It contains the following:
* `cells`: A list of references to cells where the item exists. (items can exist simultaneously in multiple cells, But duplicates are filtered out in queries)
* `spatial`: A reference to the spatial module
### Adding custom filters
You can add your own filters to Spatial.lua's internal filter list via this function
```lua
spatial:newFilter(name, filter)
```
where `name` is a string used to refer to the filter in queries, and `filter` is the function.
### Internal functions
Spatial has some functions it uses internally. You can use them too if you really want.
```lua
myHash:getCells(x, y, width, height)
```
returns a list of cells that intersect with a rectangle. The cells are simple lists of items.
```lua
cell = {
  item1,
  item2,
  -- etc...
}
```

```lua
myHash:addToCell(item, cellX, cellY)
```
Adds `item` to a cell at `cellX` x `cellY`. Also creates the cell if it does not exist yet.

```lua
myHash:forEach(func)
```
Calls function `func` for each item in the hash. `func` is called with the follwing arguments:
* `item`: The current item.
* `cell`: The cell the item is in.
* `index`: The items index in its cell
* 
Note that this function does not account for duplicates. So if an item exists in say 3 cells, `func` will be called 3 times for that item.
