class Modular_keyboardAssembly < CrystalScad::Assembly
	PART_SPACING = 5
	# Assemblies are used to show how different parts interact on your design.

	# Skip generation of the 'output' method for this assembly.
	# (will still generate 'show')
	skip :output

	def part(show)
		# # Create a test cube
		# cube = TestCube.new
		#
		# # And another one, but translate this one next to the cube and change the color
		# # You can use any transformation on the class itself.
		# another_cube = TestCube.new.translate(z:cube.z).color("MediumTurquoise")
		#
		# # We're calling the show method on both cubes
		# res = cube.show
		# res += another_cube.show
		#
		# # There's a bolt going through the cubes and a nut on the bottom. Let's show it
		# res += cube.show_hardware
		#
		# # always make sure the lowest statement always returns the object that you're working on
		# res

		keyboard = Keyboard.new
		bottom_plate = BottomPlate.new

		res = keyboard.show.translate(z: bottom_plate.thickness + PART_SPACING)
		res += bottom_plate.show
		res
	end

end
