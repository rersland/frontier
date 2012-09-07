class Object
  # Takes a hash of attribute names and values, and assigns each value to the named attribute.
  def set_attributes(attributes, defaults={})
    attributes.each do |attr, value|
      public_send("#{attr}=".to_sym, value)
    end
    defaults.each do |attr, default|
      public_send("#{attr}=".to_sym, default) if public_send(attr).nil?
    end
  end
end



class Resource
  attr_accessor :name

  def initialize(attributes)
    set_attributes(attributes)
  end
end

WOOD  = Resource.new(name: "wood")
WHEAT = Resource.new(name: "wheat")
CLAY  = Resource.new(name: "clay")
ROCK  = Resource.new(name: "rock")
SHEEP = Resource.new(name: "sheep")

class Terrain
  attr_accessor :name, :text_symbol

  def initialize(attributes)
    set_attributes(attributes)
  end

  def inspect()
    @name.upcase
  end
end

FOREST   = Terrain.new(name: "forest",   text_symbol: "f")
PLAINS   = Terrain.new(name: "plains",   text_symbol: "p")
PASTURE  = Terrain.new(name: "pasture",  text_symbol: "a")
HILLS    = Terrain.new(name: "hills",    text_symbol: "h")
MOUNTAIN = Terrain.new(name: "mountain", text_symbol: "m")
DESERT   = Terrain.new(name: "desert",   text_symbol: "d")
TERRAINS = [FOREST, PLAINS, HILLS, MOUNTAIN, PASTURE, DESERT]

module IdObject
  attr_accessor :id

  def inspect()
    "#{public_send(:class)}:#{id}"
  end
end

class TileCounter
  attr_accessor :letter, :number
  def initialize(*args)
    @letter, @number = *args
  end
end

class GamePiece
  attr_accessor :type, :player
  def initialize(*args)
    @type, @player = *args
  end
end
