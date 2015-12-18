require "eventmachine"
require "thin"
require "pixel_pi"
require "yaml"

module Pixelbot
  extend self

  PATH = File.expand_path("../..", __FILE__).freeze
  LIBPATH = File.join(PATH, "lib").freeze

  def path( *args )
    return PATH if args.empty?
    File.join(PATH, *args)
  end

  def strip
    @strip
  end

  def config
    @config = YAML.load_file(path("pixelbot.yml")) rescue {}
  end

  def run( opts = {} )
    EventMachine.run do
      server = opts.fetch(:server, "thin")
      host   = opts.fetch(:host,   "localhost")
      port   = opts.fetch(:port,   5000)

      dispatch = Rack::Builder.app do
        use Pixelbot::PixelBackend
        run Pixelbot::App.new
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

      @strip = Pixelbot::StrandTest.new \
        config.fetch("leds", 8),
        config.fetch("gpio", 18),
        :brightness => config.fetch("brightness", 255),
        :debug      => true

      @strip.run

      #EM.add_periodic_timer(1) { puts "tick [#{Time.now}]" }

      trap "SIGINT" do
        @strip.stop
        @strip.strip.clear.show.close

        $stdout.puts "Stopping ..."
        EventMachine.stop
      end
    end
  end
end

require "pixelbot/app"
require "pixelbot/pixel_backend"
require "pixelbot/strandtest"
