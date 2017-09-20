# The bottom plate of the keyboard, also includes attachment points for feet
class BottomPlate < CrystalScad::Printed
  FF = 0.1

  SCREW_D = 1.4
  SCREW_D_SLOP = 0.08 # make screw holes on plate this much larger to account for "squish"
  SCREW_H = 3
  THICKNESS = 0.9

  skip :output

	def initialize()

  end

  def part(show)
    puts "--- Begin at #{Time.now} ---"
    mgr = Layout.new(filename: Keyboard::FILENAME)

    return bottom_plate(mgr, thickness: 0.7)
  end

  def bottom_plate(mgr, screw_d: SCREW_D, screw_d_slop: SCREW_D_SLOP, thickness: THICKNESS)
    def plate_section(key, thickness)
      Common.rounded_rectangle(x: key.width(as: :mm), y: key.height(as: :mm), z: thickness, options: Key.key_rounded_corner_options(key))
    end

    plate = nil

    mgr.rows.each do |row|
      row.keys.each do |key|
        plate += plate_section(key, thickness).translate(x: key.x_position(as: :mm), y: key.y_position(as: :mm))
      end
    end

    BottomPlate.bottom_plate_hole_locations(mgr).each do |loc|
      plate -= cylinder(d: screw_d+screw_d_slop, h: thickness+(FF*2)).translate(loc.merge(z: -FF)).color('purple')
    end

    plate
  end

  def self.bottom_plate_hole_locations(mgr)
    holes = []

    # corner holes
    screw_end_x_spacing = ((Layout::DEFAULT_UNIT_WIDTH-Keyboard::SWITCH_CUTOUT)/2)/1.5
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
        holes << {
          x: corner_pos[:x]+(direction == :left ? +screw_end_x_spacing : -screw_end_x_spacing),
          y: corner_pos[:y]+Layout::DEFAULT_UNIT_WIDTH/2
        }
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
        holes << {x: corner_pos[:x], y: corner_pos[:y]+(Layout::DEFAULT_UNIT_WIDTH/2)}
      end
    end

    holes
  end
end
