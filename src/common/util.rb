

class Object
  # Takes a hash of attribute names and values, and assigns each value to the named attribute.
  def set_attributes(attributes, defaults={})
    attributes.each do |attr, value|
      public_send("#{attr}=".to_sym, value)
    end
    defaults.each do |attr, default|
      public_send("#{attr}=".to_sym, default) if public_send(attr).nil?
    end
  end
end

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

def vec(x, y)
  return Vector.new(x, y)
end
