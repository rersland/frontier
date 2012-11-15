require_relative 'util'

class Resource
  attr_accessor :name, :terrain

  def initialize(attributes)
    set_attributes(attributes)
  end
end

class Terrain
  attr_accessor :name, :text_symbol, :resource

  def initialize(attributes)
    set_attributes(attributes)
    resource.terrain = self unless resource.nil?
  end

  def inspect()
    @name.upcase
  end
end

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

  def num_pips()
    #        number:  2  3  4  5  6    7  8  9 10 11 12
    return [nil, nil, 1, 2, 3, 4, 5, nil, 5, 4, 3, 2, 1][@number]
  end
end

class GamePiece
  attr_accessor :type, :player
  def initialize(*args)
    @type, @player = *args
  end
end



LUMBER = Resource.new(name: "lumber")
GRAIN  = Resource.new(name: "grain")
BRICK  = Resource.new(name: "brick")
ORE    = Resource.new(name: "ore")
WOOL   = Resource.new(name: "wool")

FOREST   = Terrain.new(name: "forest",   text_symbol: "f", resource: LUMBER)
PLAINS   = Terrain.new(name: "plains",   text_symbol: "p", resource: GRAIN)
PASTURE  = Terrain.new(name: "pasture",  text_symbol: "a", resource: WOOL)
HILLS    = Terrain.new(name: "hills",    text_symbol: "h", resource: BRICK)
MOUNTAIN = Terrain.new(name: "mountain", text_symbol: "m", resource: ORE)
DESERT   = Terrain.new(name: "desert",   text_symbol: "d")
TERRAINS = [FOREST, PLAINS, HILLS, MOUNTAIN, PASTURE, DESERT]

class ResourceHand
  attr_accessor :cards
  def initialize(cards=nil)
    @cards = cards || []
  end
end
