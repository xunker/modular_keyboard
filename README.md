# modular_keyboard

### TODO

Now:
* Generate slots for Costar-style supports
* Ability to render single row
* Screw holes on bottom
* Generate bottom plate with screw holes
* Screw holes on top
* Generate top partial plate to fit between rows
* Add holes for adjustment feet
* Add openings on top row for wires to exit
* update Layout::Key#width and #height to also return MM
* Ability to set :unit_width and :unit_height in Layout#new instead of passing it explicitly to all methods
* Rounded corners
* Cut-back interior corners (like between sides of keyboard)

Later:
* Cherry-style supports
* channels for wires and sockets on bottom plate
* Ability to truncate row left or right at given column
* "blank space" option to have empty spots be printed
* Trap if json has switch manufacturer that is incompatible with current :unit_width and :unit_height
* Shorthand to set unit_width/height simply by setting switch manufacturer/brand/type on Layout#new?
* Add Layout::Keys#id (which is just string of "#{row}/#{column}"
* Replace Layout#find_key with Layout#keys.find(id)
* Ability to add large additional cutout for micro-controller
