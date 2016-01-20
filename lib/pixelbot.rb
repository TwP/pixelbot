require "eventmachine"
require "thin"
require "pixel_pi"

module Pixelbot
  extend self

  PATH = File.expand_path("../..", __FILE__).freeze
  LIBPATH = File.join(PATH, "lib").freeze

  Color = Struct.new(:red, :green, :blue) do
    def to_json( *args )
      %Q({"red":#{red},"green":#{green},"blue":#{blue}})
    end
  end

  def path( *args )
    return PATH if args.empty?
    File.join(PATH, *args)
  end

  def config
    @config ||= Configuration.new
  end

  def leds
    @leds ||= PixelPi::Leds.new \
        config.leds, config.gpio,
        :brightness => config.brightness,
        :invert     => config.invert,
        :debug      => true
  end

  def lightshow
    @lightshow ||= Pixelbot::Lightshow.new leds
  end

  def clients
    @clients ||= []
  end

  def run
    EventMachine.run do
      server = "thin"  # could also use "hatetepe" or "goliath"

      app = Rack::Builder.app do
        Faye::WebSocket.load_adapter(server)
        use Pixelbot::Pusher
        run Pixelbot::App
      end

      # Start the web server. Note that you are free to run other tasks
      # within your EM instance.
      Rack::Server.start \
        :app     => app,
        :server  => server,
        :Host    => config.host,
        :Port    => config.port,
        :signals => false

      lightshow.run

      trap("SIGINT") { stop! }
    end
  end

  def stop!
    lightshow.stop
    leds.clear.show
    leds.close

    $stdout.puts "Stopping ..."
    EventMachine.stop
  end

  def set_color( color )
    lightshow.stop
    leds.
      rotate(1).
      set_pixel(leds.length-1, color.red, color.green, color.blue).
      show

    settings[:color] = color

    msg = MultiJson.dump({:color => color})
    clients.each { |client| client.send(msg) }

    nil
  end

  def set_brightness( brightness )
    leds.brightness = brightness
    leds.show unless lightshow.running?

    settings[:brightness] = brightness

    msg = %Q({"brightness": #{brightness}})
    clients.each { |client| client.send(msg) }

    nil
  end

  def settings
    @settings ||= {
      :brightness => 255,
      :color => Pixelbot::Color.new(128,128,128)
    }
  end
end

require "pixelbot/app"
require "pixelbot/configuration"
require "pixelbot/lightshow"
require "pixelbot/pusher"
