class Keyboard < CrystalScad::Printed
  skip :output

	def initialize()
		# # Here is a good place to define instance variables that make your part parametric.
		# # These variables are acessable from outside:
		# @x = 25
		# @y = 25
		# @z = 20
		# @hardware = []
		# @color = "BurlyWood"
    #
		# # The variable below is not accessable from the outside unless you specify so with attr_accessable
		# @diameter = 10

    @ff = 0.1

    @unit = 19.05 # cherry mx
    @switch_cutout = 14 # cherry mx

    @plate_mount_t = 1.3

    @undermount_t = 7.0

    @wiring_channel_d = 6
    @x_wiring_channel_offset = unit/4
    @y_wiring_channel_offset = unit/3
	end

	def part(show)
    # cherry_mx
    # socket
    # socket_with_switch
    # plate_unit
    # plate_with_undermount
    # complete_unit

    mgr = Layout.new(filename: './recycler_right.json')
    # mgr = Layout.new(filename: './recycler_left.json')
    # mgr = Layout.new(filename: './recycler.json')
    layout = []
    mgr.rows.each_with_index do |row, row_index|
      layout[row_index] = []
      row.keys.each_with_index do |key, key_index|
        layout[row_index][key_index] = [key.row_offset, key.width]
      end
    end

    puts "width in units: #{mgr.width(as: :units)}, width in mm: #{mgr.width(as: :mm, unit_width: 19.05)}"
    puts "height in units: #{mgr.height(as: :units)}, height in mm: #{mgr.height(as: :mm, unit_height: 19.05)}"
    rows = mgr.height
    columns = mgr.width
    output = nil

    unconnected = {}

    columns.times do |column|
      rows.times do |row|
        unconnected[row] ||= []
        next unless layout[row][column]
        unconnected[row] << column
        key = mgr.find_key(row, column)
        output += complete_unit(width: layout[row][column][1].to_f, options: {no_left_channel: key.first?, no_right_channel: key.last?}).translate(x: (layout[row][column][0]*@unit), y: (-@unit*row), z: 0)
      end
    end



    columns.times do |column|
      puts "column: #{column}"
      rows.times do |row|
        puts "row: #{row}"
        next unless layout[row][column]

        adjacent = nil
        adj_distance = nil
        adj_idx = nil
        # find closest on next row
        p1 = {
          x: (layout[row][column][0]*@unit)+((layout[row][column][1]*@unit)/2),
          y: (-@unit*row.to_f)-(@unit/2)+@unit
        }
        if layout[row+1]
          layout[row+1].each_with_index do |adj_col, idx|
            p2 = {
              x: (adj_col[0]*@unit)+((adj_col[1]*@unit)/2),
              y: (-@unit*((row+1).to_f))-(@unit/2)+@unit
            }

            len = Math.sqrt( ((p1[:x]-p2[:x]).to_i**2) + ((p1[:y]-p2[:y]).to_i**2) )
            if !adj_distance || len < adj_distance
              adjacent = adj_col
              adj_distance = len
              adj_idx = idx
            end

          end
        end

        # if layout[row+1] && layout[row+1][column]
        #   adjacent = layout[row+1][column]
        # elsif layout[row+1] && layout[row+1][column-1]
        #   adjacent = layout[row+1][column-1]
        # end

        next unless adjacent
        unconnected[row+1].delete(adj_idx) if unconnected[row+1]

        puts "current"
        puts layout[row][column].inspect
        puts "adjacent:"
        puts adjacent.inspect

        p1 = {
          x: (layout[row][column][0]*@unit)+((layout[row][column][1]*@unit)/2),
          y: (-@unit*row.to_f)-(@unit/2)+@unit
        }

        p2 = {
          x: (adjacent[0]*@unit)+((adjacent[1]*@unit)/2),
          y: (-@unit*((row+1).to_f))-(@unit/2)+@unit
        }

        puts "p1: #{p1.inspect}"
        puts "p2: #{p2.inspect}"

        angle = Math.atan2(p2[:x] - p1[:x], p2[:y] - p1[:y]) * 180 / Math::PI

        puts "angle: #{angle}"


        # output += sphere(d: 3, fn: 6).translate(x: p1[:x], y: p1[:y])
        # output += sphere(d: 3, fn: 6).translate(x: p2[:x], y: p2[:y], z: 10)

        len = Math.sqrt( ((p1[:x]-p2[:x]).to_i**2) + ((p1[:y]-p2[:y]).to_i**2) )

        output -= cylinder(h: len, d: wiring_channel_d, fn: 4).rotate(x: -90, z: -angle).translate(x: p1[:x], y: p1[:y])
        #  output += cube(x: 1, y: @unit*3, z: 1).translate(v: [-0.5, 0, -0.5]).rotate(z: -angleDeg).translate(x: p1[:x], y: p1[:y])

      end
    end

    unconnected.each do |row, cols|
      next if row == 0
      cols.each do |column|
        p1 = {
          x: (layout[row][column][0]*@unit)+((layout[row][column][1]*@unit)/2),
          y: (-@unit*row.to_f)-(@unit/2)+@unit
        }
        # puts p1.inspect
        # output += sphere(d: 5, fn: 6).translate(x: p1[:x], y: p1[:y], z: 10)

        adjacent = nil
        adj_distance = nil
        adj_idx = nil
        # find closest on PREVIOUS row

        if layout[row-1]
          layout[row-1].each_with_index do |adj_col, idx|
            p2 = {
              x: (adj_col[0]*@unit)+((adj_col[1]*@unit)/2),
              y: (-@unit*((row-1).to_f))-(@unit/2)+@unit
            }

            len = Math.sqrt( ((p1[:x]-p2[:x]).to_i**2) + ((p1[:y]-p2[:y]).to_i**2) )
            if !adj_distance || len < adj_distance
              adjacent = adj_col
              adj_distance = len
              adj_idx = idx
            end

          end
        end

        next unless adjacent

        puts "current"
        puts layout[row][column].inspect
        puts "adjacent:"
        puts adjacent.inspect

        p1 = {
          x: (layout[row][column][0]*@unit)+((layout[row][column][1]*@unit)/2),
          y: (-@unit*row.to_f)-(@unit/2)+@unit
        }

        p2 = {
          x: (adjacent[0]*@unit)+((adjacent[1]*@unit)/2),
          y: (-@unit*((row+1).to_f))-(@unit/2)+@unit
        }

        puts "p1: #{p1.inspect}"
        puts "p2: #{p2.inspect}"

        angle = Math.atan2(p2[:x] - p1[:x], p2[:y] - p1[:y]) * 180 / Math::PI

        puts "angle: #{angle}"


        # output += sphere(d: 3, fn: 6).translate(x: p1[:x], y: p1[:y])
        # output += sphere(d: 3, fn: 6).translate(x: p2[:x], y: p2[:y], z: 10)

        len = Math.sqrt( ((p1[:x]-p2[:x]).to_i**2) + ((p1[:y]-p2[:y]).to_i**2) )

        output -= cylinder(h: len, d: wiring_channel_d, fn: 4).rotate(x: 90, z: angle).translate(x: p1[:x], y: p1[:y])
      end
    end

    legends = nil
    columns.times do |column|
      # puts "column: #{column}"
      rows.times do |row|
        # puts "row: #{row}"
        next unless layout[row][column]

        legends += text(text: layout[row][column][2], size: 5).translate(x: (layout[row][column][0]*@unit)+layout[row][column][1]*(@unit/2)-(@switch_cutout/3), y: (-@unit*row)+(@unit/4), z: undermount_t)
      end
    end

    output += legends.background
    puts unconnected.inspect
    output.translate(v: [0, (rows-1)*@unit, 0])


  end

  def cherry_mx
    fn = 60
    #
    # a cherry mx switch.
    #
    # most of the measurements done with a caliper. some taken from
    # http://geekhack.org/index.php?topic=47744.0
    #
    # This is just to illustrate and to drop in a a gross reference. It is mostly artistic apart from the steam and mounting plate dimensions

    switch = nil

    # 1. steam

  	# 1.1. l-r tab is 1.35mm
  	stem = (
      cube(x: 1.35, y: 4.5, z: 3.62).center.translate(v: [0,0,-3.62/2]) +

    	# 1.2. f-b tab is 1.15mm. it has a smal notch that i will ignore.
    	cube(x: 4.5, y: 1.15, z: 3.62).center.translate(v: [0,0,-3.62/2]) +

    	# 1.3. base. it has a chamfered top that i will ignore.
    	cube(x: 7.2, y: 5.56, z: 4).center.translate(v: [0,0,-5.62])
    ).color("brown")
    switch += stem

  	# 2. top
  	top = (
  		# make a trapezoid with the general shape (volume?) of the top
  		hull(
  				cube(x: 9.87, y: 10.62, z: 0.1).center.translate(v: [0,0,-4]), #distance from top of switch... some i measured 3.9 others 4.2... so leaving at 4
  				cube(x: 14.58, y: 14.58, z: 0.1).center.translate(v: [0,0,-4 -5.2]) # bottom has a measured 5.3... so move 5.2 and use the 0.1 bellow
  		) - (

  		# and subtract:
  		# the front led. NOTE: totally off... measured by eye. just for astetics
  		# adding just so there is a visual cue of the direction
  		cylinder(r: 3/2, h: 6, center: true, fn: fn).translate(v: [0,-4.7,-6]) + cube(x: 8, y: 4, z: 5).center.translate(v: [0,-5.5,-6])
  	  # the four corners
  		# TODO waste of time? this is all for looks, you shouldn't invade any of that space anyway...
      )
  	).color("grey")

    switch += top

  	# 3. bottom
  	bottom = (
  		# 3.1 main body volume
  		hull(
  				cube(x: 13.98,y: 13.98, z: 0.1).center.translate(v: [0,0,-4 -5.3]), #steam + top
  				cube(x: 13.98,y: 13.98, z: 0.1).center.translate(v: [0,0,-4 -5.3 -2.2]), #steam + top + straigth part
  				cube(x: 12.74,y: 13.6, z: 0.1).center.translate(v: [0,0,-4 -5.3 -5.5]) #steam + top + bottom (measured 5.5)
  		).color("green") +

  		# 3.2 tabs
  		# note: only measured the lenght, if they are slightly off-center, this will be all wrong :)

      (
    		cube(x: 15.64,y: 15.64, z: 0.82).center.translate(v: [0,0,-4 -5.3 -0.82/2]) - #steam + top
    		cube(x: 5.64, y: 20, z: 0.82 +2).center.translate(v: [0,0,-4 -5.3 -0.82/2  ]) - # front-back cut
    		cube(x: 20, y: 11.64, z: 0.82 +2).center.translate(v: [0,0,-4 -5.3 -0.82/2  ]) #side cut
      ).color("black") +


  		# 3.3 tab (plate snap on). to use this mechanically, you have to take into account the bending (as it will move the bottom part slightly up...) just for gross reference here for now
  		(
  			# 3.3.1 top
  			cube(x: 1.82, y: 16.33, z: 0.82).center.translate(v: [0,0,-4 -5.3 -0.82/2  ]) + # front-back cut

  			# 3.3.2 bottom
  			(
  				hull(
  					cube(x: 3.65, y: 14, z: 0.1).center.translate(v: [0,0,-4 -5.3 -0.82/2 -1.76  ]), # front-back cut
  					cube(x: 3.65,y: 14.74, z: 0.1).center.translate(v: [0,0,-4 -5.3 -0.82/2 -2.2  ]), # front-back cu
  					cube(x: 3.65, y: 14, z: 0.1).center.translate(v: [0,0,-4 -5.3 -0.82/2 -2.89  ]) # front-back cut

  				) -
  				cube(x: 2.2, y: 20,z: 4).center.translate(v: [0,0,-4 -5.3 -0.82/2 -1.76   ]) # front-back cut
        )
  		).color("white")
    )
    switch += bottom

    # 4. bottom guides
  	# again, i'm assuming everything is centered...
  	bottom_guides = (
  			# 4.1 cylinder
  			cylinder(r: 3.85/2, h: 2, center: true, fn: fn).translate(v: [0,0,-4 -5.3 -5.5 -2/2]) + #steam + top + bottom (measured 5.5)
  			cylinder(r2: 3.85/2, r: 2.8/2, h: 1, center: true, fn: fn).translate(v: [0,0,-4 -5.3 -5.5 -2 -1/2]) + #steam + top + bottom (measured 5.5)
  			# 4.2 PCB pins
  			cylinder(r: 1.6/2, h: 2, center: true, fn: fn).translate(v: [4.95,0,-4 -5.3 -5.5 -2/2]) + #steam + top + bottom (measured 5.5)
  			cylinder(r2: 1.6/2, r: 1/2, h: 1, center: true, fn: fn).translate(v: [4.95,0,-4 -5.3 -5.5 -2 -1/2]) + #steam + top + bottom (measured 5.5)
  			cylinder(r: 1.6/2, h: 2, center: true, fn: fn).translate(v: [-4.95,0,-4 -5.3 -5.5 -2/2]) + #steam + top + bottom (measured 5.5)
  			cylinder(r2: 1.6/2, r: 1/2, h: 1, center: true, fn: fn).translate(v: [-4.95,0,-4 -5.3 -5.5 -2 -1/2]) #steam + top + bottom (measured 5.5)
  	).color("darkGreen")
    switch += bottom_guides

  	# 5. pins
  	pins = (
  		cube(x: 0.86, y: 0.2, z: 3.1).center.translate(v: [-3.77,2.7,-4 -5.3 -5.5 -3.1/2]) + #steam + top + bottom (measured 5.5)

  		cube(x: 0.86, y: 0.2, z: 3.1).center.translate(v: [2.7,5.2,-4 -5.3 -5.5 -3.1/2]) #steam + top + bottom (measured 5.5)

  	).color("orange")
    switch += pins


    # move the whole thing 3mm to give the empty space in usual keycaps.
    # that is, the extra space inside a keycap female connector.
    # i do that since i create all my keycaps with 0,0,0 being the internal base of the keycap
    switch.translate(v: [0,0,-3])

  end

  def socket
    def solder_tab
      cube(x: 2, y: 2, z: 1.75)
    end


    s = cube(x: 10.9, y: 5.5, z: 1.75) - cube(x: 10.9-3.65+@ff, y: 1.5+@ff, z: 1.75+(@ff*2)).translate(x: 3.65, y: -@ff, z: -@ff)


    s += solder_tab.translate(x: -2, y: 1, z: 0)

    s +=  solder_tab.translate(x: 10.9, y: (5.5-1.5)-1, z: 0)

    s +=  cylinder(d: 2.88, h: 1, fn: 12).translate(x: 2, y: 1.75, z: 1.75)

    s +=  cylinder(d: 2.88, h: 1, fn: 12).translate(x: 9, y: 3.75, z: 1.75)
    s
  end

  def socket_with_switch
    socket + cherry_mx.translate(v: [6,-1,20.75])
  end

  # width is multiples of unit
  def plate_unit(width: 1)
    space_width = @unit * width

    # cherry_mx().translate(v: [(unit)/2, (unit)/2, -ff]).translate(v: [-0,0,14.2+0.35]) +
    (
      cube(x: space_width, y: @unit, z: @plate_mount_t) -
      cube(x: @switch_cutout, y: @switch_cutout, z: @plate_mount_t+(@ff*2)).translate(v: [(space_width-@switch_cutout)/2, (@unit-@switch_cutout)/2, -@ff])
    )
  end

  # width is multiples of unit
  def plate_with_undermount(width: 1)
    space_width = @unit * width
    # the inward curve can begin as soon as plate_unit() ends.

    # "under pocket" is a space for the clips on the underside of the plate
    under_pocket_d = 1.25
    under_pocket_l = switch_cutout

    plate_unit(width: width).translate(v: [0,0,@undermount_t])

    (
      cube(x: space_width, y: @unit, z: @undermount_t) -
      hull(
        cube(x: @switch_cutout, y: @switch_cutout, z: @plate_mount_t+@ff).translate(v: [0,0,@undermount_t-@plate_mount_t+@ff]),
        # translate offset below should be half of what is substracted from switch_cutout
        cube(x: @switch_cutout-2.5, y: @switch_cutout-0, z: @plate_mount_t).translate(v: [1.25,0.0,0])
      ).translate(v: [(space_width-@switch_cutout)/2, (@unit-@switch_cutout)/2, -@ff]) -

      (
        cylinder(d: under_pocket_d, h: under_pocket_l, fn: 12).rotate(x: 0, y: 90, z: 0).translate(v: [(space_width-@switch_cutout)/2, (@unit-@switch_cutout)/2, 0]) +
        cylinder(d: under_pocket_d, h: under_pocket_l, fn: 12).rotate(x: 0, y: 90, z: 0).translate(v: [(space_width-@switch_cutout)/2, ((@unit-@switch_cutout)/2)+@switch_cutout, 0])
      ).translate(v: [0,0,@undermount_t]).translate(v: [0,0,(-under_pocket_d/2)+0.0])
    )
    # ) * cube(x: space_width, y: @unit/2, z: @undermount_t).translate(v: [0, 0, 0])
    # ) * cube(x:  space_width, y: @unit/2, z: @undermount_t).translate(v: [0, @unit/2, 0])
    # ) * cube(x: space_width/2, y: @unit/2, z: @undermount_t).translate(v: [0, @unit/2, 0])
  end

  # width is multiples of unit
  def complete_unit(width: 1, options: {})
    space_width = @unit * width;
    obj = plate_with_undermount(width: width)
    # X wiring channel
    if options[:no_left_channel]
      obj -= cylinder(d: @wiring_channel_d, h: (space_width/2)+(@ff*2), fn: 4).translate(v: [0,0,(space_width/2)]).rotate(x: 0, y: 90, z: 0).translate(v: [0, @x_wiring_channel_offset,0])
      obj
    elsif options[:no_right_channel]
      obj -= cylinder(d: @wiring_channel_d, h: (space_width/2)+(@ff*2), fn: 4).translate(v: [0,0,-@ff]).rotate(x: 0, y: 90, z: 0).translate(v: [0, @x_wiring_channel_offset,0])
      obj
    else
      obj -= cylinder(d: @wiring_channel_d, h: space_width+(@ff*2), fn: 4).translate(v: [0,0,-@ff]).rotate(x: 0, y: 90, z: 0).translate(v: [0, @x_wiring_channel_offset,0])
    end

    # Y wiring channel
    # offset
    # obj -= cylinder(d: @wiring_channel_d, h: @unit+(@ff*2), fn: 18).rotate(x: 270, y: 0, z: 0).translate(v: [@y_wiring_channel_offset,0,0]).translate(v: [0,0,-@ff])
    # centered
    # obj -= cylinder(d: @wiring_channel_d, h: @unit+(@ff*2), fn: 18).translate(v: [0,0,-@ff]).rotate(x: 270, y: 0, z: 0).translate(v: [(space_width/2),0,0])
  end
end


# /*
# for (x=[0:2]) {
#   for (y=[0:2]) {
#     translate([unit*x,unit*y,0]) complete_unit();
#   }
# }*/
#
# module keyRow() {
#   for (x=[0:2]) {
#     translate([unit*x,0,0]) complete_unit();
#   }
# }
#
# module staggeredRows() {
#   keyRow();
#   translate([unit/4,unit,0]) keyRow();
#   translate([unit/1.5,unit*2,0]) keyRow();
# }
#
# /* These tabs look neat but won't work for an actual staggered and split keyboard */
# module complete_unit_with_v1_tabs() {
#
#   connector_screw_d = 2.1;
#   difference() {
#     union() {
#       complete_unit();
#       translate([unit/2, 0, undermount_t/2]) rotate([0, 90, 0]) scale([1.5,1.25,1]) cylinder(d=connector_screw_d*1.5, h=2, $fn=24);
#       translate([(unit/2)+2, unit, undermount_t/2]) rotate([0, 90, 0]) scale([1.5,1.25,1]) cylinder(d=connector_screw_d*1.5, h=2, $fn=24);
#     }
#
#     translate([0, 0, undermount_t/2]) {
#       rotate([0, 90, 0]) translate([0,0,-ff]) cylinder(d=connector_screw_d, h=unit+(ff*2), $fn=18);
#       rotate([0, 90, 0]) translate([0,unit,-ff]) cylinder(d=connector_screw_d, h=unit+(ff*2), $fn=18);
#       // cutout slightly bigger
#       translate([(unit/2)+2, 0, 0]) rotate([0, 90, 0]) scale([1.55,1.3,1.05]) cylinder(d=connector_screw_d*1.5, h=2, $fn=18);
#       translate([(unit/2), unit, 0]) rotate([0, 90, 0]) scale([1.55,1.3,1.05]) cylinder(d=connector_screw_d*1.5, h=2, $fn=18);
#     }
#   }
# }
#
# /*for (x=[0:2]) translate([unit*x,0,0])*/
#   /*complete_unit_with_v1_tabs();*/
#
# /*complete_unit(width=1);*/
#
# /* test of full keyboard */
# layout = [
#   [
#     [0, 1],
#     [1, 1],
#     [2, 1], // 2
#     [3, 1],
#     [4, 1],
#     [5, 1],
#     [6, 1], // 6
#   ],
#   [
#     [0, 1.5],
#     [1.5, 1],
#     [2.5, 1], // w
#     [3.5, 1],
#     [4.5, 1],
#     [5.5, 1], // t
#   ],
#   [
#     [0, 1.75],
#     [1.75, 1],
#     [2.75, 1], // s
#     [3.75, 1],
#     [4.75, 1],
#     [5.75, 1], // g
#   ],
#   [
#     [0, 2.25],
#     [2.25, 1],
#     [3.25, 1], // x
#     [4.25, 1],
#     [5.25, 1],
#     [6.25, 1],
#   ],
#   [
#     [0, 1],
#     [1, 1],
#     [2, 1.25], //  alt
#     [3.25, 1.25],
#     [4.5, 2.75], // space
#   ]
# ];
# rows = 5;
# columns = 6;
# translate([0, (rows)*unit, 0]) {
#   for(column=[1:columns]) {
#     for(row=[rows:1]) {
#       translate([(layout[row-1][column-1][0]*unit), -unit*row, 0]) complete_unit(width=layout[row-1][column-1][1]);
#       /*translate([0, -unit*row, 0]) complete_unit(width=layout[row][column][1]);*/
#     }
#   }
# }


		# # We start with a cube and center it in x and y direction. The cube starts at z = 0 with this.
		# res = cube(@x,@y,@z).center_xy
    #
		# # We want a bolt to go through it. It will be facing upwards however, so we will need to mirror it.
		# # Also translating it to twice the height, as we want to stack two of these cubes together in the assembly.
		# bolt = Bolt.new(4,40).mirror(z:1).translate(z:@z*2)
		# @hardware << bolt
    #
		# # We also want a nut. And since the printing direction is from the bottom, we decide to add support to it.
		# nut = Nut.new(4,support:true,support_layer_height:0.3)
		# @hardware << nut
    #
		# # substracting the @hardware array will call the .output method on each hardware item automatically
		# res -= @hardware
    #
		# # colorize is a convenience thing to colorize your part differently in assemblies.
		# # You can specify @color in initalize (as default color), or set a different color in the assembly this way.
		# res = colorize(res)
    #
		# # Note: Make sure you do this before adding parts (i.e. hardware) that have their own color and that
		# #				you do not want to colorize.
    #
		# # You can go ahead and show the hardware when the part produces its 'show' output file by uncommenting this:
		# #		res += @hardware if show
		# # However, in this example, the Assembly file calls show_hardware in order to not show it twice.
    #
		# # always make sure the lowest statement always returns the object that you're working on
		# res
	# end
# end
