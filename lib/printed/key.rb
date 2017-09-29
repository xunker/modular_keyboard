# Class describing a single key unit
class Key < CrystalScad::Printed
  FF = 0.1

  UNDERMOUNT_T = 9.0

  FN_DIV = Keyboard::FN_DIV # Divide all $fn values by this, to test effect on render times
  $fn=$fn/FN_DIV # comment out to used default (64)

  attr_reader :key, :options
  skip [:output, :show, :show_hardware]

  # @params key Layout::Key the key to render
  # key accepts nil because the crystalscad render action instantiates it
  def initialize(key = nil, options: {})
    return if key.nil?

    @options = options
    @key = key

    @unit = key.unit_width # cherry mx
    @switch_cutout = 14 # cherry mx

    @stabilizer_spacing = 24 # 20.6 (20.5 measured)?
    @stabilizer_slot_width = 3.5 # 3.3 (3.5 measured)
    @stabilizer_slot_height = 14.0 # 14 (14 measured)
    @stabilizer_slot_depth = 1.0
    @stabilizer_y_offset = 0.5 # 0.75 is too far down, rubs

    @plate_mount_t = 1.6 # Cherry MX Brown
    # @plate_mount_t = 1.7 # Greetech Brown, measured
    # @plate_mount_t = 1.6 # Outemu, measured

    @undermount_t = UNDERMOUNT_T

    @wiring_channel_d = 6
    @x_wiring_channel_offset = unit/3.5
	end

  def part
    space_width = @unit * key.width
    obj = plate_with_undermount
    # X wiring channel
    if options[:no_left_channel]
      obj -= cylinder(d: @wiring_channel_d, h: (space_width/2)+(FF*2), fn: 4).translate(v: [0,0,(space_width/2)]).rotate(x: 0, y: 90, z: 0).translate(v: [0, @x_wiring_channel_offset,0])
      obj
    elsif options[:no_right_channel]
      obj -= cylinder(d: @wiring_channel_d, h: (space_width/2)+(FF*2), fn: 4).translate(v: [0,0,-FF]).rotate(x: 0, y: 90, z: 0).translate(v: [0, @x_wiring_channel_offset,0])
      obj
    else
      obj -= cylinder(d: @wiring_channel_d, h: space_width+(FF*2), fn: 4).translate(v: [0,0,-FF]).rotate(x: 0, y: 90, z: 0).translate(v: [0, @x_wiring_channel_offset,0])
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

        stabilizer += cube(x: @stabilizer_slot_width, y: @stabilizer_slot_height, z: @stabilizer_slot_depth+FF).translate(x: x_center+(@stabilizer_spacing/2)*sign, y: y_center-@stabilizer_y_offset, z: -@stabilizer_slot_depth)

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

  def plate_with_undermount
    space_width = @unit * key.width
    # the inward curve can begin as soon as plate_unit() ends.

    # "under pocket" is a space for the clips on the underside of the plate
    under_pocket_d = 1.8
    under_pocket_l = switch_cutout*0.4

    plate_unit.translate(v: [0,0,@undermount_t])

    options = Key.key_rounded_corner_options(key, render_row: (options || {})[:render_row])

    unit = (
      Common.rounded_rectangle(x: space_width, y: @unit, z: @undermount_t, options: options) -
      hull(
        cube(x: @switch_cutout, y: @switch_cutout, z: @plate_mount_t+FF).translate(v: [0,0,@undermount_t-@plate_mount_t+FF]),
        # translate offset below should be half of what is substracted from switch_cutout
        cube(x: @switch_cutout-0.5, y: @switch_cutout-0, z: @plate_mount_t).translate(v: [0.25,0.0,0])
      ).translate(v: [(space_width-@switch_cutout)/2, (@unit-@switch_cutout)/2, -FF]) -

      (
        cylinder(d: under_pocket_d, h: under_pocket_l, fn: 7/FN_DIV).rotate(x: 0, y: 90, z: 0).translate(v: [(space_width-under_pocket_l)/2, (@unit-@switch_cutout)/2, 0]) +
        cylinder(d: under_pocket_d, h: under_pocket_l, fn: 7/FN_DIV).rotate(x: 0, y: 90, z: 0).translate(v: [(space_width-under_pocket_l)/2, ((@unit-@switch_cutout)/2)+@switch_cutout, 0])
      ).translate(v: [0,0,@undermount_t]).translate(v: [0,0,(-under_pocket_d/2)-@plate_mount_t])
    )

    # TODO: fix these, puts then in wrong place for wide keys
    # corner_cutout_offset = ((@unit * key.width)-switch_cutout)/2
    # modifier = 0.15
    # unit -= cylinder(d: 1, h: @plate_mount_t+FF).translate(x: corner_cutout_offset+modifier, y: corner_cutout_offset+modifier, z: @undermount_t-@plate_mount_t)
    # unit -= cylinder(d: 1, h: @plate_mount_t+FF).translate(x: corner_cutout_offset+switch_cutout-modifier, y: corner_cutout_offset+modifier, z: @undermount_t-@plate_mount_t)
    # unit -= cylinder(d: 1, h: @plate_mount_t+FF).translate(x: corner_cutout_offset+switch_cutout-modifier, y: corner_cutout_offset+switch_cutout-modifier, z: @undermount_t-@plate_mount_t)
    # unit -= cylinder(d: 1, h: @plate_mount_t+FF).translate(x: corner_cutout_offset+modifier, y: corner_cutout_offset+switch_cutout-modifier, z: @undermount_t-@plate_mount_t)

    # unit *= cube(x: space_width, y: @unit/2, z: @undermount_t).translate(v: [0, 0, 0])
    # unit *= cube(x:  space_width, y: @unit/2, z: @undermount_t).translate(v: [0, @unit/2, 0])
    # unit *= cube(x: space_width/2, y: @unit/2, z: @undermount_t).translate(v: [0, @unit/2, 0])
    # unit *= cube(x: space_width/2, y: @unit, z: @undermount_t).translate(v: [0, 0, 0])

    unit
  end

  def plate_unit
    space_width = @unit * key.width

    # cherry_mx().translate(v: [(unit)/2, (unit)/2, -FF]).translate(v: [-0,0,14.2+0.35]) +
    (
      # cube(x: space_width, y: @unit, z: @plate_mount_t) -
      cube(x: space_width, y: @unit, z: @plate_mount_t) -
      cube(x: @switch_cutout, y: @switch_cutout, z: @plate_mount_t+(FF*2)).translate(v: [(space_width-@switch_cutout)/2, (@unit-@switch_cutout)/2, -FF])
    )
  end

  # @params key Layout::Key the key to render
  def self.key_rounded_corner_options(key, render_row: nil)

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
end
