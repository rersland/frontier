require_relative 'frontier'

class Player
  attr_accessor :color, :num_roads, :num_settlements, :num_cities, :hand

  def initialize(attributes)
    @color = attributes[:color]
    @num_roads = 15
    @num_settlements = 5
    @num_cities = 4
  end
end
