module RenderPaths

  include Java

  class Vector
    attr_accessor :x, :y
    def initialize(x=0, y=0)
      @x, @y = x, y
    end
    def to_s()
      "<#@x,#@y>";
    end
    def +(v)
      v = Vector.new(*v) if v.is_a? Array
      return Vector.new(@x + v.x, @y + v.y)
    end
    def *(f)
      return Vector.new(@x * f, @y * f)
    end
  end

  def RenderPaths.vec(x, y)
    return Vector.new(x, y)
  end

  def RenderPaths.make_path(*points)
    path = java.awt.geom.Path2D::Double.new
    first, *rest = points
    path.moveTo(first.x, first.y)
    rest.each {|p| path.lineTo(p.x, p.y)}
    path.lineTo(first.x, first.y)
    return path
  end

  def RenderPaths.lerp(v1, v2, f)
    return Vector.new(v1.x + (v2.x - v1.x) * f,
                      v1.y + (v2.y - v1.y) * f)
  end

  HR3 = (3.0 ** 0.5) / 2.0
  HR2 = (2.0 ** 0.5) / 2.0

  xs = [   0,  0.5,  HR2,  HR3,    1,  HR3,  HR2,  0.5,    0, -0.5, -HR2, -HR3,   -1, -HR3, -HR2, -0.5]
  ys = [  -1, -HR3, -HR2, -0.5,    0,  0.5,  HR2,  HR3,    1,  HR3,  HR2,  0.5,    0, -0.5, -HR2, -HR3]
  (       v0,  v30,  v45,  v60,  v90, v120, v135, v150, v180, v210, v225, v240, v270, v300, v315, v330) =
    xs.zip(ys).map {|x, y| Vector.new(x, y)}

  HEX = make_path(v0, v60, v120, v180, v240, v300)

  def RenderPaths.make_road_path(vsrc, vdst, dir1, dir2)
    f_major, f_minor = 0.22, 0.06
    p1, p2 = lerp(vsrc, vdst, f_major), lerp(vsrc, vdst, 1 - f_major)
    return make_path(p1 + dir1 * f_minor,
                     p2 + dir1 * f_minor,
                     p2 + dir2 * f_minor,
                     p1 + dir2 * f_minor)
  end

  def RenderPaths.make_settlement_path(p)
    y1, y2, y3, x = -0.1, -0.0, 0.1, 0.10
    return make_path(p + vec( 0, y1),
                     p + vec( x, y2),
                     p + vec( x, y3),
                     p + vec(-x, y3),
                     p + vec(-x, y2))
  end

  def RenderPaths.make_city_path(p)
    x, y = 0.085, 0.075
    return make_path(p,
                     p + vec(   0,   -x),
                     p + vec(   x, -2*x),
                     p + vec( 2*x,   -x),
                     p + vec( 2*x,  2*x),
                     p + vec(-2*x,  2*x),
                     p + vec(-2*x,    0))
  end

  PIECES = {
    road: {
      asc:  make_road_path(v300, v0, v330, v150),
      desc: make_road_path(v0, v60, v30, v210),
      vert: make_road_path(v240, v300, v270, v90),
    },
    settlement: {
      up:   make_settlement_path(v0),
      down: make_settlement_path(v180),
    },
    city: {
      up:   make_city_path(v0),
      down: make_city_path(v180),
    }
  }

end
