require 'thread'

require_relative '../common/coordinates'
require_relative '../common/event'
require_relative '../common/frontier'
require_relative '../common/player'
require_relative '../common/util'
require_relative 'render_shapes'
require_relative 'client'

include Coords

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
  return newpath
end

def scale_shape(shape, scale1, scale2=nil)
  scale2 ||= scale1
  orig, path = *shape
  return [orig * scale1, scale_path(path, scale2)]
end

def make_circle(r, x=0, y=0)
  [vec(x, y), java.awt.geom.Ellipse2D::Double.new(-r, -r, r * 2, r * 2)]
end

def draw_centered_text(gfx, text, font, x, y, center_y = true)
  glyph_vector = font.createGlyphVector(gfx.getFontRenderContext(), text)
  #  bounds = glyph_vector.getBounds2D()
  bounds = glyph_vector.getVisualBounds()
  gfx.drawGlyphVector(glyph_vector,
                      (x - bounds.getCenterX()),
                      (center_y ? (y - bounds.getCenterY()) : y))
end

def draw_text(gfx, text, font, x, y, args)
  frc = gfx.getFontRenderContext()
  glyph_vector = font.createGlyphVector(frc, text)
  bounds = glyph_vector.getVisualBounds()
  x -= bounds.getCenterX() if args[:center_x]
  y -= bounds.getCenterY() if args[:center_y]
  gfx.setColor(args[:color]) if args[:color]
  y += font.getLineMetrics(text, frc).getHeight * args[:line] if args[:line]
  gfx.drawGlyphVector(glyph_vector, x, y)
end

def draw_centered_image(gfx, img, x, y)
  w, h = img.getWidth(), img.getHeight()
  gfx.drawImage(img, x - w/2, y - h/2, nil)
end

def draw_shape(gfx, shape)
  o, path = *shape
  gfx.translate(o.x, o.y)
  gfx.draw(path)
  gfx.translate(-o.x, -o.y)
end

def fill_shape(gfx, shape)
  o, path = *shape
  gfx.translate(o.x, o.y)
  gfx.fill(path)
  gfx.translate(-o.x, -o.y)
end

DETAIL_LINE_WEIGHT = 1.0 / 200.0
PIECE_LINE_WEIGHT = 1.0 / 75.0

REPAINT_BLOCK_X = -(SECTOR_W + 0.5)
REPAINT_BLOCK_Y = -(SECTOR_H * 2 + 0.5)
REPAINT_BLOCK_W = SECTOR_W * 2 + 1.0
REPAINT_BLOCK_H = SECTOR_H * 4 + 1.0

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
COL_HIGHLIGHT  = Color.new( 180, 250, 210 )

################################################################################
# BoardRenderJob
################################################################################
class BoardRenderJob
  attr_accessor :game, :scale
  def initialize(game, scale)
    @game = game
    @scale = scale
  end

  def detail_stroke()  BasicStroke.new(@scale * DETAIL_LINE_WEIGHT)  end
  def piece_stroke()   BasicStroke.new(@scale * PIECE_LINE_WEIGHT)   end
  def counter_number_font()  Font.new("Serif", Font::BOLD, (@scale * 0.32).to_i)   end
  def counter_letter_font()  Font.new("SansSerif", Font::PLAIN, (@scale * 0.15).to_i)  end

  def draw_tile(tile, buffer)
    outer_hex = scale_shape(RenderShapes::HEX, @scale * 0.97)
    inner_hex = scale_shape(RenderShapes::HEX, @scale * 0.87)
    x, y = tile_coords_to_render(tile.coords, @scale)
    gfx = buffer.createGraphics
    gfx.setRenderingHint(RHint::KEY_ANTIALIASING, RHint::VALUE_ANTIALIAS_ON)
    gfx.translate(x, y)
    gfx.setPaint(COL_CREAM)
    fill_shape(gfx, outer_hex)
    gfx.setPaint(tile.terrain.color)
    fill_shape(gfx, inner_hex)
    gfx.setPaint(Color::BLACK)
    gfx.setStroke(detail_stroke())
    draw_shape(gfx, outer_hex)
    draw_shape(gfx, inner_hex)

    unless tile.counter.nil?
      # draw the circle
      circle = make_circle(@scale * 0.3)
      gfx.setPaint(COL_CREAM)
      fill_shape(gfx, circle)
      gfx.setPaint(Color::BLACK)
      gfx.setStroke(piece_stroke())
      draw_shape(gfx, circle)

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
        fill_shape(gfx, make_circle(r, x + offset, y))
      end
    end
  end

  def draw_edge(edge, buffer)
    return unless edge.piece
    shape = RenderShapes::PIECES[edge.piece.type][edge.alignment]
    shape = scale_shape(shape, @scale)
    color = {red: Color::RED, blue: Color::BLUE, orange: Color::ORANGE,
      white: Color.new(220,220,220)}[edge.piece.player]
    x, y = tile_coords_to_render([edge.row, edge.col], @scale)
    gfx = buffer.createGraphics
    gfx.setRenderingHint(RHint::KEY_ANTIALIASING, RHint::VALUE_ANTIALIAS_ON)
    gfx.translate(x, y)
    gfx.setPaint(color)
    fill_shape(gfx, shape)
    gfx.setPaint(Color::BLACK)
    gfx.setStroke(piece_stroke())
    draw_shape(gfx, shape)
  end

  def draw_vtex(vtex, buffer)
    return unless vtex.piece
    shape = RenderShapes::PIECES[vtex.piece.type][vtex.alignment]
    shape = scale_shape(shape, @scale)
    color = {red: Color::RED, blue: Color::BLUE, orange: Color::ORANGE,
      white: Color.new(220,220,220)}[vtex.piece.player]
    x, y = tile_coords_to_render([vtex.row, vtex.col], @scale)
    gfx = buffer.createGraphics
    gfx.setRenderingHint(RHint::KEY_ANTIALIASING, RHint::VALUE_ANTIALIAS_ON)
    gfx.translate(x, y)
    gfx.setPaint(color)
    fill_shape(gfx, shape)
    gfx.setPaint(Color::BLACK)
    gfx.setStroke(piece_stroke())
    draw_shape(gfx, shape)
  end

  def draw_board()
    w, h = BOARD_W * @scale, BOARD_H * @scale
    buffer = BufferedImage.new(w, h, BufferedImage::TYPE_4BYTE_ABGR)
    @game.board.tiles.each {|tile| draw_tile(tile, buffer) }
    @game.board.edges.each {|edge| draw_edge(edge, buffer) }
    @game.board.vtexs.each {|vtex| draw_vtex(vtex, buffer) }
    return buffer
  end

  def draw_highlight(shape, factor)
    orig, path = *shape
    path = path.clone
    path.append(scale_path(path, factor), false)
    path.setWindingRule(java.awt.geom.Path2D::WIND_EVEN_ODD)
    path = scale_path(path, @scale)
    shape = [orig, path]

    buffer = BufferedImage.new((SECTOR_W * 4 * @scale).to_i,
                               (SECTOR_H * 6 * @scale).to_i,
                               BufferedImage::TYPE_4BYTE_ABGR)
    gfx = buffer.createGraphics
    gfx.setRenderingHint(RHint::KEY_ANTIALIASING, RHint::VALUE_ANTIALIAS_ON)
    gfx.translate(buffer.getWidth() / 2.0, buffer.getHeight() / 2.0)
    gfx.setColor(COL_HIGHLIGHT)
    fill_shape(gfx, shape)
    gfx.setStroke(detail_stroke())
    gfx.setColor(Color::BLACK)
    draw_shape(gfx, shape)
    return buffer
  end

  def render()
    return {
      board: draw_board(),
      highlight: {
        tile:  draw_highlight(RenderShapes::HEX, 1.1),
      },
#      hand: HandRenderJob.new($player, @scale).render
    }
  end
end

################################################################################
# HandRenderJob
################################################################################
class HandRenderJob
  def initialize(player, scale)
    @player = player
    @scale = scale
  end

  def render_resources()
    num_resources = @player.resources.cards.count

    w = (scale * 12).to_i
    h = (scale * 2).to_i
    border = 3

    buffer = BufferedImage.new(w, h * num_resources, BufferedImage::TYPE_BYTE_ABGR)
    gfx = buffer.createGraphics
    @player.resources.cards.each_with_index do |card, i|
      gfx.setColor(card.terrain.color)
      gfx.fillRect(0, h * i, w, h)
      gfx.setColor(Color::WHITE)
      gfx.fillRect(border, h * i + border, w - border * 2, h - border * 2)
    end

    return buffer
  end

  def render()
    return render_resources
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
          sleep(1.0)
        else
          job = BoardRenderJob.new(@game, scale)
          buffers = job.render()
          Event.emit(:render_job_done, buffers)
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
  attr_accessor :client

  class ComponentListener < java.awt.event.ComponentAdapter
    def componentResized(evt)
      evt.source.on_resize
    end
  end

  class MouseListener < java.awt.event.MouseAdapter
#    def mouseClicked(evt)
#      results = evt.source.point_to_tile_coords(evt.getX, evt.getY)
#      puts "#{results.inspect}"
#    end
    def mouseMoved(evt)
      evt.source.on_mouse_moved(evt.getX, evt.getY)
    end
  end

  def initialize()
    super
    @client = nil
    @bounds = nil
    @scale = nil
    @buffers = {}
    @buffers_mutex = Mutex.new
    @highlight_type = nil
    @highlight_coords = nil
    @highlight_mutex = Mutex.new
    addComponentListener ComponentListener.new
    addMouseListener MouseListener.new
    addMouseMotionListener MouseListener.new
  end

  def set_buffers(buffers)
    @buffers_mutex.synchronize { @buffers = buffers }
    repaint
  end

  def repaint_block(coords)
    row, col, alignment = coords
    x, y = board_coords_to_component(*tile_coords_to_board([row, col]))
    repaint(0,
            (x + REPAINT_BLOCK_X * @scale).to_i,
            (y + REPAINT_BLOCK_Y * @scale).to_i,
            (REPAINT_BLOCK_W * @scale).to_i,
            (REPAINT_BLOCK_H * @scale).to_i)
  end

  def set_highlight(type, coords)
    old_coords = @highlight_mutex.synchronize do
      old_coords = @highlight_coords
      @highlight_type, @highlight_coords = type, coords
      old_coords
    end
    repaint_block(old_coords) unless old_coords.nil?
    repaint_block(coords) unless coords.nil?
  end

  def xy_to_bounds(x, y)
    return [x + @bounds[0], y + @bounds[1]]
  end

  def xy_from_bounds(x, y)
    return [x - @bounds[0], y - @bounds[1]]
  end

  def component_coords_to_board(x, y)
    return [(x - @bounds[0]) / @scale,
            (y - @bounds[1]) / @scale]
  end

  def board_coords_to_component(x, y)
    return [(x * @scale + @bounds[0]).to_i,
            (y * @scale + @bounds[1]).to_i]
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
    @buffers_mutex.synchronize do
      if @buffers[:board]
        x, y, w, h = @bounds
        img = @buffers[:board].getScaledInstance(w, h, java.awt.Image::SCALE_FAST)
        gfx.drawImage(img, x, y, nil)
      end

      @highlight_mutex.synchronize do
        if @highlight_coords and @buffers[:highlight]
          x, y = xy_to_bounds(*tile_coords_to_render(@highlight_coords, @scale))
          draw_centered_image(gfx, @buffers[:highlight][@highlight_type], x, y)
#          gfx.setStroke(BasicStroke.new(3))
#          gfx.drawRect((x + REPAINT_BLOCK_X * @scale).to_i,
#                       (y + REPAINT_BLOCK_Y * @scale).to_i,
#                       (REPAINT_BLOCK_W * @scale).to_i,
#                       (REPAINT_BLOCK_H * @scale).to_i)
        end
      end
    end
  end

  def on_resize()
    @bounds = get_board_bounds()
    @scale = (@bounds[2].to_f / BOARD_W)
    Event.emit(:request_render_job, scale: @scale)
  end

  def on_mouse_moved(mx, my)
    coords = tile_coords_under_point(*component_coords_to_board(mx, my))
    coords = nil unless @client.game.board.tile_map.has_key?(coords)
    old_coords = @highlight_mutex.synchronize { @highlight_coords }
    set_highlight(:tile, coords) if coords != old_coords
  end
end


class PlayerWindow < javax.swing.JPanel
  attr_accessor :client

  def initialize()
    @client = nil
  end

  def paintComponent(gfx)
    super
    setBackground Color::WHITE
    cards = @client.local_player.resources
    font = Font.new("SansSerif", Font::BOLD, 14)
    cards.each_with_index do |resource, i|
      draw_text(gfx, resource.name, font, 20, 30,
                color: resource.terrain.color,
                line: i)
    end
  end
end



require_relative '../common/board'
require_relative '../common/game'

$board_text = "
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

# board_text = "
#                      *           *           *
#                   *     R     *     *     *     *
#                *           *           *           *
#                *     p     R     f     *     d     *
#                *           *           *           *
#             *     *     R     *     *     *     *     *
#          *           Rc          *           *           *
#          *     m     *     a     *     m     *     a     *
#          *           *           *           *           *
#       *     *     *     *     *     *     *     *     *     *
#    *           *           *           *           Rs          *
#    *     h     *     p11   *     p8    *     h5    *     m2    *
#    *           *           *           *           *           *
#       *     *     *     *     *     *     *     *     *     *
#          *           *           *           *           *
#          *     a     *     f     *     p     *     a     *
#          *           *           *           *           *
#             *     *     *     *     *     *     *     *
#                *           *           *           *
#                *     h     *     f     *     f     *
#                *           *           *           *
#                   *     *     *     *     *     *
#                      *           *           *
# "

class MainFrameListener < java.awt.event.WindowAdapter
  def windowClosed
    puts "MainFrameListener: window closed"
    renderer.stop_thread()
    Event.stop_thread()
    puts "MainFrameListener: threads stopped"
  end
end

class TestFrame < javax.swing.JFrame
  def initialize
    super

    ############################################################################
    # client setup

    @client = Client.new

    game = Game.new
    @client.game = game

    b = Board.new
    b.create_spaces
    b.connect_spaces
    b.load_text($board_text)
    game.board = b

    # puts "################################################################################"
    # puts game.board.inspect
    # puts "################################################################################"

    game.players = {
      red: Player.new(color: :red),
      blue: Player.new(color: :blue),
      orange: Player.new(color: :orange),
      white: Player.new(color: :white),
    }

    local_player = game.players[:red]
    @client.local_player = local_player
    local_player.resources = [LUMBER, GRAIN, WOOL, ORE, BRICK]

    ############################################################################
    # layout setup

    cp = getContentPane()

    layout = javax.swing.BoxLayout.new(cp, javax.swing.BoxLayout::X_AXIS)
    cp.setLayout layout

    @player_window = PlayerWindow.new
    @player_window.setMinimumSize   dim(200, 10)
    @player_window.setPreferredSize dim(200, 100)
    @player_window.setMaximumSize   dim(200, 10000)
    cp.add @player_window

    @board_window = BoardWindow.new
    @board_window.setMinimumSize    dim(200, 10)
    @board_window.setPreferredSize  dim(400, 100)
    @board_window.setMaximumSize    dim(1000, 10000)
    cp.add @board_window

    @player_window.client = @client
    @board_window.client = @client

#    setDefaultCloseOperation javax.swing.WindowConstants::DISPOSE_ON_CLOSE
    setDefaultCloseOperation javax.swing.JFrame::EXIT_ON_CLOSE
    setSize 1000, 800
    setLocation 400, 100
    setVisible true
  end

  def run

    renderer = Renderer.new(@client.game)

    Thread.abort_on_exception = true

    Event.start_thread
    renderer.start_thread

    Event.connect(:request_render_job) do |name, data|
      renderer.add_render_job(data[:scale])
    end
    Event.connect(:render_job_done) do |name, buffers|
      @board_window.set_buffers(buffers)
    end

    addWindowListener MainFrameListener.new

  end
end

TestFrame.new().run()
