require "yaml"

module Pixelbot
  class Configuration

    PIXELS = {
      "leds"       => 8,
      "gpio"       => 18,
      "brightness" => 255,
      "invert"     => false
    }
    SERVER = {
      "host" => "localhost",
      "port" => 5000
    }

    def initialize( filename = nil )
      filename ||= Pixelbot.path("pixelbot.yml")
      @config =
        begin
          YAML.load_file(filename)
        rescue StandardError => err
          $stderr.puts "Could not load the configuration file: #{filename}"
          $stderr.puts err.to_s
          {"pixels" => PIXELS, "server" => SERVER}
        end
    end

    def pixels
      @config.fetch("pixels", PIXELS)
    end

    def server
      @config.fetch("server", SERVER)
    end

    SERVER.keys.each do |name|
      define_method(name) { server.fetch(name, SERVER[name]) }
    end

    PIXELS.keys.each do |name|
      define_method(name) { pixels.fetch(name, SERVER[name]) }
    end
  end
end
