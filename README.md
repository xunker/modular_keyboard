# modular_keyboard

### TODO

Now:
* Add additional top plate screw holes where unit length is more than 1.0
* Add holes for adjustment feet
* round corners of top connector
* build/find adjustment feet

Later:
* different stabilizer pattern for standard-length space bars
* Fix switch hole corner cutouts
* Cherry-style stabilizers
* channels for wires and sockets on bottom plate
* Ability to truncate row left or right at given column
* "blank space" option to have empty spots be printed
  * option to have offset between keys automatically filled?
  * option to have keyboard width be set to width of longest row?
* switches that are offset on Y-axis (like the num-ad enter key)
* ISO-style enter key support
* Trap if json has switch manufacturer that is incompatible with current :unit_width and :unit_height
* Shorthand to set unit_width/height simply by setting switch manufacturer/brand/type on Layout#new?
* Add Layout::Keys#id (which is just string of "#{row}/#{column}"
* Replace Layout#find_key with Layout#keys.find(id)
* Ability to add large additional cutout for micro-controller
