# What is this?

A small ruby web service for controlling
[NeoPixels](https://www.adafruit.com/category/168) attached to a
[RaspberryPi](http://www.raspberrypi.org).

# Is it any good?

Yes.

# How do I run it?

Clone the repository to your RaspberryPi, and install all the dependencies:

```sh
git clone https://github.com/TwP/pixelbot.git
cd pixelbot
script/bootstrap
```

Open the `pixelbot.yml` file in your favorite editor and set the number of
`leds` to the number of NeoPixels you have connected to your RaspberryPi. Set
the `gpio` pin number to match the GPIO pin where the NeoPixels are connected to
your RaspberryPi. Please read the [RaspberryPi NeoPixel guide](https://learn.adafruit.com/neopixels-on-raspberry-pi/overview)
from Adafruit for all the details on setting up your NeoPixel circuit.

To start the web service run:

```sh
sudo script/pixelbot
```

Enjoy the blinkenlights!

# It won't run!

Yes it will.

The [ws2811](https://github.com/jgarff/rpi_ws281x) driver is using direct memory
addressing (DMA) via `/dev/mem` to control the NeoPixels. Only the root user has
permission to read and write to this hardware device. So any time your work with
NeoPixels, your code will need to be run as the super user.

# But I don't have a RaspberryPi

You're in luck!

When running on an architecture other than `linux-arm` (the RaspberryPi
architecture), a fake LEDs class is used to simulate the NeoPixels. This set of
fake LEDs is provided by the [pixel_pi](https://github.com/TwP/pixel_pi) gem,
and the fake LEDs are automatically used where needed.

The fake LEDs are displayed in the terminal using a UTF-8 fisheye "◉" character,
and the fake LEDs are colorized using the [rainbow]() gem. So you can work with
the LEDs even when a RaspberryPi is not handy.

![](/public/images/pixelbot.gif)
