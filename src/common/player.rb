require_relative 'frontier'

class Player
  attr_accessor :color, :roads, :settlements, :cities
  attr_accessor :resource_cards, :development_cards

  def initialize(attributes)
    @color = attributes[:color]
    @roads = []
    @settlements = []
    @cities = []
    @reource_cards = ResourceCards.new
    @development_cards = DevelopmentCards.new
  end

  def available_roads()        15 - @roads.count       end
  def available_settlements()  5 - @settlements.count  end
  def available_cities()       4 - @cities.count       end
end
