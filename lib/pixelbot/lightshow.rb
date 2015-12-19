module Pixelbot
  class Lightshow
    Halt = Class.new(StandardError)

    SLEEP = 60   # seconds

    def initialize( leds )
      @leds    = leds
      @running = false
      @stop    = nil
    end

    attr_reader   :leds
    attr_accessor :wait_ms

    def run
      if @stop.nil?
        EM.next_tick do
          EM.defer do
            perform
            run
          end
        end
      elsif (seconds = @stop - Time.now) > 0
        EM::Timer.new(seconds) { run }
      else
        @stop = nil
        run
      end

      self
    end

    def sleep( time )
      raise Halt unless @stop.nil?
      Kernel.sleep time
    end

    def running?
      @running
    end

    def stop
      @stop = Time.now + SLEEP
    end

    def perform
      @running = true

      # Color wipe animations
      self.wait_ms = 75
      color_wipe(PixelPi::Color(255, 0, 0))  # red color wipe
      color_wipe(PixelPi::Color(0, 255, 0))  # green color wipe
      color_wipe(PixelPi::Color(0, 0, 255))  # blue color wipe

      # Theater chase animations
      self.wait_ms = 100
      leds.clear
      theater_chase(PixelPi::Color(255, 255, 255))  # white theater chase
      theater_chase(PixelPi::Color(255,   0,   0))  # red theater chase
      theater_chase(PixelPi::Color(  0,   0, 255))  # blue theater chase

      self.wait_ms = 20
      rainbow
      rainbow_cycle
      # theater_chase_rainbow(:wait_ms => 75)

      self
    rescue Halt
      self
    ensure
      @running = false
    end

    # Wipe color across display a pixel at a time.
    #
    # color - The 24-bit RGB color value
    # opts  - The options Hash
    #   :wait_ms - sleep time between pixel updates
    #
    # Returns this PixelPi::Leds instance.
    def color_wipe( color, opts = {} )
      wait_ms = opts.fetch(:wait_ms, self.wait_ms)

      leds.length.times do |num|
        leds[num] = color
        leds.show
        sleep(wait_ms / 1000.0)
      end

      self
    end

    # Movie theater light style chaser animation.
    #
    # color - The 24-bit RGB color value
    # opts  - The options Hash
    #   :wait_ms    - sleep time between pixel updates
    #   :iterations - number of iterations (defaults to 10)
    #   :spacing    - spacing between lights (defaults to 3)
    #
    # Returns this PixelPi::Leds instance.
    def theater_chase( color, opts = {} )
      wait_ms    = opts.fetch(:wait_ms, self.wait_ms)
      iterations = opts.fetch(:iterations, 10)
      spacing    = opts.fetch(:spacing, 3)

      iterations.times do
        spacing.times do |sp|
          leds.clear
          (sp...leds.length).step(spacing) { |ii| leds[ii] = color }
          leds.show
          sleep(wait_ms / 1000.0)
        end
      end

      self
    end

    # Generate rainbow colors across 0-255 positions.
    #
    # pos - Positoin between 0 and 255
    #
    # Returns a 24-bit RGB color value.
    def wheel( pos )
      pos = pos & 0xff
      if pos < 85
        return PixelPi::Color(pos * 3, 255 - pos * 3, 0)
      elsif pos < 170
        pos -= 85
        return PixelPi::Color(255 - pos * 3, 0, pos * 3)
      else
        pos -= 170
        return PixelPi::Color(0, pos * 3, 255 - pos * 3)
      end
    end

    # Draw rainbow that fades across all pixels at once.
    #
    # opts - The options Hash
    #   :wait_ms    - sleep time between pixel updates
    #   :iterations - number of iterations (defaults to 1)
    #
    # Returns this PixelPi::Leds instance.
    def rainbow( opts = {} )
      wait_ms    = opts.fetch(:wait_ms, self.wait_ms)
      iterations = opts.fetch(:iterations, 1)

      (0...256*iterations).each do |jj|
        leds.fill { |ii| wheel(ii+jj) }
        leds.show
        sleep(wait_ms / 1000.0)
      end

      self
    end

    # Draw rainbow that uniformly distributes itself across all pixels.
    #
    # opts - The options Hash
    #   :wait_ms    - sleep time between pixel updates
    #   :iterations - number of iterations (defaults to 5)
    #
    # Returns this PixelPi::Leds instance.
    def rainbow_cycle( opts = {} )
      wait_ms    = opts.fetch(:wait_ms, self.wait_ms)
      iterations = opts.fetch(:iterations, 5)

      (0...256*iterations).each do |jj|
        leds.fill { |ii| wheel((ii * 256 / leds.length) + jj) }
        leds.show
        sleep(wait_ms / 1000.0)
      end

      self
    end

    # Rainbow moview theather light style chaser animation.
    #
    # opts - The options Hash
    #   :wait_ms - sleep time between pixel updates
    #   :spacing - spacing between lights (defaults to 3)
    #
    # Returns this PixelPi::Leds instance.
    def theater_chase_rainbow( opts = {} )
      wait_ms = opts.fetch(:wait_ms, self.wait_ms)
      spacing = opts.fetch(:spacing, 3)

      256.times do |jj|
        spacing.times do |sp|
          leds.clear
          (sp...leds.length).step(spacing) { |ii| leds[ii] = wheel((ii+jj) % 255) }
          leds.show
          sleep(wait_ms / 1000.0)
        end
      end

      self
    end
  end
end
