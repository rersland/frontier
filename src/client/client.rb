

class Client
  def initialize
    @client_frame = nil
    @renderer = nil
  end
end


include Java

class ClientFrame < javax.swing.JFrame
  def initialize

  end
end
