require 'singleton'
require 'thread'

class Event
  include Singleton

  def initialize
    @queue = Queue.new
    @thread = nil
    @connections = {}
    @stop_thread = false
  end

  def emit(name, data)
    @queue.push [name, data]
  end

  def connect(name, &handler)
    @connections[name] = [] unless @connections.has_key?(name)
    @connections[name] << handler
  end

  def start_thread()
    @stop_thread = false
    @thread = Thread.new do
      while true
        break if @stop_thread
        if @queue.empty?
          sleep 0.1
        else
          name, data = @queue.pop
          handlers = @connections[name]
          handlers.each {|handler| handler.call(name, data)} unless handlers.nil?
        end
      end
    end
  end

  def stop_thread()
    @stop_thread = true
    @thread.join
  end

  def self.emit(name, data)         self.instance.emit(name, data)         end
  def self.connect(name, &handler)  self.instance.connect(name, &handler)  end
  def self.start_thread()           self.instance.start_thread()           end
  def self.stop_thread()            self.instance.stop_thread()            end
end





# puts "connect"
# Event.connect(:foo) {|name, data| puts "foo handler: #{data[:str]}"}

# puts "start thread"
# Event.start_thread

# puts "emit"
# Event.emit :foo, str: "[MESSAGE]"
# sleep 0.1

# puts "stop thread"
# Event.stop_thread

# puts "done!"
