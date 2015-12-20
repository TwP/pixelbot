require "faye/websocket"
require "thread"
require "multi_json"
require "tilt/erb"

module Pixelbot
  class Pusher
    KEEPALIVE_TIME = 15  # seconds

    def initialize( app )
      @app = app
    end

    def clients
      Pixelbot.clients
    end

    def call( env )
      if Faye::WebSocket.websocket?(env)
        ws = Faye::WebSocket.new(env, nil, {ping: KEEPALIVE_TIME })
        ws.on :open do |event|
          # p [:open, ws.object_id]
          clients << ws
          ws.send(MultiJson.dump(Pixelbot.settings))
        end

        ws.on :message do |event|
          # p [:message, event.data]
        end

        ws.on :close do |event|
          # p [:close, ws.object_id, event.code, event.reason]
          clients.delete(ws)
          ws = nil
        end

        # Return async Rack response
        ws.rack_response

      else
        @app.call(env)
      end
    end

  private

    def sanitize( message )
      hash = MultiJson.load(message)
      hash.each { |key, value| hash[key] = ERB::Util.html_escape(value) }
      MultiJson.dump(json)
    end

  end
end
