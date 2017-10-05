# modular_keyboard

### TODO

Now:
* Add additional top plate screw holes where unit length is more than 1.0
* round corners of top connector
* option to "conicalize" screw holes (make them conical so screws don't strip out as easily)
* add foot mount screw holes to keyboard as well, so longer screws will work
* lengthen foot attachment plate so screw heads won't get in the way of leg screws


Later:
* Read all settings from config file
* option to read json filename from command line
* option to read *all* settings from command line?
* option to print out all current settings to stdout from command line

* option to render multiple contiguous rows at once, in connected blocks (e.g. just rows 0-2, 3-4) with correct corner rounding and option to trim edges

* different stabilizer pattern for standard-length space bars

* Ability to truncate row left or right at given column
* "blank space" option to have empty spots be printed
  * option to have offset between keys automatically filled?
  * option to have keyboard width be set to width of longest row?

* Convert layout.rb to stand-alone gem
* Add Layout::Keys#id (which is just string of "#{row}/#{column}"
* Replace Layout#find_key with Layout#keys.find(id)
* Ability to add large additional space/cutout for micro-controller
* Option to add top "surround" in place of top connector when not rendering specific rows

Much Later:
* Support asymetrical switch sizes (alps, for example)
* Support Cherry-ML switches, where locking notch needs to be left-right instead of top-bottom
* Shorthand to set unit_width/height simply by setting switch manufacturer/brand/type on Layout#new?
* Trap if json has switch manufacturer that is incompatible with current :unit_width and :unit_height
* channels for wires and sockets on bottom plate
* set various thicknesses based on layer height (looking at you, bottom plate countersinks!)
* set various widths based on nozzle width (not sure when where this will be used, though)
* Fix switch hole corner cutouts (not even needed now? cherry switches fit smoothly without)
* Cherry-style stabilizers
* ISO-style enter key support
* switches that are offset on Y-axis (like the num-ad enter key)
