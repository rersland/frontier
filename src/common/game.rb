require_relative 'frontier'

class Game
  attr_accessor :board, :players
  def initialize(*args)
    @board = nil
    @players = {}
  end
end
