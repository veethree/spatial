# spacial.lua
Spacial.lua is a tiny spatial dictionary library for lua. It lets you create a fancy table that stores data organized by a 2d position.

# Usage
### `spatial.new(cell_size)`
Creates and returns a new spatial dictionary. 
* `cell_size`: the size of the cells spatial sorts your data into. It's pretty arbitrary. Defaults to 64.

### `spatial:insert(x, y, data)`
Inserts data into your dictionary. Returns the indices of the cell your data ended up in. 
* `x` & `y`: The position of your data
* `data`: Your data. 

### `spatial:remove(data, cell_x, cell_y)`
Removes `data` from your dictionary
* `data`: The data to be removed.
* `cell_x` & `cell_y`: The cell your data is stored in. These are optional, But if they're not provided it will search the whole dictionary, Which can be slow if it's large.

### `spatial:getRect(x, y, w, h)`
Returns
