require "eventmachine"
require "thin"
require "pixel_pi"
require "yaml"

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
    @config ||= YAML.load_file(path("pixelbot.yml")) rescue {}
  end

  def leds
    @leds ||= PixelPi::Leds.new \
        config.fetch("leds", 8),
        config.fetch("gpio", 18),
        :brightness => config.fetch("brightness", 255),
        :debug      => true
  end

  def lightshow
    @lightshow ||= Pixelbot::Lightshow.new leds
  end

  def clients
    @clients ||= []
  end

  def run( opts = {} )
    EventMachine.run do
      server = opts.fetch(:server, "thin")
      host   = opts.fetch(:host,   "localhost")
      port   = opts.fetch(:port,   5000)

      dispatch = Rack::Builder.app do
        Faye::WebSocket.load_adapter("thin")
        use Pixelbot::Pusher
        run Pixelbot::App
      end

      # NOTE that we have to use an EM-compatible web-server. There
      # might be more, but these are some that are currently available.
      unless %w[thin hatetepe goliath].include? server
        raise "Need an EM webserver, but #{server.inspect} isn't"
      end

      # Start the web server. Note that you are free to run other tasks
      # within your EM instance.
      Rack::Server.start \
        :app     => dispatch,
        :server  => server,
        :Host    => host,
        :Port    => port,
        :signals => false

      lightshow.run

      #EM.add_periodic_timer(1) { puts "tick [#{Time.now}]" }

      trap "SIGINT" do
        stop!
      end
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
require "pixelbot/lightshow"
require "pixelbot/pusher"
