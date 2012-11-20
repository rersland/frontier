include Java

module JavaAliases
  BufferedImage = java.awt.image.BufferedImage
  AffineTransform = java.awt.geom.AffineTransform
  BasicStroke = java.awt.BasicStroke
  Color = java.awt.Color
  Font = java.awt.Font
  RHint = java.awt.RenderingHints
end

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

