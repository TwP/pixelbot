require "sinatra/base"
require "sinatra/content_for"
require "tilt/erb"
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
        leds.brightness = value
        leds.show unless lightshow.running?

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

      lightshow.stop

      leds.rotate(1).
        set_pixel(leds.length - 1, red, green, blue).
        show

      MultiJson.dump \
        :red   => red,
        :green => green,
        :blue  => blue
    end

  private

    def get_color
      Pixelbot::Color.new \
        get_value(:red),
        get_value(:green),
        get_value(:blue)
    end

    def get_value( name )
      value = Integer(params[name])
      value = value.abs & 0xff
    end

    def lightshow
      Pixelbot.lightshow
    end

    def leds
      Pixelbot.leds
    end
  end
end
