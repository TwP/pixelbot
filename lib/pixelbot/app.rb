require "sinatra/base"
require "tilt/erb"
require "multi_json"

module Pixelbot
  class App < Sinatra::Base
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
        Pixelbot.set_brightness(value)
        MultiJson.dump({:brightness => value})
      else
        "{}"
      end
    end

    post "/set_color" do
      content_type :json

      color = get_color
      Pixelbot.set_color(color)
      MultiJson.dump(color)
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
  end
end
