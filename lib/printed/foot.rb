# Feet for lifting the rear of the keyboard
class Foot < CrystalScad::Printed
  attr_reader :thickness
  FF = 0.1

  ATTACHMENT_THICKNESS = 1.2
  LEG_TICKNESS = 3
  LEG_LENGTH = 10
  FOOT_D = 9

  ATT_WIDTH = (BottomPlate::FOOT_SCREW_X_SPACING + (BottomPlate::FOOT_SCREW_D*2)) * 1.0
  ATT_LENGTH = (BottomPlate::FOOT_SCREW_ROWS*BottomPlate::FOOT_SCREW_Y_SPACING) + (BottomPlate::FOOT_SCREW_D/2)

  skip :output

  def initialize()
  end

  def part(show)
    attachment + leg.translate(x: (ATT_WIDTH-LEG_LENGTH)/2, y: -FOOT_D)
  end

  def screw_channels
    output = nil
    [1,-1].each do | sign|
      cutout = nil
      BottomPlate::FOOT_SCREW_ROWS.times do |row|
        cutout += cylinder(
          d: BottomPlate::FOOT_SCREW_D,
          h: ATTACHMENT_THICKNESS+(FF*2),
          fn: 24
        ).translate(
          x: (BottomPlate::FOOT_SCREW_X_SPACING/2)*sign,
          y: row*BottomPlate::FOOT_SCREW_Y_SPACING,
          z:-FF
        )
        output += hull(cutout)
      end
    end
    output
  end

  def attachment

    output = Common.rounded_rectangle(
      x: ATT_WIDTH,
      y: ATT_LENGTH,
      z: ATTACHMENT_THICKNESS
    )

    output -= screw_channels.translate(
      x: (BottomPlate::FOOT_SCREW_X_SPACING/2) + BottomPlate::FOOT_SCREW_D,
      y: BottomPlate::FOOT_SCREW_D
    )

    # tab that connects leg to attachment plate
    tab = cube(
      x: BottomPlate::FOOT_SCREW_D,
      y: BottomPlate::FOOT_SCREW_D*2,
      z: LEG_TICKNESS
    )
    tab += cylinder(
      d: BottomPlate::FOOT_SCREW_D*2,
      h: LEG_TICKNESS
    ).translate(
      y: BottomPlate::FOOT_SCREW_D
    )

    tab -= cylinder(
      d: BottomPlate::FOOT_SCREW_D,
      h: LEG_TICKNESS+(FF*2)
    ).translate(
      y: BottomPlate::FOOT_SCREW_D,
      z: -FF
    )

    tab.rotate(y: 90).translate(z: BottomPlate::FOOT_SCREW_D)

    output += tab.translate(
      x: (ATT_WIDTH/2)-(LEG_TICKNESS/1),
      y: ATT_LENGTH/2,
      z: ATTACHMENT_THICKNESS
    )

  end

  def leg
    # tab that connects leg to attachment plate
    tab = cube(
      x: LEG_LENGTH,
      y: BottomPlate::FOOT_SCREW_D*2,
      z: LEG_TICKNESS
    ) + hull(
      # buttress
      cube(
        x: 0.1, # just exists for hull, so size not important
        y: BottomPlate::FOOT_SCREW_D*2,
        z: LEG_TICKNESS
      ).translate(x: BottomPlate::FOOT_SCREW_D),

      cube(
        x: 0.1, # just exists for hull, so size not important
        y: BottomPlate::FOOT_SCREW_D*2,
        z: FOOT_D/1.5
      ).translate(x: LEG_LENGTH)
    )


    tab += cylinder(
      d: BottomPlate::FOOT_SCREW_D*2,
      h: LEG_TICKNESS
    ).translate(
      y: BottomPlate::FOOT_SCREW_D
    )

    tab -= cylinder(
      d: BottomPlate::FOOT_SCREW_D,
      h: LEG_TICKNESS*2
    ).translate(
      y: BottomPlate::FOOT_SCREW_D,
      z: -FF
    )

    foot = cylinder(
      d: FOOT_D,
      h: LEG_TICKNESS
    ) - cube(
      x: FOOT_D,
      y: FOOT_D,
      z: LEG_TICKNESS+(FF*2)
    ).translate(
      y: -FOOT_D/2,
      x: FOOT_D/3,
      z: -FF
    )

    tab += foot.rotate(y: 90).translate(
      x: LEG_LENGTH,
      y: FOOT_D/3,
      z: FOOT_D/3
    )

    tab
  end

  # with view you can define more outputs of a file.
	# This is useful when you are designing subassemblies of an object.
	view :assembled

	def assembled
		attachment + leg.rotate(y: 270).translate(
      x: (ATT_WIDTH/2)-(ATTACHMENT_THICKNESS/1.5),
      y: ATT_LENGTH/2,
      z: LEG_LENGTH-ATTACHMENT_THICKNESS
    )
	end
end
