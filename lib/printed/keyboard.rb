require "awesome_print"

class Keyboard < CrystalScad::Printed
  FF = 0.1
  SWITCH_CUTOUT = 14 # cherry mx

  # FILENAME = './recycler_right.json'
  FILENAME = './recycler_left.json'
  # FILENAME = './recycler_left_2.json'
  # FILENAME = './recycler.json'
  # FILENAME = './104_ansi.json'
  # FILENAME = './104_iso.json'
  # FILENAME = './symbolics_364000.json'
  # FILENAME = './default_60.json'
  # FILENAME = './leopold_fc660m.json'
  # FILENAME = './stabilizer_test.json'

  $fn=16 # comment out to used default (64)

  skip :output

	def initialize()
    @unit = Layout::DEFAULT_UNIT_WIDTH

    @stabilizer_spacing = 24 # 20.6 (20.5 measured)?
    @stabilizer_slot_width = 3.5 # 3.3 (3.5 measured)
    @stabilizer_slot_height = 14.0 # 14 (14 measured)
    @stabilizer_slot_depth = 1.0
    @stabilizer_y_offset = 0.5 # 0.75 is too far down, rubs

    @wiring_channel_d = 6

    @show_legends = false
	end

  def build_layout(mgr, render_row: nil, row_options: {})
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

    mgr.rows.each do |row|
      row.keys.each do |key|
        unconnected[:above] << key unless row.first?
        unconnected[:below] << key unless row.last?
      end
      next if render_row && key.row.number != render_row
      output += Row.new(row).part.translate(y: row.y_position(as: :mm))
    end

    if render_row
      row = mgr.rows[render_row]
      if trim_y = row_options[:trim_y]
        # options to narrow Y-width of each rendered row to compensate for
        # printer calibration and variance. To be used to allow the rows to fit
        # together properly without having to sand/grind/trim the pieces by hand.

        trim_y_cube = if trim_y.is_a? Hash
          # adjusting the top and bottom separately
          bottom = cube(
              x: row.width(as: :mm)+(FF*2),
              y: @unit-(trim_y[:bottom].to_f*2.0),
              z: 0.1
          ).translate(x: -FF, y: trim_y[:bottom].to_f, z: -FF)

          top = cube(
            x: row.width(as: :mm)+(FF*2),
            y: @unit-(trim_y[:top].to_f*2.0),
            z: 0.1
          ).translate(x: -FF, y: trim_y[:top].to_f, z: Key::UNDERMOUNT_T+FF)

          hull(bottom, top).translate(y: row.keys.first.y_position(as: :mm))
        else
          # assume trim_y is an int/float, and adjust the side as a whole
          cube(
            x: row.width(as: :mm)+(FF*2),
            y: @unit-(trim_y*2),
            z: Key::UNDERMOUNT_T+(FF*2)
          ).translate(y: row.keys.first.y_position(as: :mm)+trim_y)
        end

        output *= trim_y_cube.translate(
          x: row.keys.first.x_position(as: :mm)-FF,
          z: -FF
        )

      end
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
        x_offset = (key.x_position(as: :mm)+(key.width(as: :mm)/2))-(SWITCH_CUTOUT/3)
        legends += text(text: key.legend.to_s.gsub("\"", "Quote"), size: 3).translate(x: x_offset, y: key.y_position(as: :mm)+((key.height(as: :mm))/2), z: Key::UNDERMOUNT_T)
      end

      output += legends.background
    end

    # bottom screw holes
    BottomPlate.bottom_plate_hole_locations(mgr).each do |loc|
      output -= cylinder(
        d: BottomPlate::SCREW_D,
        h: BottomPlate::SCREW_H,
        fn: 8
      ).translate(loc.merge(z: -FF)).color('purple')
    end

    if render_row
      # top connector screw holes
      # Render time cut in half if connector holes not rendered?
      screw_d = 1.5
      screw_h = 2
      (mgr.rows.length+1).times do |row_number|
        # negative 1 (-1) is to get topmost row of holes.
        top_connector_hole_locations(mgr, row_number-1).each do |coords|
          output -= cylinder(d: screw_d, h: screw_h+FF, fn: 12).translate(coords.merge(z: Key::UNDERMOUNT_T-screw_h)).color('red')
        end
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

    upper_switch_cutout = SWITCH_CUTOUT+2
    # end_x_spacing = (@unit-SWITCH_CUTOUT)/2
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

        unit_connector -= Common.rounded_rectangle(x: upper_switch_cutout, y: upper_switch_cutout, z: connector_t+(FF*2)).translate(x: key.x_position(as: :mm)+((key.width(as: :mm)-upper_switch_cutout)/2), y: key.y_position(as: :mm)+((@unit-upper_switch_cutout)/2), z: -FF)

        connector += unit_connector

        if key.stabilized?
          # wider spaces to clear brackets
          stabilizer_slot_width = @stabilizer_slot_width*1.4
          stabilizer_slot_height = @stabilizer_slot_height*1.1

          x_center = ((key.width(as: :mm))/2)-(stabilizer_slot_width/2)
          y_center = (@unit/2)-(stabilizer_slot_height/2)

          connector -= Common.rounded_rectangle(x: (stabilizer_slot_width) + @stabilizer_spacing, y: stabilizer_slot_height, z: connector_t+(FF*2)).translate(x: (x_center+key.x_position(as: :mm))-(@stabilizer_spacing/2), y: y_center-(@stabilizer_y_offset/2), z: -FF)
        end

        # IDEA: serpentine connector, where the screw hole alternates bewtween lower and upper
      end
    end

    if lower_row
      # Generate connector pieces for lower row
      lower_row.keys.each do |key|
        unit_connector = cube(x: key.width(as: :mm), y: ((key.height(as: :mm))/2)-y_reduction, z: connector_t).translate(x: key.x_position(as: :mm), y: key.y_position(as: :mm)+((key.height(as: :mm))/2)+y_reduction, z: 0)

        unit_connector -= Common.rounded_rectangle(x: upper_switch_cutout, y: upper_switch_cutout, z: connector_t+(FF*2)).translate(x: key.x_position(as: :mm)+((key.width(as: :mm)-upper_switch_cutout)/2), y: key.y_position(as: :mm)+((@unit-upper_switch_cutout)/2), z: -FF)

        connector += unit_connector

        if key.stabilized?
          # wider spaces to clear brackets
          stabilizer_slot_width = @stabilizer_slot_width*1.4
          stabilizer_slot_height = @stabilizer_slot_height*1.1

          x_center = ((key.width(as: :mm))/2)-(stabilizer_slot_width/2)
          y_center = (@unit/2)-(stabilizer_slot_height/2)

          connector -= Common.rounded_rectangle(x: (stabilizer_slot_width) + @stabilizer_spacing, y: stabilizer_slot_height, z: connector_t+(FF*2)).translate(x: (x_center+key.x_position(as: :mm))-(@stabilizer_spacing/2), y: y_center-(@stabilizer_y_offset/2), z: -FF)
        end

        # IDEA: serpentine connector, where the screw hole alternates bewtween lower and upper
      end
    end

    output += connector

    # screw holes
    top_connector_hole_locations(mgr, row).each do |coords|
      output -= cylinder(d: screw_d, h: connector_t+(FF*2), fn: 12).translate(coords.merge(z: -FF)).color('red')
    end

    output
  end

  # TODO: make position equidistant from each key
  # TODO: if width of key at either end is greater than 1 unit, put screw hole around it too
  def top_connector_hole_locations(mgr, row)
    holes = []

    upper_switch_cutout = SWITCH_CUTOUT+2

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

	def part(show)
    puts "--- Begin at #{Time.now} ---"

    mgr = Layout.new(filename: FILENAME)

    # return complete_unit(mgr.keys.first, options: { wire_exit: false, no_right_channel: true, no_left_channel: true }) + Key.new(mgr.keys.first, wire_exit: false, no_right_channel: true, no_left_channel: true).part.translate(x: 20)

    # output = nil
    # 5.times do |i|
    #   output += build_layout(mgr, render_row: i).translate(y: -i * 2)
    # end
    # return output

    return build_layout(mgr)
    # return build_layout(mgr, render_row: 4, row_options: { trim_y: { bottom: 0.5, top: 0 }})
    # return build_layout(mgr, render_row: 1, row_options: { trim_y: 0.5})

    # return build_layout(mgr) + (top_connector(mgr, 0) + top_connector(mgr, 1) + top_connector(mgr, 2) + top_connector(mgr, 3)).color('blue').translate(z: Key::UNDERMOUNT_T*1.1)
    # return build_layout(mgr) + (top_connector(mgr, -1) + top_connector(mgr, 0) + top_connector(mgr, 1) + top_connector(mgr, 2) + top_connector(mgr, 3) + top_connector(mgr, 4)).color('blue').translate(z: Key::UNDERMOUNT_T*1.1)
    # return (top_connector(mgr, -1) + top_connector(mgr, 0) + top_connector(mgr, 1) + top_connector(mgr, 2) + top_connector(mgr, 3) + top_connector(mgr, 4)).color('blue').translate(z: Key::UNDERMOUNT_T*1.1)
    # return top_connector(mgr, 0).translate(z: Key::UNDERMOUNT_T*1.1)

    # return cube(x: 5, y: 5, z: 5).background + Common.rounded_rectangle(x: 5, y: 5, z: 5, options: { tr: false, adj: {
      # lu: 1, ll: 2, rl: 2, ru: 4,
      # tu: 1, tl: 2, bl: 2, bu: 4,
    # } })

    # return cube(x: 5, y: 5, z: 5).background - rounded_cube(x: 5, y: 5, z: 5, options: { tru: false, bll: false})
  end

end
