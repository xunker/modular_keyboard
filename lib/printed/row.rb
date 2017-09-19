# Class describing a single row of keys
class Row < CrystalScad::Printed
  FF = 0.1

  attr_reader :row, :options
  skip [:output, :show, :show_hardware]

  # @params row Layout::Row the row to render
  # row accepts nil because the crystalscad render action instantiates it
  def initialize(row = nil, options: {})
    return if row.nil?

    @row = row
    @options = options
  end

  def part
    output = nil

    # for deciding where the wire exits will be
    median_key_number = row.keys.length/2

    row.keys.each do |key|
      # puts "x: #{key.x_position(as: :mm)}"
      # puts "y: #{key.y_position(as: :mm)}"

      output += Key.new(key,
        options: {
          stabilized: key.stabilized?,
          no_left_channel: key.first?,
          no_right_channel: key.last?,
          render_row: render_row,
          wire_exit: key.row.first? && (median_key_number-1..median_key_number+1).to_a.include?(key.number)
        }
      ).part.translate(x: key.x_position(as: :mm), z: 0)
    end

    output
  end
end
