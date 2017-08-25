# modular_keyboard

### TODO

Now:
* Add additional top plate screw holes where unit length is more than 1.0
* Generate bottom plate with screw holes
* Ability to render single row (Use intersection? What if I want the corners rounded?)
* Add holes for adjustment feet
* Add openings on top row for wires to exit
* Cut-back interior corners (like between sides of keyboard, or corners of switch cutout)
* different stabilizer pattern for space bar
* round corners of top connector

Later:
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
