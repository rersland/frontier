include Java

require_relative 'client/client'
require_relative 'client/renderer'
require_relative 'client/view/player_view'
require_relative 'client/view/board_view'
require_relative 'common/board'
require_relative 'common/event'
require_relative 'common/game'
require_relative 'common/player'

$board_text = "
                     *           *           *
                  *     *     *     *     *     *
               *           Rs          *           *
               *     p     R     f     *     d     *
               *           *           Bs          *
            *     *     *     R     B     *     *     *
         *           *           *           *           *
         *     m     *     a     R     m     *     a     *
         *           *           *           Os          *
      *     *     *     R     R     R     *     O     *     *
   *           Ws          Rc          *           *           *
   *     h     W     p11   R     p8    *     h5    O     m2    *
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

class MainFrameListener < java.awt.event.WindowAdapter
  def windowClosed
    puts "MainFrameListener: window closed"
    renderer.stop_thread()
    Event.stop_thread()
    puts "MainFrameListener: threads stopped"
  end
end

class TestFrame < javax.swing.JFrame
  def initialize
    super

    ############################################################################
    # client setup

    @client = Client.new

    game = Game.new
    @client.game = game

    b = Board.new
    b.create_spaces
    b.connect_spaces
    b.load_text($board_text)
    game.board = b

    game.players = {
      red: Player.new(color: :red),
      blue: Player.new(color: :blue),
      orange: Player.new(color: :orange),
      white: Player.new(color: :white),
    }

    local_player = game.players[:red]
    @client.local_player = local_player
    local_player.resource_cards = [LUMBER, GRAIN, WOOL, ORE, BRICK]

    ############################################################################
    # layout setup

    cp = getContentPane()

    layout = javax.swing.BoxLayout.new(cp, javax.swing.BoxLayout::X_AXIS)
    cp.setLayout layout

    @player_view = PlayerView.new
    @player_view.setMinimumSize   dim(200, 10)
    @player_view.setPreferredSize dim(200, 100)
    @player_view.setMaximumSize   dim(200, 10000)
    cp.add @player_view

    @board_view = BoardView.new
    @board_view.setMinimumSize    dim(200, 10)
    @board_view.setPreferredSize  dim(400, 100)
    @board_view.setMaximumSize    dim(10000, 10000)
    cp.add @board_view

    @player_view.client = @client
    @player_view.setCards(local_player.resource_cards)
    @board_view.client = @client

    setDefaultCloseOperation javax.swing.JFrame::EXIT_ON_CLOSE
    setSize 600, 400
    setLocation 400, 100
    setTitle "Frontier"
    setVisible true
  end

  def run

    renderer = Renderer.new(@client.game)

    Thread.abort_on_exception = true

    Event.start_thread
    renderer.start_thread

    Event.connect(:request_render_job) do |name, data|
      renderer.add_render_job(data[:scale])
    end
    Event.connect(:render_job_done) do |name, buffers|
      @board_view.set_buffers(buffers)
    end

    addWindowListener MainFrameListener.new

  end
end

TestFrame.new().run()
