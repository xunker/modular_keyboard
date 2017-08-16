# modular_keyboard

### TODO

Now:
* Screw holes on bottom
* Screw holes on top
* Generate bottom plate with screw holes
* Generate top partial plate to fit between rows
* Ability to render single row
* Add holes for adjustment feet
* Add openings on top row for wires to exit
* update Layout::Key#width and #height to also return MM
* Rounded corners
* Cut-back interior corners (like between sides of keyboard)

Later:
* Cherry-style stabilizers
* channels for wires and sockets on bottom plate
* Ability to truncate row left or right at given column
* "blank space" option to have empty spots be printed
* Trap if json has switch manufacturer that is incompatible with current :unit_width and :unit_height
* Shorthand to set unit_width/height simply by setting switch manufacturer/brand/type on Layout#new?
* Add Layout::Keys#id (which is just string of "#{row}/#{column}"
* Replace Layout#find_key with Layout#keys.find(id)
* Ability to add large additional cutout for micro-controller
