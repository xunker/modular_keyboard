require "awesome_print"

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

    @stabilizer_spacing = 24 # 20.6 (20.5 measured)?
    @stabilizer_slot_width = 3.5 # 3.3 (3.5 measured)
    @stabilizer_slot_height = 14.0 # 14 (14 measured)
    @stabilizer_slot_depth = 1.0
    @stabilizer_y_offset = 0.5 # 0.75 is too far down, rubs

    @plate_mount_t = 1.6 # Cherry MX Brown
    # @plate_mount_t = 1.7 # Greetech Brown, measured
    # @plate_mount_t = 1.6 # Outemu, measured

    @undermount_t = 9.0

    @wiring_channel_d = 6
    @x_wiring_channel_offset = unit/3.5
    @y_wiring_channel_offset = unit/3

    @show_legends = false
	end

  def build_layout(mgr, render_row: nil)
    puts "keyboard width in units: #{mgr.width(as: :units)}, keyboard width in mm: #{mgr.width(as: :mm)}"
    puts "keyboard height in units: #{mgr.height(as: :units)}, keyboard height in mm: #{mgr.height(as: :mm)}"
    rows = mgr.height
    columns = mgr.width
    output = nil

    unconnected = {
      above: [],
      below: []
    }

    connected = {}

    # for deciding where the wire exits will be
    median_key_number = mgr.rows.first.keys.length/2

    mgr.keys.each do |key|
      unconnected[:above] << key unless key.row.first?
      unconnected[:below] << key unless key.row.last?
      # puts "x: #{key.x_position(as: :mm)}"
      # puts "y: #{key.y_position(as: :mm)}"
      next if render_row && key.row.number != render_row
      output += complete_unit(key,
        options: {
          stabilized: key.stabilized?,
          no_left_channel: key.first?,
          no_right_channel: key.last?,
          render_row: render_row,
          wire_exit: key.row.first? && (median_key_number-1..median_key_number+1).to_a.include?(key.number)
        }
      ).translate(x: key.x_position(as: :mm), y: key.y_position(as: :mm), z: 0)
    end

    # puts "Unconnected above: #{unconnected[:above].map(&:position).sort_by{|h| h[:y].to_s + h[:x].to_s}}"
    # puts "Unconnected below: #{unconnected[:below].map(&:position).sort_by{|h| h[:y].to_s + h[:x].to_s}}"
    # puts '---'

    mgr.keys.each do |key|
      adjacent_directions = []
      if !key.row.last?
        adjacent_directions << :below
      end
      if !key.row.first?
        adjacent_directions << :above
      end

      adjacent_directions.each do |adjacent_direction|
        adjacent = key.nearest_neighbor(adjacent_direction)

        next unless adjacent

        next if connected[key] == adjacent
        next if connected[adjacent] == key

        connected[key] = adjacent
        connected[adjacent] = key

        if adjacent_direction == :above
          unconnected[:above].delete(key)
          unconnected[:below].delete(adjacent)
        else
          unconnected[:above].delete(adjacent)
          unconnected[:below].delete(key)
        end

        distance = key.distance_to(adjacent)

        angle = key.angle_to(adjacent)

        # puts "x: #{key.x_position(as: :mm)}"
        # puts "y: #{key.y_position(as: :mm)}"

        # output += sphere(d: 3, fn: 6).translate(x: key.x_position(as: :mm)+((key.width(as: :mm))/2), y: key.y_position(as: :mm)+((key.height(as: :mm))/2), z: 10).color('blue')
        #
        # output += sphere(d: 3, fn: 6).translate(x: adjacent.x_position(as: :mm)+((adjacent.width(as: :mm))/2), y: adjacent.y_position(as: :mm)+((adjacent.height(as: :mm))/2), z: 15).color('orange')

        output -= cylinder(h: distance, d: @wiring_channel_d, fn: 4).rotate(x: -90, z: angle).translate(x: adjacent.x_position(as: :mm)+((adjacent.width(as: :mm))/2), y: adjacent.y_position(as: :mm)+((adjacent.height(as: :mm))/2))
      end
    end

    if @show_legends
      legends = nil
      mgr.keys.each do |key|
        # x_offset = key.x_position(as: :mm)+((key.width(as: :mm))/4)
        x_offset = (key.x_position(as: :mm)+(key.width(as: :mm)/2))-(@switch_cutout/3)
        legends += text(text: key.legend.to_s.gsub("\"", "Quote"), size: 3).translate(x: x_offset, y: key.y_position(as: :mm)+((key.height(as: :mm))/2), z: undermount_t)
      end

      output += legends.background
    end

    # bottom screw holes
    screw_d = 2
    screw_h = 3

    bottom_plate_hole_locations(mgr).each do |loc|
      output -= cylinder(d: screw_d, h: screw_h).translate(loc.merge(z: -@ff)).color('purple')
    end

    # top connector screw holes
    screw_d = 1.5
    screw_h = 2
    (mgr.rows.length+1).times do |row_number|
      # negative 1 (-1) is to get topmost row of holes.
      top_connector_hole_locations(mgr, row_number-1).each do |coords|
        output -= cylinder(d: screw_d, h: screw_h+@ff, fn: 12).translate(coords.merge(z: undermount_t-screw_h)).color('red')
      end
    end

    puts '---'
    puts "Unconnected above: #{unconnected[:above].map(&:position).sort_by{|h| h[:y].to_s + h[:x].to_s}}"
    puts "Unconnected below: #{unconnected[:below].map(&:position).sort_by{|h| h[:y].to_s + h[:x].to_s}}"
    puts "--- Complete at #{Time.now} --- "
    output
  end

  def top_connector(mgr, row)
    output = nil

    upper_switch_cutout = @switch_cutout+2
    # end_x_spacing = (@unit-@switch_cutout)/2
    connector_t = 1
    screw_d = 1.5

    upper_row = mgr.rows[row] unless row<0
    lower_row = mgr.rows[row+1] if mgr.rows[row+1]

    y_reduction = @unit/8
    connector = nil

    # Generate connector pieces for upper row
    if upper_row
      upper_row.keys.each do |key|
        unit_connector = cube(x: key.width(as: :mm), y: ((key.height(as: :mm))/2)-y_reduction, z: connector_t).translate(x: key.x_position(as: :mm), y: key.y_position(as: :mm), z: 0)

        unit_connector -= rounded_cube(x: upper_switch_cutout, y: upper_switch_cutout, z: connector_t+(@ff*2)).translate(x: key.x_position(as: :mm)+((key.width(as: :mm)-upper_switch_cutout)/2), y: key.y_position(as: :mm)+((@unit-upper_switch_cutout)/2), z: -@ff)

        connector += unit_connector

        if key.stabilized?
          # wider spaces to clear brackets
          stabilizer_slot_width = @stabilizer_slot_width*1.4
          stabilizer_slot_height = @stabilizer_slot_height*1.1

          x_center = ((key.width(as: :mm))/2)-(stabilizer_slot_width/2)
          y_center = (@unit/2)-(stabilizer_slot_height/2)

          connector -= rounded_cube(x: (stabilizer_slot_width) + @stabilizer_spacing, y: stabilizer_slot_height, z: connector_t+(@ff*2)).translate(x: (x_center+key.x_position(as: :mm))-(@stabilizer_spacing/2), y: y_center-(@stabilizer_y_offset/2), z: -@ff)
        end

        # IDEA: serpentine connector, where the screw hole alternates bewtween lower and upper
      end
    end

    if lower_row
      # Generate connector pieces for lower row
      lower_row.keys.each do |key|
        unit_connector = cube(x: key.width(as: :mm), y: ((key.height(as: :mm))/2)-y_reduction, z: connector_t).translate(x: key.x_position(as: :mm), y: key.y_position(as: :mm)+((key.height(as: :mm))/2)+y_reduction, z: 0)

        unit_connector -= rounded_cube(x: upper_switch_cutout, y: upper_switch_cutout, z: connector_t+(@ff*2)).translate(x: key.x_position(as: :mm)+((key.width(as: :mm)-upper_switch_cutout)/2), y: key.y_position(as: :mm)+((@unit-upper_switch_cutout)/2), z: -@ff)

        connector += unit_connector

        if key.stabilized?
          # wider spaces to clear brackets
          stabilizer_slot_width = @stabilizer_slot_width*1.4
          stabilizer_slot_height = @stabilizer_slot_height*1.1

          x_center = ((key.width(as: :mm))/2)-(stabilizer_slot_width/2)
          y_center = (@unit/2)-(stabilizer_slot_height/2)

          connector -= rounded_cube(x: (stabilizer_slot_width) + @stabilizer_spacing, y: stabilizer_slot_height, z: connector_t+(@ff*2)).translate(x: (x_center+key.x_position(as: :mm))-(@stabilizer_spacing/2), y: y_center-(@stabilizer_y_offset/2), z: -@ff)
        end

        # IDEA: serpentine connector, where the screw hole alternates bewtween lower and upper
      end
    end

    output += connector

    # screw holes
    top_connector_hole_locations(mgr, row).each do |coords|
      output -= cylinder(d: screw_d, h: connector_t+(@ff*2), fn: 12).translate(coords.merge(z: -@ff)).color('red')
    end

    output
  end

  # TODO: make position equidistant from each key
  # TODO: if width of key at either end is greater than 1 unit, put screw hole around it too
  def top_connector_hole_locations(mgr, row)
    holes = []

    upper_switch_cutout = @switch_cutout+2

    upper_row = mgr.rows[row] unless row<0
    lower_row = mgr.rows[row+1] if mgr.rows[row+1]

    if upper_row
      upper_row.keys[1..-1].each do |key|
        holes << { x: key.x_edge_position(:left), y: key.y_position(as: :mm)+((key.height(as: :mm))/4) }
      end
    end

    if lower_row
      lower_row.keys[1..-1].each do |key|
        holes << { x: key.x_edge_position(:left), y: key.y_edge_position(:top)-((key.height(as: :mm))/4) }
      end
    end

    holes
  end

  def bottom_plate_hole_locations(mgr)
    holes = []

    # corner holes
    screw_end_x_spacing = ((@unit-@switch_cutout)/2)/1.5
    screw_end_y_spacing = screw_end_x_spacing
    [
      [mgr.rows.first.keys.first, :top, :left, screw_end_x_spacing, -screw_end_y_spacing],
      [mgr.rows.first.keys.last, :top, :right, -screw_end_x_spacing, -screw_end_y_spacing],
      [mgr.rows.last.keys.first, :bottom, :left, screw_end_x_spacing, screw_end_y_spacing],
      [mgr.rows.last.keys.last, :bottom, :right, -screw_end_x_spacing, screw_end_y_spacing]
    ].each do |key, y, x, x_offset, y_offset|
      corner_pos = key.corner_position(x, y)
      holes << { x: corner_pos[:x]+x_offset, y: corner_pos[:y]+y_offset}
    end

    # row-end screw holes
    # screw hole in Y-middle of each row at each end
    mgr.rows[1..-2].each do |row|
      [:left, :right].each do |direction|
        corner_pos = row.keys.send(direction == :left ? :first : :last).corner_position(direction, :bottom)
        holes << {x: corner_pos[:x]+(direction == :left ? +screw_end_x_spacing : -screw_end_x_spacing), y: corner_pos[:y]+@unit/2}
      end
    end

    # column-end screw holes
    # screw hole every 2 units between keys on each column
    mgr.rows.first.keys[1..-1].each_with_index do |key, idx|
      next unless idx.odd?
      corner_pos = key.corner_position(:left, :top)
      holes << {x: corner_pos[:x], y: corner_pos[:y]-screw_end_y_spacing}
    end
    mgr.rows.last.keys[1..-1].each_with_index do |key, idx|
      next unless idx.odd?
      corner_pos = key.corner_position(:left, :bottom)
      holes << {x: corner_pos[:x], y: corner_pos[:y]+screw_end_y_spacing}
    end

    #  screw hole every 3 units (on Y-middle) on every-other row for inside rows

    mgr.rows[1..-2].each_with_index do |row, row_index|
      # next unless row_index.even?
      row.keys[1..-1].each_with_index do |key, key_index|
        next unless key_index.odd?
        corner_pos = key.corner_position(:left, :bottom)
        holes << {x: corner_pos[:x], y: corner_pos[:y]+(@unit/2)}
      end
    end

    holes
  end

  def key_rounded_corner_options(key, render_row: nil)
    {tr: false, tl: false, br: false, bl: false}.merge(
      bl: (key.first? && (key.row.last? || (render_row && key.row.number == render_row))) || (key.first? && !key.row.last? && (key.row.next.keys.first.x_edge_position(:left) > key.x_edge_position(:left))),
      tl: (key.first? && (key.row.first? || (render_row && key.row.number == render_row))) || (key.first? && !key.row.first? && (key.row.previous.keys.first.x_edge_position(:left) > key.x_edge_position(:left))),
      br: (key.last? && (key.row.last? || (render_row && key.row.number == render_row))) || (key.last? && !key.row.last? && (key.row.next.width(as: :mm) < key.row.width(as: :mm))),
      tr: (key.last? && (key.row.first? || (render_row && key.row.number == render_row))) || (key.last? && !key.row.first? && (key.row.previous.width(as: :mm) < key.row.width(as: :mm)))

      # bl: (key.first? && key.row.last?) || (key.first? && !key.row.last? && (key.row.next.keys.first.x_edge_position(:left) > key.x_edge_position(:left))),
      # tl: (key.first? && key.row.first?) || (key.first? && !key.row.first? && (key.row.previous.keys.first.x_edge_position(:left) > key.x_edge_position(:left))),
      # br: (key.last? && key.row.last?) || (key.last? && !key.row.last? && (key.row.next.width(as: :mm) < key.row.width(as: :mm))),
      # tr: (key.last? && key.row.first?) || (key.last? && !key.row.first? && (key.row.previous.width(as: :mm) < key.row.width(as: :mm)))
    )
  end

  def bottom_plate(mgr, screw_d: 2, thickness: 0.9)
    def plate_section(key, thickness)
      rounded_cube(x: key.width(as: :mm), y: key.height(as: :mm), z: thickness, options: key_rounded_corner_options(key))
    end

    plate = nil

    mgr.rows.each do |row|
      row.keys.each do |key|
        plate += plate_section(key, thickness).translate(x: key.x_position(as: :mm), y: key.y_position(as: :mm))
      end
    end

    bottom_plate_hole_locations(mgr).each do |loc|
      plate -= cylinder(d: screw_d, h: thickness+(@ff*2)).translate(loc.merge(z: -@ff)).color('purple')
    end


    plate
  end

	def part(show)
    puts "--- Begin at #{Time.now} --- "
    # mgr = Layout.new(filename: './recycler_right.json')
    mgr = Layout.new(filename: './recycler_left.json')
    # mgr = Layout.new(filename: './recycler_left_2.json')
    # mgr = Layout.new(filename: './recycler.json')
    # mgr = Layout.new(filename: './104_ansi.json')
    # mgr = Layout.new(filename: './104_iso.json')
    # mgr = Layout.new(filename: './symbolics_364000.json')
    # mgr = Layout.new(filename: './default_60.json')
    # mgr = Layout.new(filename: './leopold_fc660m.json')
    # mgr = Layout.new(filename: './stabilizer_test.json')

    # return complete_unit(mgr.keys.first, options: { wire_exit: false, no_right_channel: true, no_left_channel: true })

    # output = nil
    # 5.times do |i|
    #   output += build_layout(mgr, render_row: i).translate(y: -i * 2)
    # end
    # return output

    # return build_layout(mgr)
    return build_layout(mgr, render_row: 0)

    # return build_layout(mgr) + (top_connector(mgr, 0) + top_connector(mgr, 1) + top_connector(mgr, 2) + top_connector(mgr, 3)).color('blue').translate(z: undermount_t*1.1)
    # return build_layout(mgr) + (top_connector(mgr, -1) + top_connector(mgr, 0) + top_connector(mgr, 1) + top_connector(mgr, 2) + top_connector(mgr, 3) + top_connector(mgr, 4)).color('blue').translate(z: undermount_t*1.1)
    # return (top_connector(mgr, -1) + top_connector(mgr, 0) + top_connector(mgr, 1) + top_connector(mgr, 2) + top_connector(mgr, 3) + top_connector(mgr, 4)).color('blue').translate(z: undermount_t*1.1)
    # return top_connector(mgr, 0).translate(z: undermount_t*1.1)
    # return rounded_cube(x: 5, y: 5, z: 5, options: { tl: false })

    # return bottom_plate(mgr)


    # cherry_mx
    # socket
    # socket_with_switch
    # plate_unit
    # plate_with_undermount
    # complete_unit
  end

  def rounded_cube(x:, y:, z:, r: 1.0, fn: 16, options: {})
    options = {
      tl: true,
      tr: true,
      bl: true,
      br: true
    }.merge(options)

    if options.none?{|_k,v| !!v}
      # no rounding, just use a cube
      cube(x: x, y: y, z: z)
    else
      hull(
        (options[:bl] ? cylinder(r: r,  h: z,  fn: fn).translate(x: r, y: r) : cube(x: r, y: r, z: z)),
        (options[:br] ? cylinder(r: r,  h: z,  fn: fn).translate(x: x-r, y: r) : cube(x: r, y: r, z: z).translate(x: x-r)),
        (options[:tr] ? cylinder(r: r,  h: z,  fn: fn).translate(x: x-r, y: y-r) : cube(x: r, y: r, z: z).translate(x: x-r, y: y-r)),
        (options[:tl] ? cylinder(r: r,  h: z,  fn: fn).translate(x: r, y: y-r) : cube(x: r, y: r, z: z).translate(y: y-r))
      )
    end
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
  def plate_unit(key, options = {})
    space_width = @unit * key.width

    # cherry_mx().translate(v: [(unit)/2, (unit)/2, -ff]).translate(v: [-0,0,14.2+0.35]) +
    (
      # cube(x: space_width, y: @unit, z: @plate_mount_t) -
      cube(x: space_width, y: @unit, z: @plate_mount_t) -
      cube(x: @switch_cutout, y: @switch_cutout, z: @plate_mount_t+(@ff*2)).translate(v: [(space_width-@switch_cutout)/2, (@unit-@switch_cutout)/2, -@ff])
    )
  end

  # width is multiples of unit
  def plate_with_undermount(key, options = {})
    space_width = @unit * key.width
    # the inward curve can begin as soon as plate_unit() ends.

    # "under pocket" is a space for the clips on the underside of the plate
    under_pocket_d = 1.8
    under_pocket_l = switch_cutout*0.4

    plate_unit(key, options: options).translate(v: [0,0,@undermount_t])
    options = key_rounded_corner_options(key, render_row: options[:render_row])

    unit = (
      rounded_cube(x: space_width, y: @unit, z: @undermount_t, options: options) -
      hull(
        cube(x: @switch_cutout, y: @switch_cutout, z: @plate_mount_t+@ff).translate(v: [0,0,@undermount_t-@plate_mount_t+@ff]),
        # translate offset below should be half of what is substracted from switch_cutout
        cube(x: @switch_cutout-0.5, y: @switch_cutout-0, z: @plate_mount_t).translate(v: [0.25,0.0,0])
      ).translate(v: [(space_width-@switch_cutout)/2, (@unit-@switch_cutout)/2, -@ff]) -

      (
        cylinder(d: under_pocket_d, h: under_pocket_l, fn: 7).rotate(x: 0, y: 90, z: 0).translate(v: [(space_width-under_pocket_l)/2, (@unit-@switch_cutout)/2, 0]) +
        cylinder(d: under_pocket_d, h: under_pocket_l, fn: 7).rotate(x: 0, y: 90, z: 0).translate(v: [(space_width-under_pocket_l)/2, ((@unit-@switch_cutout)/2)+@switch_cutout, 0])
      ).translate(v: [0,0,@undermount_t]).translate(v: [0,0,(-under_pocket_d/2)-@plate_mount_t])
    )

    # TODO: fix these, puts then in wrong place for wide keys
    # corner_cutout_offset = ((@unit * key.width)-switch_cutout)/2
    # modifier = 0.15
    # unit -= cylinder(d: 1, h: @plate_mount_t+@ff).translate(x: corner_cutout_offset+modifier, y: corner_cutout_offset+modifier, z: @undermount_t-@plate_mount_t)
    # unit -= cylinder(d: 1, h: @plate_mount_t+@ff).translate(x: corner_cutout_offset+switch_cutout-modifier, y: corner_cutout_offset+modifier, z: @undermount_t-@plate_mount_t)
    # unit -= cylinder(d: 1, h: @plate_mount_t+@ff).translate(x: corner_cutout_offset+switch_cutout-modifier, y: corner_cutout_offset+switch_cutout-modifier, z: @undermount_t-@plate_mount_t)
    # unit -= cylinder(d: 1, h: @plate_mount_t+@ff).translate(x: corner_cutout_offset+modifier, y: corner_cutout_offset+switch_cutout-modifier, z: @undermount_t-@plate_mount_t)

    # unit *= cube(x: space_width, y: @unit/2, z: @undermount_t).translate(v: [0, 0, 0])
    # unit *= cube(x:  space_width, y: @unit/2, z: @undermount_t).translate(v: [0, @unit/2, 0])
    # unit *= cube(x: space_width/2, y: @unit/2, z: @undermount_t).translate(v: [0, @unit/2, 0])
    # unit *= cube(x: space_width/2, y: @unit, z: @undermount_t).translate(v: [0, 0, 0])

    unit
  end

  # width is multiples of unit
  def complete_unit(key, options: {})
    space_width = @unit * key.width;
    obj = plate_with_undermount(key, options)
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

    if options[:wire_exit]
      # make large channel for wires to exit to go to MCU.
      obj -= cylinder(d: @wiring_channel_d, h: key.height(as: :mm)/2, fn: 4).scale(x: 1.75, y: 1, z: 1).rotate(x: 270, y: 0, z: 0).translate(x: space_width/2, y: key.height(as: :mm)/1.5)
    end

    if options[:stabilized]
      stabilizers = nil

      x_center = ((key.width(as: :mm))/2)-(@stabilizer_slot_width/2)
      y_center = (@unit/2)-(@stabilizer_slot_height/2)

      [1, -1].each do |sign|
        stabilizer = nil

        stabilizer += cube(x: @stabilizer_slot_width, y: @stabilizer_slot_height, z: @stabilizer_slot_depth+ff).translate(x: x_center+(@stabilizer_spacing/2)*sign, y: y_center-@stabilizer_y_offset, z: -@stabilizer_slot_depth)

        stabilizer += hull(
          cube(
            x: @stabilizer_slot_width,
            y: @stabilizer_slot_height,
            z: 0.1
          ).translate(
            x: x_center+(@stabilizer_spacing/2)*sign,
            y: y_center-@stabilizer_y_offset,
            z: -@stabilizer_slot_depth
          ),

          cube(
            x: @stabilizer_slot_width+2,
            y: @stabilizer_slot_height+2,
            z: @stabilizer_slot_depth*2.5
          ).translate(
            x: (x_center+(@stabilizer_spacing/2)*sign)-1,
            y: y_center-@stabilizer_y_offset-1.0,
            # z: -(@stabilizer_slot_depth)-2.5
            z: -(@stabilizer_slot_depth*4)
          )
        )

        stabilizers += stabilizer
      end

      obj -= stabilizers.translate(z: undermount_t)
      # obj += stabilizers.translate(z: undermount_t*2)
    end
    obj

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
