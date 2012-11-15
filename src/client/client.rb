

class Client
  attr_accessor :game, :local_player
  def initialize
    @client_frame = nil
    @renderer = nil
    @game = nil
    @local_player = nil
  end
end


include Java

Color = java.awt.Color
$dummy_window_colors = [Color::RED, Color::BLUE, Color::GREEN, Color::MAGENTA, Color::CYAN, Color::ORANGE]

def constraints(args)
  
end

def dim(w, h)
  return java.awt.Dimension.new(w, h)
end

class DummyWindow < javax.swing.JPanel
  def initialize(label)
    super()
    add javax.swing.JLabel.new(label)
    setBorder javax.swing.border.LineBorder.new($dummy_window_colors.shift, 5)
  end
end

class ClientFrame < javax.swing.JFrame
  def initialize
    super

    cp = getContentPane()

    layout = javax.swing.BoxLayout.new(cp, javax.swing.BoxLayout::X_AXIS)
    cp.setLayout layout

    control = DummyWindow.new("control")
    control.setMinimumSize   dim(140, 10)
    control.setPreferredSize dim(140, 100)
    control.setMaximumSize   dim(140, 100)
    cp.add control

    middle = DummyWindow.new("middle")
    middle.setMinimumSize    dim(200, 10)
    middle.setPreferredSize  dim(400, 100)
    middle.setMaximumSize    dim(1000, 10000)
    cp.add middle

    chat = DummyWindow.new("chat")
    chat.setMinimumSize    dim(150, 10)
    chat.setPreferredSize  dim(150, 100)
#    chat.setMaximumSize    dim(150, 100)
    cp.add chat

#    setDefaultCloseOperation javax.swing.WindowConstants::DISPOSE_ON_CLOSE
    setDefaultCloseOperation javax.swing.JFrame::EXIT_ON_CLOSE
    setSize 600, 500
    setVisible true
  end
end

#f = ClientFrame.new
