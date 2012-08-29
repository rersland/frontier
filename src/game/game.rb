class Resource
  attr_accessor :name
  def initialize(*args)
    @name = *args
  end
end

WOOD  = Resource.new "wood"
WHEAT = Resource.new "wheat"
CLAY  = Resource.new "clay"
ROCK  = Resource.new "rock"
SHEEP = Resource.new "sheep"

class Terrain
  attr_accessor :name, :text_symbol
  def initialize(*args)
    @name, @text_symbol = *args
  end

  def inspect()
    name.upcase
  end
end

FOREST   = Terrain.new("forest",   "f")
PLAINS   = Terrain.new("plains",   "p")
PASTURE  = Terrain.new("pasture",  "a")
HILLS    = Terrain.new("hills",    "h")
MOUNTAIN = Terrain.new("mountain", "m")
DESERT   = Terrain.new("desert",   "d")
TERRAINS = [FOREST, PLAINS, HILLS, MOUNTAIN, PASTURE, DESERT]

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

module IdObject
  attr_accessor :id

  def inspect()
    "#{send(:class)}:#{id}"
  end
end
