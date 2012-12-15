
{graphics: g} = love

export *

class Projector
  shader: [[
    extern number screen_width;
    extern number screen_height;

    float PI = 3.14159265358979323846264;

    vec4 effect(vec4 color, sampler2D tex, vec2 st, vec2 pixel_coords) {
      vec2 pos = (st - 0.5) * 2;
      pos.x = pos.x * 800/600;

      float R = 1.2;

      if (length(pos) > R) {
        return vec4(0);
      }

      float long_0 = 0;
      float lat_0 = 0;

      float P = length(pos);
      float C = asin(P/R);

      float long = long_0 + atan(
        pos.x * sin(C),
        (P * cos(lat_0) * cos(C) - pos.y * sin(long_0) * sin(C))
      );

      float lat = asin(
        cos(C) * sin(lat_0) + (
          pos.y * sin(C) * cos(lat_0) / P
        )
      );

      vec2 source = (vec2(long, lat) / PI * 2 + 1) / 2;

      vec4 final = Texel(tex, source);
      return vec4(final.rgb, 1.0);
    }
  ]]

  new: =>
    @canvas = g.newCanvas!
    @canvas\setFilter "nearest", "nearest"
    @effect = g.newPixelEffect @shader
    -- @effect\send "screen_width", g.getWidth!
    -- @effect\send "screen_height", g.getHeight!

  render: (fn) =>
    g.setCanvas @canvas
    fn!
    g.setCanvas!

    g.setPixelEffect @effect unless @disabled
    g.draw @canvas, 0,0
    g.setPixelEffect!