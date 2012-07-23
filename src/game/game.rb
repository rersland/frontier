class Resource
  attr_accessor :name
  def initialize(*args)
    name = *args
  end
end

WOOD  = Resource.new "wood"
WHEAT = Resource.new "wheat"
CLAY  = Resource.new "clay"
ROCK  = Resource.new "rock"
SHEEP = Resource.new "sheep"

class TileType
  attr_accessor :name
  def initialize(*args)
    name = *args
  end
end

FOREST   = TileType.new "forest"
PLAINS   = TileType.new "plains"
HILLS    = TileType.new "hills"
MOUNTAIN = TileType.new "mountain"
PASTURE  = TileType.new "pasture"
DESERT   = TileType.new "desert"
TILE_TYPES = [FOREST, PLAINS, HILLS, MOUNTAIN, PASTURE, DESERT]

class TileCounter
  attr_accessor :letter, :number
  def initialize(*args)
    letter, number = *args
  end
end

module IdObject
  attr_accessor :id

  def inspect()
    "#{send(:class)}:#{id}"
  end
end
