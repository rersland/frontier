require_relative 'gui'

include Gui

class Terrain
  attr_accessor :palette
end
FOREST.palette   = ColorPalette.new( primary: '30a000' )
PLAINS.palette   = ColorPalette.new( primary: 'f0d058' )
HILLS.palette    = ColorPalette.new( primary: 'e05830' )
MOUNTAIN.palette = ColorPalette.new( primary: 'a08048' )
PASTURE.palette  = ColorPalette.new( primary: 'b0f048' )
DESERT.palette   = ColorPalette.new( primary: 'f8f850' )

COL_CREAM       = Color.new( 230, 220, 150 )
COL_SEA         = Color.new(  40,  70, 160 )
COL_HIGHLIGHT   = Color.new( 180, 250, 210 )

COL_CARD_BORDER = Color::BLACK
COL_CARD_BG     = Color.new( 192, 192, 192 )
