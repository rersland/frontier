require_relative '../gui'
require_relative '../constants'
require_relative '../../common/coordinates'
require_relative '../../common/event'

include Coords
include Gui

################################################################################
# BoardView
################################################################################
class BoardView < JPanel
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
    setBackground COL_SEA
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


