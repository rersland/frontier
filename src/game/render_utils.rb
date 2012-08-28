module RenderUtils

  include Java

  # import some java classes into this namespace
  JFrame = javax.swing.JFrame
  BufferedImage = java.awt.image.BufferedImage
  Path = java.awt.geom.Path2D::Double
  AffineTransform = java.awt.geom.AffineTransform
  Color = java.awt.Color
  BasicStroke = java.awt.BasicStroke
  RHint = java.awt.RenderingHints

  # sqrt(3) / 2 ... "Half Root 3"
  HR3 = (3.0 ** 0.5) / 2.0

  # hexagon path with side length 1.0, centered at (0.0, 0.0)
  HEX_PATH = Path.new
  HEX_PATH.moveTo  0.0, -1.0
  HEX_PATH.lineTo  HR3, -0.5
  HEX_PATH.lineTo  HR3,  0.5
  HEX_PATH.lineTo  0.0,  1.0
  HEX_PATH.lineTo -HR3,  0.5
  HEX_PATH.lineTo -HR3, -0.5
  HEX_PATH.lineTo  0.0, -1.0

  # Creates a hexagon path centered at (0.0, 0.0)
  # @param [Float] scale the hexagon's side length
  def make_hex_path(scale=1.0)
    xform = AffineTransform.new
    xform.scale(scale, scale)
    path = HEX_PATH.clone
    path.transform(xform)
    return path
  end

end
