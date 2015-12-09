require "eventmachine"
require "thin"
require "pixelbot/app"

module Pixelbot
  PATH = File.expand_path("../..", __FILE__).freeze
  LIBPATH = File.join(PATH, "lib").freeze

  def self.path( *args )
    return PATH if args.empty?
    File.join(PATH, *args)
  end

  def self.run( opts = {} )
    EM.run do
      server = opts.fetch(:server, "thin")
      host   = opts.fetch(:host,   "localhost")
      port   = opts.fetch(:port,   5000)

      dispatch = Rack::Builder.app do
        run lambda { |env| [200, {'Content-Type' => 'text/plain'}, ['OK']] }
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

      #EM.add_periodic_timer(1) { puts "tick [#{Time.now}]" }

      trap "SIGINT" do
        $stdout.puts "Stopping ..."
        EventMachine.stop
      end
    end
  end
end
