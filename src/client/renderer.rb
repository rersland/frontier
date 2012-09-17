require 'thread'

require_relative '../common/event'
require_relative '../common/frontier'
require_relative 'render_paths'

include Java

BufferedImage = java.awt.image.BufferedImage
AffineTransform = java.awt.geom.AffineTransform
BasicStroke = java.awt.BasicStroke
Color = java.awt.Color
Font = java.awt.Font
RHint = java.awt.RenderingHints

def scale_path(path, scale)
  xform = AffineTransform.new
  xform.scale(scale, scale)
  newpath = path.clone
  newpath.transform(xform)
  newpath
end

def make_circle(r, x=0, y=0)
  java.awt.geom.Ellipse2D::Double.new(x - r, y - r, r * 2, r * 2)
end

# :.....:.....:.....:.....:.....:.....:.....:.....:.....:.....:.....:.....:
# :     :     :     :     :     :     :     :     :     :     :     :     :
# :.....:.....:.....:.....X.....:.....X.....:.....X.....:.....:.....:.....:
# :     :     :     :  X  :  X  :  X  :  X  :  X  :  X  :     :     :     :
# :.....:.....:.....X.....:.....X.....:.....X.....:.....X.....:.....:.....:
# :     :     :     X     :     X     :     X     :     X     :     :     :
# :.....:.....:.....X.....:.....X.....:.....X.....:.....X.....:.....:.....:
# :     :     :     X     :     X     :     X     :     X     :     :     :
# :.....:.....:.....X.....:.....X.....:.....X.....:.....X.....:.....:.....:
# :     :     :  X  :  X  :  X  :  X  :  X  :  X  :  X  :  X  :     :     :
# :.....:.....X.....:.....X.....:.....X.....:.....X.....:.....X.....:.....:
# :     :     X     :     X     :     X     :     X     :     X     :     :
# :.....:.....X.....:.....X.....:.....X.....:.....X.....:.....X.....:.....:
# :     :     X     :     X     :     X     :     X     :     X     :     :
# :.....:.....X.....:.....X.....:.....X.....:.....X.....:.....X.....:.....:
# :     :  X  :  X  :  X  :  X  :  X  :  X  :  X  :  X  :  X  :  X  :     :
# :.....X.....:.....X.....:.....X.....:.....X.....:.....X.....:.....X.....:
# :     X     :     X     :     X     :     X     :     X     :     X     :
# :.....X.....:.....X.....:.....X.....:.....X.....:.....X.....:.....X.....:
# :     X     :     X     :     X     :     X     :     X     :     X     :
# :.....X.....:.....X.....:.....X.....:.....X.....:.....X.....:.....X.....:
# :     :  X  :  X  :  X  :  X  :  X  :  X  :  X  :  X  :  X  :  X  :     :
# :.....:.....X.....:.....X.....:.....X.....:.....X.....:.....X.....:.....:
# :     :     X     :     X     :     X     :     X     :     X     :     :
# :.....:.....X.....:.....X.....:.....X.....:.....X.....:.....X.....:.....:
# :     :     X     :     X     :     X     :     X     :     X     :     :
# :.....:.....X.....:.....X.....:.....X.....:.....X.....:.....X.....:.....:
# :     :     :  X  :  X  :  X  :  X  :  X  :  X  :  X  :  X  :     :     :
# :.....:.....:.....X.....:.....X.....:.....X.....:.....X.....:.....:.....:
# :     :     :     X     :     X     :     X     :     X     :     :     :
# :.....:.....:.....X.....:.....X.....:.....X.....:.....X.....:.....:.....:
# :     :     :     X     :     X     :     X     :     X     :     :     :
# :.....:.....:.....X.....:.....X.....:.....X.....:.....X.....:.....:.....:
# :     :     :     :  X  :  X  :  X  :  X  :  X  :  X  :     :     :     :
# :.....:.....:.....:.....X.....:.....X.....:.....X.....:.....:.....:.....:
# :     :     :     :     :     :     :     :     :     :     :     :     :
# :.....:.....:.....:.....:.....:.....:.....:.....:.....:.....:.....:.....:
BOARD_UNIT_X = RenderPaths::HR3
BOARD_UNIT_Y = 0.5
BOARD_UNITS_W = BOARD_UNIT_X * 12
BOARD_UNITS_H = BOARD_UNIT_Y * 18
BOARD_WH_RATIO = BOARD_UNITS_W / BOARD_UNITS_H

DETAIL_LINE_WEIGHT = 1.0 / 200.0
PIECE_LINE_WEIGHT = 1.0 / 75.0

class Terrain
  attr_accessor :color
end
FOREST.color   = Color.new( 40,  155, 0   )
PLAINS.color   = Color.new( 240, 210, 90  )
HILLS.color    = Color.new( 220, 90,  50  )
MOUNTAIN.color = Color.new( 160, 120, 70  )
PASTURE.color  = Color.new( 170, 240, 70  )
DESERT.color   = Color.new( 250, 250, 80  )

COL_CREAM      = Color.new( 230, 220, 150 )
COL_SEA        = Color.new( 40,  70,  160 )

def draw_centered_text(gfx, text, font, x, y, center_y = true)
  glyph_vector = font.createGlyphVector(gfx.getFontRenderContext(), text)
  #  bounds = glyph_vector.getBounds2D()
  bounds = glyph_vector.getVisualBounds()
  gfx.drawGlyphVector(glyph_vector,
                      (x - bounds.getCenterX()),
                      (center_y ? (y - bounds.getCenterY()) : y))
end

################################################################################
# RenderJob
################################################################################

class RenderJob
  attr_accessor :game, :scale
  def initialize(game, scale)
    @game = game
    @scale = scale
  end

  def detail_stroke()  BasicStroke.new(@scale * DETAIL_LINE_WEIGHT)  end
  def piece_stroke()   BasicStroke.new(@scale * PIECE_LINE_WEIGHT)   end
  def counter_number_font()  Font.new("Serif", Font::BOLD, (@scale * 0.32).to_i)   end
  def counter_letter_font()  Font.new("SansSerif", Font::PLAIN, (@scale * 0.15).to_i)  end

  def window_coords_to_board(x, y)
    i, yrem = y.divmod(BOARD_UNIT_Y * @scale)
    j, xrem = x.divmod(BOARD_UNIT_X * @scale)
    if i % 3 != 1
      row = (i % 3 == 0) ? (i / 3) : (i / 3) + 1
      ascending, above = nil, nil
    else
      ascending = (i % 6 == 1) ? (j % 2 == 1) : (j % 2 == 0)
      if ascending
        above = (BOARD_UNIT_Y * @scale - yrem) / xrem > BOARD_UNIT_Y / BOARD_UNIT_X
      else
        above = yrem / xrem < BOARD_UNIT_Y / BOARD_UNIT_X
      end
      #above = (ascending ? ((BOARD_UNIT_Y * @scale - yrem) / xrem > BOARD_UNIT_Y / BOARD_UNIT_X)
      #above = ((ascending ? (BOARD_UNIT_Y * @scale) - yrem : yrem) / xrem) < (BOARD_UNIT_Y / BOARD_UNIT_X)
      row = above ? (i / 3) : (i / 3) + 1
    end
    col = (j - 2 + row) / 2
    [row, col, ascending, above]
  end

  def board_coords_to_window(row, col)
    [((2 * col - row + 3) * BOARD_UNIT_X * @scale).to_i,
     ((3 * row) * BOARD_UNIT_Y * @scale).to_i]
  end

  def draw_tile(tile, buffer)
    outer_hex = scale_path(RenderPaths::HEX, @scale * 0.97)
    inner_hex = scale_path(RenderPaths::HEX, @scale * 0.87)
    x, y = board_coords_to_window(tile.row, tile.col)
    gfx = buffer.createGraphics
    gfx.setRenderingHint(RHint::KEY_ANTIALIASING, RHint::VALUE_ANTIALIAS_ON)
    gfx.translate(x, y)
    gfx.setPaint(COL_CREAM)
    gfx.fill(outer_hex)
    gfx.setPaint(tile.terrain.color)
    gfx.fill(inner_hex)
    gfx.setPaint(Color::BLACK)
    gfx.setStroke(detail_stroke())
    gfx.draw(outer_hex)
    gfx.draw(inner_hex)

    unless tile.counter.nil?
      # draw the circle
      circle = make_circle(@scale * 0.3)
      gfx.setPaint(COL_CREAM)
      gfx.fill(circle)
      gfx.setPaint(Color::BLACK)
      gfx.setStroke(piece_stroke())
      gfx.draw(circle)

      # draw the text
      num_pips = tile.counter.num_pips
      gfx.setPaint(num_pips == 5 ? Color::RED : Color::BLACK)
      draw_centered_text(gfx, tile.counter.number.to_s, counter_number_font(),
                         0.0, @scale * -0.05, true)

      # draw the pips
      xs = (0...num_pips).to_a.map {|x| x * @scale * 0.07}
      y = @scale * 0.16
      r = @scale * 0.03
      offset = -(xs.last - xs.first) / 2.0
      xs.each do |x|
        gfx.fill(make_circle(r, x + offset, y))
      end
    end
  end

  def draw_edge(edge, buffer)
    return unless edge.piece
    path = RenderPaths::PIECES[edge.piece.type][edge.alignment]
    path = scale_path(path, @scale)
    color = {red: Color::RED, blue: Color::BLUE, orange: Color::ORANGE,
      white: Color.new(220,220,220)}[edge.piece.player]
    x, y = board_coords_to_window(edge.row, edge.col)
    gfx = buffer.createGraphics
    gfx.setRenderingHint(RHint::KEY_ANTIALIASING, RHint::VALUE_ANTIALIAS_ON)
    gfx.translate(x, y)
    gfx.setPaint(color)
    gfx.fill(path)
    gfx.setPaint(Color::BLACK)
    gfx.setStroke(piece_stroke())
    gfx.draw(path)
  end

  def draw_vtex(vtex, buffer)
    return unless vtex.piece
    path = RenderPaths::PIECES[vtex.piece.type][vtex.alignment]
    path = scale_path(path, @scale)
    color = {red: Color::RED, blue: Color::BLUE, orange: Color::ORANGE,
      white: Color.new(220,220,220)}[vtex.piece.player]
    x, y = board_coords_to_window(vtex.row, vtex.col)
    gfx = buffer.createGraphics
    gfx.setRenderingHint(RHint::KEY_ANTIALIASING, RHint::VALUE_ANTIALIAS_ON)
    gfx.translate(x, y)
    gfx.setPaint(color)
    gfx.fill(path)
    gfx.setPaint(Color::BLACK)
    gfx.setStroke(piece_stroke())
    gfx.draw(path)
  end

  def draw_board()
    w, h = BOARD_UNITS_W * @scale, BOARD_UNITS_H * @scale
    buffer = BufferedImage.new(w, h, BufferedImage::TYPE_4BYTE_ABGR)
    @game.board.tiles.each {|tile| draw_tile(tile, buffer) }
    @game.board.edges.each {|edge| draw_edge(edge, buffer) }
    @game.board.vtexs.each {|vtex| draw_vtex(vtex, buffer) }
    return buffer
  end
end

################################################################################
# Renderer
################################################################################

class Renderer
  def initialize(game)
    @game = game
    @stop_thread = false
    @thread = nil
    @next_job = nil
    @mutex = Mutex.new
  end

  def start_thread
    @stop_thread = false
    @thread = Thread.new do
      while true do
        break if @stop_thread
        scale = @mutex.synchronize do
          this_job, @next_job = @next_job, nil
          this_job
        end
        if scale.nil?
#        scale = @next_job
#        if scale.nil?
          sleep(1.0)
        else
          job = RenderJob.new(@game, scale)
          board = job.draw_board()
          Event.emit(:render_job_done, board: board)
        end
      end
    end
  end

  def stop_thread
    @stop_thread = true
    @thread.join
  end

  def add_render_job(scale)
    @mutex.synchronize { @next_job = scale }
    @thread.wakeup if @thread.status == 'sleep'
  end
end

################################################################################
# BoardWindow
################################################################################

class BoardWindow < javax.swing.JPanel

  class ComponentListener < java.awt.event.ComponentAdapter
    def componentResized(evt)
      evt.source.on_resize
    end
  end

  def initialize()
    super
    @board_buffer = nil
    addComponentListener ComponentListener.new
  end

  def board_buffer=(bb)
    @board_buffer = bb
    repaint
  end

  def get_board_bounds()
    if (getWidth().to_f / getHeight().to_f > BOARD_WH_RATIO)
      w = (BOARD_WH_RATIO * getHeight()).to_i
      h = getHeight()
      x = (getWidth() - w) / 2
      y = 0
      return [x, y, w, h]
    else
      w = getWidth()
      h = (getWidth() / BOARD_WH_RATIO).to_i
      x = 0
      y = (getHeight() - h) / 2
      return [x, y, w, h]
    end
  end

  def paintComponent(gfx)
    super
    unless @board_buffer.nil?
      x, y, w, h = get_board_bounds()
      img = @board_buffer.getScaledInstance(w, h, java.awt.Image::SCALE_FAST)
      gfx.drawImage(img, x, y, nil)
    end
  end

  def on_resize()
    x, y, w, h = get_board_bounds()
    scale = (w.to_f / BOARD_UNITS_W)
    Event.emit(:request_render_job, scale: scale)
  end

end





require_relative '../common/board'
require_relative '../common/game'

board_text = "
                     *           *           *
                  *     *     *     *     *     *
               *           Rs          *           *
               *     p     R     f     *     d     *
               *           *           Bs          *
            *     *     *     R     B     *     *     *
         *           *           *           *           *
         *     m     *     a     R     m     *     a     *
         *           *           *           Os          *
      *     *     *     R     R     R     *     O     *     *
   *           Ws          Rc          *           *           *
   *     h     W     p11   R     p8    *     h5    O     m2    *
   *           *           *           Os          Os          *
      *     O     W     B     B     *     O     O     *     *
         Os          *           *           *           *
         *     a     W     f     B     p     W     a     *
         *           *           *           *           *
            *     W     *     *     B     *     W     *
               Ws          *           Bs          Ws
               *     h     R     f     *     f     *
               *           Rs          *           *
                  *     *     *     *     *     *
                     *           *           *
"

game = Game.new

b = Board.new
b.create_spaces
b.connect_spaces
b.load_text(board_text)
game.board = b

# r = Renderer.new
# r.game = game
# r.scale = 80

f = javax.swing.JFrame.new("Test Frame")

#img = r.draw_buffer
bwindow = BoardWindow.new
#bwindow.board_buffer = img

f.add bwindow
f.setDefaultCloseOperation javax.swing.WindowConstants::DISPOSE_ON_CLOSE
f.pack
f.setSize 800, 800

renderer = Renderer.new(game)

Event.start_thread
renderer.start_thread

Event.connect(:request_render_job) do |name, data|
  renderer.add_render_job(data[:scale])
end
Event.connect(:render_job_done) do |name, data|
  bwindow.board_buffer = data[:board]
end

class MainFrameListener < java.awt.event.WindowAdapter
  def windowClosed
    renderer.stop_thread()
    Event.stop_thread()
  end
end
f.addWindowListener MainFrameListener.new

f.setVisible true
