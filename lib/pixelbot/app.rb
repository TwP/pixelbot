require "sinatra/base"
require "sinatra/content_for"
require "multi_json"

module Pixelbot
  class App < Sinatra::Base
    helpers Sinatra::ContentFor

    configure do
      set :threaded, false
      set :public_dir, Pixelbot.path("public")
      set :views, Pixelbot.path("views")
    end

    get "/" do
      content_type :html
      erb :index
    end

    post "/brightness" do
      content_type :json
      if params[:brightness]
        value = get_value(:brightness)
        strip.brightness = value
        strip.show unless strandtest.running?

        MultiJson.dump({:brightness => value})
      else
        "{}"
      end
    end

    post "/set_color" do
      content_type :json

      red   = get_value(:red)
      green = get_value(:green)
      blue  = get_value(:blue)

      strandtest.stop

      strip.rotate(1).
        set_pixel(strip.length - 1, red, green, blue).
        show

      MultiJson.dump \
        :red   => red,
        :green => green,
        :blue  => blue
    end

  private

    def get_value( name )
      value = Integer(params[name])
      value = value.abs & 0xff
    end

    def strandtest
      Pixelbot.strip
    end

    def strip
      Pixelbot.strip.strip
    end
  end
end
