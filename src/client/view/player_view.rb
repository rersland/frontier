require_relative '../gui'
require_relative 'card_view'

include Gui

################################################################################
# PlayerView
################################################################################
class PlayerView < JPanel
  attr_accessor :client

  def initialize()
    super
    @client = nil
    setLayout javax.swing.BoxLayout.new(self, javax.swing.BoxLayout::Y_AXIS)
  end

  def setCards(cards)
    removeAll
    cards.each do |card|
      add CardView.new(card)
    end
  end
end
