require_relative '../common/util'

module RenderShapes

  include Java

  def self.make_path(*points)
    path = java.awt.geom.Path2D::Double.new
    first, *rest = points
    path.moveTo(first.x, first.y)
    rest.each {|p| path.lineTo(p.x, p.y)}
    path.closePath()
#    path.lineTo(first.x, first.y)
    return path
  end

  def self.lerp(v1, v2, f)
    return Vector.new(v1.x + (v2.x - v1.x) * f,
                      v1.y + (v2.y - v1.y) * f)
  end

  HR3 = (3.0 ** 0.5) / 2.0
  HR2 = (2.0 ** 0.5) / 2.0

  xs = [   0,  0.5,  HR2,  HR3,    1,  HR3,  HR2,  0.5,    0, -0.5, -HR2, -HR3,   -1, -HR3, -HR2, -0.5]
  ys = [  -1, -HR3, -HR2, -0.5,    0,  0.5,  HR2,  HR3,    1,  HR3,  HR2,  0.5,    0, -0.5, -HR2, -HR3]
  (       v0,  v30,  v45,  v60,  v90, v120, v135, v150, v180, v210, v225, v240, v270, v300, v315, v330) =
    xs.zip(ys).map {|x, y| Vector.new(x, y)}

  HEX = [Vector.new(0,0), make_path(v0, v60, v120, v180, v240, v300)]

  def self.make_road_path(vsrc, vdst, dir1, dir2)
    f_major, f_minor = 0.22, 0.06
    p1, p2 = lerp(vsrc, vdst, f_major), lerp(vsrc, vdst, 1 - f_major)
    return make_path(p1 + dir1 * f_minor,
                     p2 + dir1 * f_minor,
                     p2 + dir2 * f_minor,
                     p1 + dir2 * f_minor)
  end

  def self.make_settlement_path()
    y1, y2, y3, x = -0.1, -0.0, 0.1, 0.10
    return make_path(vec( 0, y1),
                     vec( x, y2),
                     vec( x, y3),
                     vec(-x, y3),
                     vec(-x, y2))
  end

  def self.make_city_path()
    x, y = 0.085, 0.075
    return make_path(vec(   0,    0),
                     vec(   0,   -x),
                     vec(   x, -2*x),
                     vec( 2*x,   -x),
                     vec( 2*x,  2*x),
                     vec(-2*x,  2*x),
                     vec(-2*x,    0))
  end

  PIECES = {
    road: {
      asc:  [lerp(v300,   v0, 0.5), make_road_path(v240 * 0.5,  v60 * 0.5, v330, v150)],
      desc: [lerp(  v0,  v60, 0.5), make_road_path(v300 * 0.5, v120 * 0.5,  v30, v210)],
      vert: [lerp(v240, v300, 0.5), make_road_path(v180 * 0.5,   v0 * 0.5, v270,  v90)],
    },
    settlement: {
      up:   [  v0, make_settlement_path()],
      down: [v180, make_settlement_path()],
    },
    city: {
      up:   [  v0, make_city_path()],
      down: [v180, make_city_path()],
    }
  }

end
