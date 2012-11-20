require_relative '../common/frontier'

include Java

module Gui

  ##############################################################################
  # aliased Java classes
  ##############################################################################

  BufferedImage = java.awt.image.BufferedImage
  AffineTransform = java.awt.geom.AffineTransform
  BasicStroke = java.awt.BasicStroke
  Color = java.awt.Color
  Font = java.awt.Font
  RHint = java.awt.RenderingHints

  JComponent = javax.swing.JComponent
  JPanel = javax.swing.JPanel

  ##############################################################################
  # function: color
  #
  # convience function for constructing java.awt.Color instances
  #
  # valid calling signatures:
  #   color(java.awt.Color.new(128, 192, 192))
  #   color("8080b0")
  #   color(0.5, 0.75, 0.75)
  #   color(128, 192, 192)
  ##############################################################################
  def color(*args)
    if args.size == 1
      arg = args.first
      return arg if arg.is_a? Color
      return color(*arg) if arg.is_a? Array
      arg = arg.to_s
      return Color.new(arg[0..1].to_i(16),
                       arg[2..3].to_i(16),
                       arg[4..5].to_i(16))
    elsif args.size == 3
      if args.any? {|n| n.is_a? Float} and args.all? {|n| n >= 0 and n <= 1}
        args.map! {|n| (n * 255).to_i}
      end
      return Color.new(*args)
    else
      raise ArgumentError.new
    end
  end

  ##############################################################################
  # function: draw_text
  ##############################################################################
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

  ##############################################################################
  # function: draw_centered_image
  ##############################################################################
  def draw_centered_image(gfx, img, x, y)
    w, h = img.getWidth(), img.getHeight()
    gfx.drawImage(img, x - w/2, y - h/2, nil)
  end

  ##############################################################################
  # class: ColorPalette
  ##############################################################################
  class ColorPalette
    def initialize(attrs)
      @colors = {}
      attrs.each_pair do |key, val|
        @colors[key] = color(val)
      end
    end

    def method_missing(name, *args)
      if @colors.has_key?(name)
        return @colors[name]
      elsif name.to_s[-1] == '='
        name = name.to_s[0...-1].to_sym
        val = args.first
        @colors[name] = color(val)
        return
      end
      super
    end
  end

  ##############################################################################
  # JComponent
  ##############################################################################
  javax.swing.JComponent.class_eval do
    def get_inset_bounds
      ins = getInsets
      return [ins.left,
              ins.top,
              getWidth - (ins.left + ins.right),
              getHeight - (ins.top + ins.bottom)]
    end

    def add_margins(margins)
      border = getBorder
      margin = javax.swing.border.EmptyBorder.new(*margins)
      setBorder javax.swing.border.CompoundBorder.new(margin, border)
    end
  end
end

