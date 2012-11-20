require 'thread'

require_relative 'client'
require_relative 'constants'
require_relative 'gui'
require_relative 'render_shapes'
require_relative '../common/coordinates'
require_relative '../common/event'
require_relative '../common/frontier'
require_relative '../common/player'
require_relative '../common/util'

include Coords
include Gui
include Java

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

  def draw_board_foundation(buffer)
    path = scale_path(RenderShapes::PIECES[:board_foundation], @scale)
    x, y = tile_coords_to_render([3, 3], @scale)
    gfx = buffer.createGraphics
    gfx.setRenderingHint(RHint::KEY_ANTIALIASING, RHint::VALUE_ANTIALIAS_ON)
    gfx.setPaint(Color::WHITE)
    fill_shape(gfx, [vec(0,0,), path])
  end

  def draw_tile(tile, buffer)
    outer_hex = scale_shape(RenderShapes::HEX, @scale * 0.97)
    inner_hex = scale_shape(RenderShapes::HEX, @scale * 0.87)
    x, y = tile_coords_to_render(tile.coords, @scale)
    gfx = buffer.createGraphics
    gfx.setRenderingHint(RHint::KEY_ANTIALIASING, RHint::VALUE_ANTIALIAS_ON)
    gfx.translate(x, y)
    gfx.setPaint(COL_CREAM)
    fill_shape(gfx, outer_hex)
    gfx.setPaint(tile.terrain.palette.primary)
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
    draw_board_foundation(buffer)
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
      gfx.setColor(card.terrain.palette.primary)
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
