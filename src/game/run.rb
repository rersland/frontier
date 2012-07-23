require_relative 'board'

include Java

JFrame = javax.swing.JFrame
BufferedImage = java.awt.image.BufferedImage
Path = java.awt.geom.Path2D::Double
AffineTransform = java.awt.geom.AffineTransform
Color = java.awt.Color
BasicStroke = java.awt.BasicStroke
RHint = java.awt.RenderingHints

HR3 = (3.0 ** 0.5) / 2.0

COL_CREAM = Color.new(230, 220, 150)
COL_SEA   = Color.new(40, 70, 160)

class TileType
  attr_accessor :color
end
FOREST.color = Color.new(40, 155, 0)
PLAINS.color = Color.new(240, 210, 90)
HILLS.color = Color.new(220, 90, 50)
MOUNTAIN.color = Color.new(160, 120, 70)
PASTURE.color = Color.new(170, 240, 70)
DESERT.color = Color.new(250, 250, 80)

HEX_PATH = Path.new
HEX_PATH.moveTo  0.0, -1.0
HEX_PATH.lineTo  HR3, -0.5
HEX_PATH.lineTo  HR3,  0.5
HEX_PATH.lineTo  0.0,  1.0
HEX_PATH.lineTo -HR3,  0.5
HEX_PATH.lineTo -HR3, -0.5
HEX_PATH.lineTo  0.0, -1.0

def make_hex_path(scale=1.0)
  xform = AffineTransform.new
  xform.scale(scale, scale)
  path = HEX_PATH.clone
  path.transform(xform)
  path
  #p = Path.new
  #p.moveTo 0.0, -scale
  #p.lineTo HR3*scale, (-scale / 2.0)
  #p.lineTo HR3*scale, (scale / 2.0)
  #p.lineTo 0.0, scale
  #p.lineTo -HR3*scale, (scale / 2.0)
  #p.lineTo -HR3*scale, (-scale / 2.0)
  #p.lineTo 0.0, -scale
  #p
end

#HEX_PATH = make_hex_path

def render_tiles_picker(scale)
  hex = make_hex_path(1.0)
  rows = (0..6).to_a.zip([4,5,6,7,6,5,4]).map {|r, c| [r]*c}.flatten
  cols = [0..3, 0..4, 0..5, 0..6, 1..6, 2..6, 3..6].map {|x| x.to_a}.flatten
  
  w, h = HR3 * 12 * scale, 9 * scale
  img = BufferedImage.new(w, h, BufferedImage::TYPE_BYTE_GRAY)
  gfx = img.createGraphics
  gfx.setPaint(Color.new(0xff, 0xff, 0xff))
  gfx.fillRect(0, 0, img.getWidth, img.getHeight)
  
  colors = [Color::BLACK] + [Color::BLUE, Color::RED]*17 + [Color::BLUE, Color::BLACK]
  colors = [Color::BLUE, Color::GREEN, Color::BLACK, Color::RED, Color::ORANGE, Color::MAGENTA]*6 + [Color::BLUE]
  rows.zip(cols, colors).each do |row, col, color|
    x = ((2 * col - row + 3) * HR3 * scale).to_i
    y = ((1.5 * row - 0.0) * scale).to_i
    at = AffineTransform.new
    at.setToTranslation(x, y)
    hex = make_hex_path(scale+0.5)
    hex.transform(at)
    val = (row << 4) + col
    puts "#{row}, #{col}, #{val}"
    gfx.setPaint(Color.new(val, val, val))
    gfx.fill(hex)
  end
  
  img
end

class BoardViewImgs
  X_UNIT = HR3
  Y_UNIT = 0.5
  UNITS_W = X_UNIT * 12
  UNITS_H = Y_UNIT * 18
  LINE_WEIGHT = 1.0 / 200.0

  attr_reader :window_width, :window_height
  attr_reader :width, :height, :xoff, :yoff, :scale
  attr_reader :board, :tiles_buffer
  
  def initialize(window_width, window_height, board)
    @window_width = window_width
    @window_height = window_height
    @board = board
    wscale = window_width / UNITS_W
    hscale = window_height / UNITS_H
    @scale = (wscale < hscale) ? wscale : hscale
    @width = scale * UNITS_W
    @height = scale * UNITS_H
    @xoff = (window_width - width) / 2
    @yoff = (window_height - height) / 2
    
    render_tiles_buffer
  end
  
  def draw_centered(gfx, img, x, y)
    gfx.drawImage(img, x - (img.getWidth / 2.0), y - (img.getHeight / 2.0), nil)
  end
  
  def render_tile_types()
    path1 = make_hex_path(scale * 0.97)
    path2 = make_hex_path(scale * 0.87)
    w, h = (X_UNIT * 2 * scale).to_i, (Y_UNIT * 4 * scale).to_i
    mx, my = w / 2.0, h / 2.0
    Hash[
      TILE_TYPES.map do |type|
        img = BufferedImage.new(w, h, BufferedImage::TYPE_4BYTE_ABGR)
        gfx = img.createGraphics
        gfx.setRenderingHint(RHint::KEY_ANTIALIASING, RHint::VALUE_ANTIALIAS_ON)
        gfx.translate(mx, my)
        gfx.setPaint(COL_CREAM)
        gfx.fill(path1)
        gfx.setPaint(type.color)
        gfx.fill(path2)
        gfx.setPaint(Color::BLACK)
        gfx.setStroke(BasicStroke.new(scale * LINE_WEIGHT))
        gfx.draw(path1)
        gfx.draw(path2)
        [type, img]
      end
    ]
  end
  
  def render_tiles_buffer()
    tile_imgs = render_tile_types()
    
    @tiles_buffer = BufferedImage.new(width, height, BufferedImage::TYPE_4BYTE_ABGR)
    gfx = tiles_buffer.createGraphics
    gfx.setRenderingHint(RHint::KEY_ANTIALIASING, RHint::VALUE_ANTIALIAS_ON)
    
    board.tiles.each do |tile|
      x, y = tile_coords_to_point(tile.row, tile.col)
      draw_centered(gfx, tile_imgs[tile.type], x, y)
    end
  end
  
  def point_to_tile_coords(x, y)
    i, yrem = y.divmod(Y_UNIT * scale)
    j, xrem = x.divmod(X_UNIT * scale)
    if i % 3 != 1
      row = (i % 3 == 0) ? (i / 3) : (i / 3) + 1
      ascending, above = nil, nil
    else
      ascending = (i % 6 == 1) ? (j % 2 == 1) : (j % 2 == 0)
      if ascending
        above = (Y_UNIT * scale - yrem) / xrem > Y_UNIT / X_UNIT
      else
        above = yrem / xrem < Y_UNIT / X_UNIT
      end
      #above = (ascending ? ((Y_UNIT * scale - yrem) / xrem > Y_UNIT / X_UNIT)
      #above = ((ascending ? (Y_UNIT * scale) - yrem : yrem) / xrem) < (Y_UNIT / X_UNIT)
      row = above ? (i / 3) : (i / 3) + 1
    end
    col = (j - 2 + row) / 2
    [row, col, ascending, above]
  end
  
  def tile_coords_to_point(row, col)
    [((2 * col - row + 3) * X_UNIT * scale).to_i,
     ((3 * row) * Y_UNIT * scale).to_i]
  end
end

class BoardView < javax.swing.JPanel
  attr_reader :imgs, :board
  
  class MouseListener < java.awt.event.MouseAdapter
    def mouseClicked(evt)
      results = evt.source.point_to_tile_coords(evt.getX, evt.getY)
      puts "#{results.inspect}"
    end
    
    def mouseMoved(evt)
      imgs = evt.source.imgs
      row, col = imgs.point_to_tile_coords(evt.getX - imgs.xoff, evt.getY - imgs.yoff)
      evt.source.highlight = [row, col]
    end
  end
  
  class ComponentListener < java.awt.event.ComponentAdapter
    def componentResized(evt)
      evt.source.update_size
    end
  end
  
  def initialize()#(board)
    super
    #@board = board
    @highlight = nil
    @imgs = BoardViewImgs.new(600, 500, $b)#board)
    setPreferredSize(java.awt.Dimension.new(600, 500))
    
    addMouseListener MouseListener.new
    addMouseMotionListener MouseListener.new
    addComponentListener ComponentListener.new
  end
  
  def point_to_tile_coords(x, y)
    imgs.point_to_tile_coords(x - imgs.xoff, y - imgs.yoff)
  end
  
  def paintComponent(gfx)
    gfx.setPaint(Color::WHITE)#COL_SEA)
    gfx.fill(getBounds())
    gfx.drawImage(@imgs.tiles_buffer, @imgs.xoff, @imgs.yoff, nil)
    
    if not highlight.nil?
      x, y = imgs.tile_coords_to_point(*highlight)
      gfx.setPaint(Color::BLACK)
      gfx.fillOval(x + imgs.xoff - 10, y + imgs.yoff - 10, 20, 20)
    end
  end
  
  def update_size()
    @imgs = BoardViewImgs.new(getWidth, getHeight, $b)
    repaint
  end
  
  def highlight() @highlight end
  def highlight=(coords)
    coords = nil if not $b.tile_map.has_key?(coords)
    if @highlight != coords
      @highlight = coords
      repaint
    end
  end
end

class TestFrame < JFrame
  def initialize()
    super("Test Frame")
    
    board_view = BoardView.new#($b)
    add board_view
    
    setDefaultCloseOperation JFrame::EXIT_ON_CLOSE
    pack
    setVisible true
  end
end

f = TestFrame.new
