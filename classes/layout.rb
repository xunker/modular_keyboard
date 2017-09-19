# Parser for layout information from keyboard-layout-editor.com
require 'json'

class Layout
  attr_reader :json, :structure, :rows, :unit_width, :unit_height
  attr_accessor :keys, :stabilizers, :stabilized_width

  DEFAULT_UNIT_WIDTH = 19.05 # Cherry MX
  DEFAULT_UNIT_HEIGHT = 19.05 # Cherry MX

  def initialize(filename: nil, json: nil, options: {})
    # default options
    options = {
      stabilizers: true, # will only be added if width (in units) >= stabilized_width
      stabilized_width: 2.0,
      unit_width: options[:unit_width] || DEFAULT_UNIT_WIDTH,
      unit_height: options[:unit_height] || DEFAULT_UNIT_HEIGHT
    }.merge(options)

    if [filename.to_s, json.to_s].join.length == 0
      raise ArgumentError, 'must supply either :filename or :json'
    end

    @json = json

    if filename
      @json = File.open(filename, 'r').read

      unless @json[0..1] == '[['
        @json = '[' + @json + ']'
      end

      # Fix kle.com's json, add quotes around hash keys
      @json.gsub!(/\{(\w+)\:/, '{"\1": ')
      @json.gsub!(/\,(\w+)\:/, ',"\1": ')
    end

    @structure = JSON.parse(@json)
    # puts @json.inspect

    @stabilizers = options[:stabilizers]
    # keys this many UNITS or wider will have stabilizers added
    # if @stabilizers is true
    @stabilized_width = options[:stabilized_width].to_f

    @unit_width = options[:unit_width]
    @unit_height = options[:unit_height]

    @keys = []
    load_rows
  end

  def stabilizers?
    @stabilizers
  end

  def find_key(row, column)
    rows[row].keys[column]
  end

  # return the width, it can be in :units or :mm. If returning width
  # in :mm, any additional offsets will be included. If returning
  # width in :units, no offset additional information will be included.
  def width(as: :units)
    if as == :mm
      widest_row = rows.max_by{|row| row.keys.last.row_offset + row.keys.last.width}

      (widest_row.keys.last.row_offset + widest_row.keys.last.width) * unit_width
    else
      rows.max_by{|row| row.keys.length}.keys.length
    end
  end

  # return the width, it can be in :units or :mm. If :mm, unit_width
  # must be given
  def height(as: :units)
    max_height = rows.length
    max_height *= unit_height if as == :mm
    max_height
  end

  def load_rows
    row_number = -1
    @rows = @structure.map{|row_structure| row_number += 1; Row.new(row_structure, row_number, self)}
  end

  class Row
    attr_reader :structure, :keys, :number, :layout
    def initialize(structure = [], row_number, parent_layout)
      @layout = parent_layout
      @number = row_number
      @structure = structure
      key_number = -1
      @keys = []
      key_settings = {}
      structure.each do |key_structure|
        if key_structure.is_a? Hash
          # not a key, but key settings info
          key_settings.merge!(key_structure)
        else
          # key structure is probably legends string
          key_number += 1
          @keys << Key.new(key_structure, key_settings, key_number, self)
          key_settings = {}
        end
      end
      parent_layout.keys += @keys
    end

    def first?
      number == 0
    end

    def last?
      number == layout.rows.length-1
    end

    def width(as: :units)
      if as == :mm
        keys.last.x_edge_position(:right)
      else
        keys.length
      end
    end

    # returns the row after this one, if present, else nil
    def next
      layout.rows[number+1] unless last?
    end

    # returns the row before this one, if present, else nil
    def previous
      layout.rows[number-1] unless first?
    end
  end

  class Key
    attr_reader :legends, :settings, :number, :row, :row_offset, :additional_offset, :switch_mount, :switch_brand, :switch_type
    attr_accessor :stabilizers

    def initialize(legends, settings, key_number, parent_row)
      @number = key_number
      @row = parent_row
      @settings = settings

      @legends = %i[
        top_left bottom_left
        top_right bottom_right
        front_left front_right
        center_left center_right
        top_center center
        bottom_center front_center
      ].zip(legends.split("\n")).to_h

      # convert empty string legends to nil
      @legends.each do |k, v|
        @legends[k] = nil if v == ''
      end

      parse_settings

      @width ||= 1.0
      @height ||=  1.0
      @additional_offset ||= 0.0
      @stabilizers ||= layout.stabilizers? && @width >= layout.stabilized_width

      calculate_row_offset
    end

    def width(as: :units)
      if as == :mm
        @width * unit_width
      else
        @width
      end
    end

    def height(as: :units)
      if as == :mm
        @height * unit_height
      else
        @height
      end
    end


    def first?
      number == 0
    end

    def last?
      number == row.keys.length-1
    end

    def legend(location = :top_left)
      @legends[location]
    end

    def layout
      row.layout
    end

    def stabilizers?
      @stabilizers
    end
    alias_method :stabilized?, :stabilizers?

    def unit_width
      layout.unit_width
    end

    def unit_height
      layout.unit_height
    end

    # Returns position of left (x-plane) of key unit
    def x_position(as: :units)
      if as == :mm
        row_offset * unit_width
      else
        number
      end
    end

    # Returns position of bottom (y-plane) of key unit
    def y_position(as: :units)
      if as == :mm
        ((row.layout.height-1) - row.number) * unit_height
      else
        row.number
      end
    end

    # Returns position of bottom-left corner of key unit
    def position(as: :units)
      if as == :mm
        {
          x: x_position(as: :mm, unit_width: unit_width),
          y: y_position(as: :mm, unit_height: unit_height)
        }
      else
        {
          x: number,
          y: row.number
        }
      end
    end

    # Returns the position of the edge of the key unit along the
    # X-Plane, IN MM.
    # :edge can be :left or :right
    def x_edge_position(edge)
      x_pos = x_position(as: :mm)
      x_pos += width(as: :mm) if edge == :right
      x_pos
    end

    # Returns the position of the edge of the key unit along the
    # Y-Plane, IN MM.
    # :edge can be :top or :bottom
    def y_edge_position(edge)
      y_pos = y_position(as: :mm)
      y_pos += height(as: :mm) if edge == :top
      y_pos
    end

    # Returns the position of the corner of the key unit IN MM.
    # `x` can be :left or :right
    # `y` can be :top or :bottom
    # returns hash of two float values, x and y
    def corner_position(x, y)
      { x: x_edge_position(x), y: y_edge_position(y) }
    end

    # finds the next key nearest in `direction`. Direction can be one of:
    # :above - in previous row
    # :below - in next row
    # :side - in same row
    def nearest_neighbor(direction)
      case direction
      when :above
        return if row.first?

        adjacent = nil
        adj_distance = nil
        # find closest on next row
        previous_row = row.layout.rows[row.number-1]
        return unless previous_row
        # p1 = {
        #   x: row_offset+(width/2),
        #   y: number.to_f-(height/2)+height
        # }

        previous_row.keys.each_with_index do |key|
          # p2 = {
          #   x: (key.row_offset)+(key.width/2),
          #   y: next_row.number.to_f-(key.height/2)+key.height
          # }

          # len = Math.sqrt( ((p1[:x]-p2[:x]).to_i**2) + ((p1[:y]-p2[:y]).to_i**2) )
          len  = distance_to(key)
          if !adj_distance || len < adj_distance
            adjacent = key
            adj_distance = len
          end
        end
        return adjacent

      when :below
        return if row.last?

        adjacent = nil
        adj_distance = nil
        # find closest on next row
        next_row = row.layout.rows[row.number+1]
        return unless next_row
        # p1 = {
        #   x: row_offset+(width/2),
        #   y: number.to_f-(height/2)+height
        # }

        next_row.keys.each_with_index do |key|
          # p2 = {
          #   x: (key.row_offset)+(key.width/2),
          #   y: next_row.number.to_f-(key.height/2)+key.height
          # }

          # len = Math.sqrt( ((p1[:x]-p2[:x]).to_i**2) + ((p1[:y]-p2[:y]).to_i**2) )
          len  = distance_to(key)
          if !adj_distance || len < adj_distance
            adjacent = key
            adj_distance = len
          end
        end
        return adjacent

      when :side
        raise NotImplementedError
      else
        raise ArgumentError, "Unknown direction #{direction.inspect}"
      end
    end

    # Returns the distance to `key` in unit, or MM if size of unit is given
    def distance_to(key)
      p1 = {
        x: (row_offset.to_f*unit_width)+((width(as: :mm))/2),
        y: (row.number.to_f*unit_height)-((height(as: :mm))/2)+(height(as: :mm))
      }

      p2 = {
        x: (key.row_offset.to_f*unit_width)+((key.width(as: :mm))/2),
        y: (key.row.number.to_f*unit_height)-((key.height(as: :mm))/2)+(key.height(as: :mm))
      }

      Math.sqrt( ((p1[:x]-p2[:x])**2) + ((p1[:y]-p2[:y])**2) ).round(2)
    end

    # returns the angle in degrees to `key`
    def angle_to(key)
      p1 = {
        x: (row_offset.to_f)+((width)/2),
        y: (row.number.to_f)-((height)/2)+(height)
      }

      p2 = {
        x: (key.row_offset.to_f)+((key.width)/2),
        y: (key.row.number.to_f)-((key.height)/2)+(key.height)
      }

      Math.atan2(p2[:x] - p1[:x], p2[:y] - p1[:y]) * 180 / Math::PI
    end

    def to_s
      "#{self.class}: #{position} #{legends.inspect}"
    end

    private

    def parse_settings
      settings.each do |k, v|
        case k
        when 'x'
          @additional_offset = v.to_f
        when 'w'
          @width = v.to_f
        when 'sm'
          # expected to be "alps" or "cherry"
          @switch_mount = v.to_s
        when 'sb'
          @switch_brand = v.to_s
        when 'st'
          @switch_type = v.to_s
        else
          warn "Unknown setting #{k.inspect} => #{v.inspect}"
        end
      end
    end

    def calculate_row_offset
      @row_offset ||= if number == 0
        additional_offset
      else
        additional_offset + row.keys[number-1].row_offset + row.keys[number-1].width
      end
    end
  end
end
