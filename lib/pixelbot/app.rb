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
      "hello from '#{`uname -a`}'"
    end

    get "/hello" do
      "Hello World"
    end

    get "/hello/delayed" do
      EM.defer do
        sleep(rand(5)+1)
        puts "My work here is done"
      end
      "I'm doing work in the background, but I am still free to take requests"
    end
  end
end
