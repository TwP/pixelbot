
var brightness_request = null;
var color_request = null;

var getColor = function() {
  return {
    red:   r.getValue(),
    green: g.getValue(),
    blue:  b.getValue()
  };
};

var setColor = function( color ) {
  if (color_request == null) {
    r.setValue(color.red);
    g.setValue(color.green);
    b.setValue(color.blue);
    showColor(color);
  }
};

var showColor = function( color ) {
  $('#RGB').css('background', 'rgb('+color.red+','+color.green+','+color.blue+')');
};

var RGBChange = function() {
  var color = getColor();
  showColor(color);
  if (color_request == null) {
    color_request = $.post("/set_color", color,
      function( data, status, xhr ) { color_request = null; }
    );
  }
};

var getBrightness = function() {
  return i.getValue();
};

var setBrightness = function( brightness ) {
  if (brightness_request == null) {
    i.setValue(brightness);
  }
};

var BrightnessChange = function() {
  if (brightness_request == null) {
    brightness_request = $.post("/brightness", { brightness: getBrightness() },
      function( data, status, xhr ) { brightness_request = null; }
    );
  }
};

var r = $('#R').slider()
          .on('change', RGBChange)
          .data('slider');

var g = $('#G').slider()
          .on('change', RGBChange)
          .data('slider');

var b = $('#B').slider()
          .on('change', RGBChange)
          .data('slider');

var i = $('#I').slider()
          .on('change', BrightnessChange)
          .data('slider');

// configure the WebSocket code
var scheme = 'ws://';
var uri    = scheme + window.document.location.host + '/';
var ws     = new WebSocket(uri);

ws.onmessage = function(message) {
  var data = JSON.parse(message.data);
  if (data.hasOwnProperty('brightness')) {
    setBrightness(data.brightness);
  }
  if (data.hasOwnProperty('color')) {
    setColor(data.color);
  }
}
