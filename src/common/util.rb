

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
