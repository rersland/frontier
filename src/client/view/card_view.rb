require_relative '../gui'

include Gui

################################################################################
# CardView
################################################################################
class CardView < JPanel
  def initialize(card)
    super()
    @card = card
    setMinimumSize   dim(100, 50)
    setPreferredSize dim(200, 50)
    setMaximumSize   dim(200, 50)
    add_margins([4, 4, 4, 4])
  end

  def paintComponent(gfx)
    super

    gfx.setRenderingHint(RHint::KEY_ANTIALIASING, RHint::VALUE_ANTIALIAS_ON)
    gfx.setColor COL_CARD_BORDER
    x, y, w, h = *get_inset_bounds()
    gfx.fillRoundRect(x, y, w, h, 10, 10)
    gfx.setColor @card.terrain.palette.primary
    gfx.fillRect(x+4, y+4, w-8, h-8)

    font = Font.new("SansSerif", Font::BOLD, 14)
    x = self.getWidth() / 2
    y = self.getHeight() / 2
    draw_text(gfx, @card.name, font, x, y, color: Color::BLACK,
              center_x: true, center_y: true)
  end
end
