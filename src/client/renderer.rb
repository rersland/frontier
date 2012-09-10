require_relative '../common/frontier'

include Java

BufferedImage = java.awt.image.BufferedImage
Path = java.awt.geom.Path2D::Double
AffineTransform = java.awt.geom.AffineTransform
Color = java.awt.Color
BasicStroke = java.awt.BasicStroke
RHint = java.awt.RenderingHints

HR3 = (3.0 ** 0.5) / 2.0

VEC_0  =  [  0.0, -1.0 ]
VEC_30 =  [  0.5, -HR3 ]
VEC_60 =  [  HR3, -0.5 ]
VEC_90 =  [  1.0,  0.0 ]
VEC_120 = [  HR3,  0.5 ]
VEC_150 = [  0.5,  HR3 ]
VEC_180 = [  0.0,  1.0 ]
VEC_210 = [ -0.5,  HR3 ]
VEC_240 = [ -HR3,  0.5 ]
VEC_270 = [ -1.0,  0.0 ]
VEC_300 = [ -HR3, -0.5 ]
VEC_330 = [ -0.5, -HR3 ]

def vec_add(*vecs)
  [vecs.map {|v| v[0]}.reduce(:+),
   vecs.map {|v| v[1]}.reduce(:+)]
end
def vec_scale(v1, f)
  [v1[0] * f, v1[1] * f]
end
def lerp(v1, v2, f)
  [v1[0] + (v2[0] - v1[0]) * f,
   v1[1] + (v2[1] - v1[1]) * f]
end


# hex path

HEX_PATH = Path.new
HEX_PATH.moveTo *VEC_0
HEX_PATH.lineTo *VEC_60
HEX_PATH.lineTo *VEC_120
HEX_PATH.lineTo *VEC_180
HEX_PATH.lineTo *VEC_240
HEX_PATH.lineTo *VEC_300
HEX_PATH.lineTo *VEC_0

# edge paths

stepf = 0.06
pf = 0.22

p1 = lerp(VEC_300, VEC_0, pf)
p2 = lerp(VEC_300, VEC_0, 1 - pf)
ASC_ROAD_PATH = Path.new
ASC_ROAD_PATH.moveTo *vec_add(p1, vec_scale(VEC_330, stepf))
ASC_ROAD_PATH.lineTo *vec_add(p2, vec_scale(VEC_330, stepf))
ASC_ROAD_PATH.lineTo *vec_add(p2, vec_scale(VEC_150, stepf))
ASC_ROAD_PATH.lineTo *vec_add(p1, vec_scale(VEC_150, stepf))
ASC_ROAD_PATH.lineTo *vec_add(p1, vec_scale(VEC_330, stepf))

p1 = lerp(VEC_0, VEC_60, pf)
p2 = lerp(VEC_0, VEC_60, 1 - pf)
DESC_ROAD_PATH = Path.new
DESC_ROAD_PATH.moveTo *vec_add(p1, vec_scale(VEC_30, stepf))
DESC_ROAD_PATH.lineTo *vec_add(p2, vec_scale(VEC_30, stepf))
DESC_ROAD_PATH.lineTo *vec_add(p2, vec_scale(VEC_210, stepf))
DESC_ROAD_PATH.lineTo *vec_add(p1, vec_scale(VEC_210, stepf))
DESC_ROAD_PATH.lineTo *vec_add(p1, vec_scale(VEC_30, stepf))

p1 = lerp(VEC_240, VEC_300, pf)
p2 = lerp(VEC_240, VEC_300, 1 - pf)
VERT_ROAD_PATH = Path.new
VERT_ROAD_PATH.moveTo *vec_add(p1, vec_scale(VEC_90, stepf))
VERT_ROAD_PATH.lineTo *vec_add(p2, vec_scale(VEC_90, stepf))
VERT_ROAD_PATH.lineTo *vec_add(p2, vec_scale(VEC_270, stepf))
VERT_ROAD_PATH.lineTo *vec_add(p1, vec_scale(VEC_270, stepf))
VERT_ROAD_PATH.lineTo *vec_add(p1, vec_scale(VEC_90, stepf))

# vtex paths

f = 0.12
p = VEC_0
UP_SETTLEMENT_PATH = Path.new
UP_SETTLEMENT_PATH.moveTo *vec_add(p, vec_scale(VEC_0, f))
UP_SETTLEMENT_PATH.lineTo *vec_add(p, vec_scale(VEC_90, f))
UP_SETTLEMENT_PATH.lineTo *vec_add(p, vec_scale(VEC_90, f), vec_scale(VEC_180, f))
UP_SETTLEMENT_PATH.lineTo *vec_add(p, vec_scale(VEC_270, f), vec_scale(VEC_180, f))
UP_SETTLEMENT_PATH.lineTo *vec_add(p, vec_scale(VEC_270, f))
UP_SETTLEMENT_PATH.lineTo *vec_add(p, vec_scale(VEC_0, f))

p = VEC_180
DOWN_SETTLEMENT_PATH = Path.new
DOWN_SETTLEMENT_PATH.moveTo *vec_add(p, vec_scale(VEC_0, f))
DOWN_SETTLEMENT_PATH.lineTo *vec_add(p, vec_scale(VEC_90, f))
DOWN_SETTLEMENT_PATH.lineTo *vec_add(p, vec_scale(VEC_90, f), vec_scale(VEC_180, f))
DOWN_SETTLEMENT_PATH.lineTo *vec_add(p, vec_scale(VEC_270, f), vec_scale(VEC_180, f))
DOWN_SETTLEMENT_PATH.lineTo *vec_add(p, vec_scale(VEC_270, f))
DOWN_SETTLEMENT_PATH.lineTo *vec_add(p, vec_scale(VEC_0, f))

def scale_path(path, scale)
  xform = AffineTransform.new
  xform.scale(scale, scale)
  newpath = path.clone
  newpath.transform(xform)
  newpath
end


# .........................................................................
# .     .     .     .     .     .     .     .     .     .     .     .     .
# ........................X...........X...........X........................
# .     .     .     .  X  .  X  .  X  .  X  .  X  .  X  .     .     .     .
# ..................X...........X...........X...........X..................
# .     .     .     X     .     X     .     X     .     X     .     .     .
# ..................X...........X...........X...........X..................
# .     .     .     X     .     X     .     X     .     X     .     .     .
# ..................X...........X...........X...........X..................
# .     .     .  X  .  X  .  X  .  X  .  X  .  X  .  X  .  X  .     .     .
# ............X...........X...........X...........X...........X............
# .     .     X     .     X     .     X     .     X     .     X     .     .
# ............X...........X...........X...........X...........X............
# .     .     X     .     X     .     X     .     X     .     X     .     .
# ............X...........X...........X...........X...........X............
# .     .  X  .  X  .  X  .  X  .  X  .  X  .  X  .  X  .  X  .  X  .     .
# ......X...........X...........X...........X...........X...........X......
# .     X     .     X     .     X     .     X     .     X     .     X     .
# ......X...........X...........X...........X...........X...........X......
# .     X     .     X     .     X     .     X     .     X     .     X     .
# ......X...........X...........X...........X...........X...........X......
# .     .  X  .  X  .  X  .  X  .  X  .  X  .  X  .  X  .  X  .  X  .     .
# ............X...........X...........X...........X...........X............
# .     .     X     .     X     .     X     .     X     .     X     .     .
# ............X...........X...........X...........X...........X............
# .     .     X     .     X     .     X     .     X     .     X     .     .
# ............X...........X...........X...........X...........X............
# .     .     .  X  .  X  .  X  .  X  .  X  .  X  .  X  .  X  .     .     .
# ..................X...........X...........X...........X..................
# .     .     .     X     .     X     .     X     .     X     .     .     .
# ..................X...........X...........X...........X..................
# .     .     .     X     .     X     .     X     .     X     .     .     .
# ..................X...........X...........X...........X..................
# .     .     .     .  X  .  X  .  X  .  X  .  X  .  X  .     .     .     .
# ........................X...........X...........X........................
# .     .     .     .     .     .     .     .     .     .     .     .     .
# .........................................................................
X_UNIT = HR3
Y_UNIT = 0.5
UNITS_W = X_UNIT * 12
UNITS_H = Y_UNIT * 18

TILE_LINE_WEIGHT = 1.0 / 200.0
PIECE_LINE_WEIGHT = 1.0 / 75.0


COL_CREAM = Color.new(230, 220, 150)
COL_SEA   = Color.new(40, 70, 160)

class Terrain
  attr_accessor :color
end
FOREST.color = Color.new(40, 155, 0)
PLAINS.color = Color.new(240, 210, 90)
HILLS.color = Color.new(220, 90, 50)
MOUNTAIN.color = Color.new(160, 120, 70)
PASTURE.color = Color.new(170, 240, 70)
DESERT.color = Color.new(250, 250, 80)


class Renderer
  attr_accessor :game, :scale
  def initialize
    @game = nil
    @scale = nil
  end

  def window_coords_to_board(x, y)
    i, yrem = y.divmod(Y_UNIT * @scale)
    j, xrem = x.divmod(X_UNIT * @scale)
    if i % 3 != 1
      row = (i % 3 == 0) ? (i / 3) : (i / 3) + 1
      ascending, above = nil, nil
    else
      ascending = (i % 6 == 1) ? (j % 2 == 1) : (j % 2 == 0)
      if ascending
        above = (Y_UNIT * @scale - yrem) / xrem > Y_UNIT / X_UNIT
      else
        above = yrem / xrem < Y_UNIT / X_UNIT
      end
      #above = (ascending ? ((Y_UNIT * @scale - yrem) / xrem > Y_UNIT / X_UNIT)
      #above = ((ascending ? (Y_UNIT * @scale) - yrem : yrem) / xrem) < (Y_UNIT / X_UNIT)
      row = above ? (i / 3) : (i / 3) + 1
    end
    col = (j - 2 + row) / 2
    [row, col, ascending, above]
  end

  def board_coords_to_window(row, col)
    [((2 * col - row + 3) * X_UNIT * @scale).to_i,
     ((3 * row) * Y_UNIT * @scale).to_i]
  end

  def draw_tile(tile, buffer)
    outer_hex = scale_path(HEX_PATH, @scale * 0.97)
    inner_hex = scale_path(HEX_PATH, @scale * 0.87)
    x, y = board_coords_to_window(tile.row, tile.col)
    gfx = buffer.createGraphics
    gfx.setRenderingHint(RHint::KEY_ANTIALIASING, RHint::VALUE_ANTIALIAS_ON)
    gfx.translate(x, y)
    gfx.setPaint(COL_CREAM)
    gfx.fill(outer_hex)
    gfx.setPaint(tile.terrain.color)
    gfx.fill(inner_hex)
    gfx.setPaint(Color::BLACK)
    gfx.setStroke(BasicStroke.new(@scale * TILE_LINE_WEIGHT))
    gfx.draw(outer_hex)
    gfx.draw(inner_hex)
  end

  def draw_edge(edge, buffer)
    return unless edge.piece
    path = {asc: ASC_ROAD_PATH, desc: DESC_ROAD_PATH, vert: VERT_ROAD_PATH}[edge.alignment]
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
    gfx.setStroke(BasicStroke.new(@scale * PIECE_LINE_WEIGHT))
    gfx.draw(path)
  end

  def draw_vtex(vtex, buffer)
    return unless vtex.piece
    path = {
      settlement: {up: UP_SETTLEMENT_PATH, down: DOWN_SETTLEMENT_PATH},
      city: {up: UP_SETTLEMENT_PATH, down: DOWN_SETTLEMENT_PATH},
    }[vtex.piece.type][vtex.alignment]
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
    gfx.setStroke(BasicStroke.new(@scale * PIECE_LINE_WEIGHT))
    gfx.draw(path)
  end

  def draw_buffer()
    w, h = UNITS_W * @scale, UNITS_H * @scale
    buffer = BufferedImage.new(w, h, BufferedImage::TYPE_4BYTE_ABGR)
    @game.board.tiles.each {|tile| draw_tile(tile, buffer) }
    @game.board.edges.each {|edge| draw_edge(edge, buffer) }
    @game.board.vtexs.each {|vtex| draw_vtex(vtex, buffer) }
    return buffer
  end

  # def render_tile_types()
  #   path1 = scale_path(HEX_PATH, 0.97)
  #   path2 = scale_path(HEX_PATH, 0.87)
  #   w, h = (X_UNIT * 2 * @scale).to_i, (Y_UNIT * 4 * @scale).to_i
  #   mx, my = w / 2.0, h / 2.0
  #   Hash[
  #     TERRAINS.map do |terrain|
  #       img = BufferedImage.new(w, h, BufferedImage::TYPE_4BYTE_ABGR)
  #       gfx = img.createGraphics
  #       gfx.setRenderingHint(RHint::KEY_ANTIALIASING, RHint::VALUE_ANTIALIAS_ON)
  #       gfx.translate(mx, my)
  #       gfx.setPaint(COL_CREAM)
  #       gfx.fill(path1)
  #       gfx.setPaint(terrain.color)
  #       gfx.fill(path2)
  #       gfx.setPaint(Color::BLACK)
  #       gfx.setStroke(BasicStroke.new(@scale * LINE_WEIGHT))
  #       gfx.draw(path1)
  #       gfx.draw(path2)
  #       [terrain, img]
  #     end
  #   ]
  # end

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
      *     *     *     *     R     R     *     O     *     *
   *           Ws          Rc          *           *           *
   *     h     W     p     *     p     *     h     O     m     *
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

r = Renderer.new
r.game = game
r.scale = 80

f = javax.swing.JFrame.new("Test Frame")

class ImageViewer < javax.swing.JPanel
  def initialize()
    super
  end
  def paintComponent(gfx)
    gfx.drawImage($img, 0, 0, nil)
  end
end

$img = r.draw_buffer
imgview = ImageViewer.new

f.add imgview
f.setDefaultCloseOperation javax.swing.JFrame::EXIT_ON_CLOSE
f.pack
f.setSize 800, 800
f.setVisible true
