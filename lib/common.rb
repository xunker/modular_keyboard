# Common functions used everywhere
module Common
  include CrystalScad

  # Cube that is rounded on the X and Y corners only
  def self.rounded_rectangle(x:, y:, z:, r: 1.0, fn: 16, options: {})
    adj = options[:adj] || {}
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

      corner = lambda {|*loc, rounded: true, adj: {}|
        height = 0.01 # height of cylinder corners OR X/Y/Z of square corners

        loc = Array(loc).flatten
        top = loc.include?(:top)
        bottom = !top
        left = loc.include?(:left)
        right = !left
        lower = loc.include?(:lower)
        upper = !lower

        x_adj = 0
        y_adj = 0
        z_adj = 0

        x_adj += x if right
        y_adj += y if top
        z_adj += z if upper

        x_adj += adj[:x].to_i if right
        x_adj -= adj[:x].to_i if left
        y_adj += adj[:y].to_i if top
        y_adj -= adj[:y].to_i if bottom


        output = if rounded
          x_adj += (left ? r : -r)
          y_adj += (bottom ? r : -r)
          z_adj += (upper ? -height : 0)

          cylinder(r: r, h: height, fn: fn)
        else
          x_adj -= height if right
          y_adj -= height if top
          z_adj -= height if upper

          cube(x: height, y: height, z: height)
        end

        output.translate(x: x_adj, y: y_adj, z: z_adj)
      }

      hull(
        corner.call(:bottom, :left, :lower, rounded: options[:bl], adj: { x: adj[:ll], y: adj[:bl] }),
        corner.call(:bottom, :left, :upper, rounded: options[:bl], adj:{ x: adj[:lu], y: adj[:bu] }),

        corner.call(:bottom, :right, :lower, rounded: options[:br], adj: { x: adj[:rl], y: adj[:bl] }),
        corner.call(:bottom, :right, :upper, rounded: options[:br], adj: { x: adj[:ru], y: adj[:bu] }),

        corner.call(:top, :right, :lower, rounded: options[:tr], adj: { x: adj[:rl], y: adj[:tl] }),
        corner.call(:top, :right, :upper, rounded: options[:tr], adj: { x: adj[:ru], y: adj[:tu] }),

        corner.call(:top, :left, :lower, rounded: options[:tl], adj: { x: adj[:ll], y: adj[:tl] }),
        corner.call(:top, :left, :upper, rounded: options[:tl], adj: { x: adj[:lu], y: adj[:tu] })
      )
    end
  end

  # Cube that is rounded on the X,Y, and Z corners.
  def self.rounded_cube(x:, y:, z:, r: 1.0, fn: 16, options: {})
    options = {
      tll: true,
      tlu: true,
      trl: true,
      tru: true,
      bll: true,
      blu: true,
      brl: true,
      bru: true
    }.merge(options)

    if options.none?{|_k,v| !!v}
      # no rounding, just use a cube
      cube(x: x, y: y, z: z)
    else

      corner = lambda {|*loc, rounded: true, adj: {}|
        square_corner_height = 0.01 # side length of square corner cubes

        loc = Array(loc).flatten
        top = loc.include?(:top)
        bottom = !top
        left = loc.include?(:left)
        right = !left
        lower = loc.include?(:lower)
        upper = !lower

        x_adj = 0
        y_adj = 0
        z_adj = 0

        x_adj += x if right
        y_adj += y if top
        z_adj += z if upper

        output = if rounded
          x_adj += (left ? r : -r)
          y_adj += (bottom ? r : -r)
          z_adj += (lower ? r : -r)

          sphere(r: r, fn: fn)
        else
          x_adj -= square_corner_height if right
          y_adj -= square_corner_height if top
          z_adj -= square_corner_height if upper

          cube(x: square_corner_height, y: square_corner_height, z: square_corner_height)
        end

        output.translate(x: x_adj, y: y_adj, z: z_adj)
      }

      hull(
        corner.call(:bottom, :left, :lower, rounded: options[:bll]),
        corner.call(:bottom, :left, :upper, rounded: options[:blu]),

        corner.call(:bottom, :right, :lower, rounded: options[:brl]),
        corner.call(:bottom, :right, :upper, rounded: options[:bru]),

        corner.call(:top, :right, :lower, rounded: options[:trl]),
        corner.call(:top, :right, :upper, rounded: options[:tru]),

        corner.call(:top, :left, :lower, rounded: options[:tll]),
        corner.call(:top, :left, :upper, rounded: options[:tlu]),
      )
    end
  end

  def self.cherry_mx
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

  def self.socket
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
end
