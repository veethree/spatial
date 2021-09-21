# Spatial.lua
Spatial.lua is a tiny spatial database library for lua.

# Creating a database
### `spatial.new(cell_size)`
Creates and returns a new spatial database. 
* `cell_size`: the size of the cells spatial sorts your data into. It's pretty arbitrary. Defaults to 64.
# Inserting & removing items
### `spatial:insert(x, y, item)`
Inserts data into your database. Returns a reference to your data.
* `x` & `y`: The position of your data
* `item`: The item you want to insert into the database. Can be anything.
### `spatial:remove(item)`
Removes `item` from your database.
* `item`: The item to be removed.
# Querying the database 
### `spatial:queryRect(x, y, w, h, filter)`
Returns a list of items from cells that intersect with a rectangle
* `x, y, w, h`: The rectangle to query by
* `filter`: An optional filter function. The function is called with the item as an argument. If the function returns true, The item is included in the list.
### `spatial:queryPoint(x, y, filter)`
Same as `spatial:queryRect`, But for a point. Internally, It actually just calls `spatial:queryRect()` with a width and height of 1.
### `spatial:query(filter)`
Retrns a list of all items in the database, Optionally filtered by a filter function.
