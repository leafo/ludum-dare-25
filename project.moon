
{graphics: g} = love

export *

setCanvas = (canvas) ->
  if canvas
    g.setCanvas canvas
  else
    g.setCanvas!

class Glow
  new: (@scale=0.5) =>
    @canvas = g.newCanvas g.getWidth! * @scale, g.getHeight! * @scale
    -- @canvas\setFilter "nearest", "nearest"
    @effect = g.newPixelEffect @shader!

  render: (fn) =>
    old_canvas = g.getCanvas!

    g.setCanvas @canvas
    @canvas\clear 0,0,0,0
    g.push!
    g.scale @scale, @scale
    fn!
    g.pop!
    setCanvas old_canvas

    fn!
    g.setColor 255,255,255,100

    g.push!
    g.scale 1/@scale, 1/@scale
    g.draw @canvas, 0,0
    g.pop!

    g.setColor 255,255,255,255


class Projector
  shader: -> [[
    extern number R;

    float PI = 3.14159265358979323846264;
    vec4 effect(vec4 color, sampler2D tex, vec2 st, vec2 pixel_coords) {
      vec2 pos = (st - 0.5) * 2;
      pos.x = pos.x * 1.4;
      pos.y = pos.y / 1.2;

      // float R = 1.2;

      if (length(pos) > R) {
        return vec4(0);
      }

      float long_0 = 0;
      float lat_0 = 0;

      float P = length(pos);
      float C = asin(P/R);

      float _long = long_0 + atan(
        pos.x * sin(C),
        (P * cos(lat_0) * cos(C) - pos.y * sin(long_0) * sin(C))
      );

      float lat = asin(
        cos(C) * sin(lat_0) + (
          pos.y * sin(C) * cos(lat_0) / P
        )
      );

      lat *= 1.8;
      _long *= 0.8;

      vec2 source = (vec2(_long, lat) / PI * 2 + 1) / 2;


      float darken = min(1, 1.1 - pow(length(pos) / R, 5));

      vec4 final = Texel(tex, source);
      return vec4(final.rgb * darken, final.a);
    }
  ]]

  new: (@radius=1.2) =>
    @canvas = g.newCanvas!
    @canvas\setFilter "nearest", "nearest"
    @effect = g.newPixelEffect @shader!

  render: (fn) =>
    old_canvas = g.getCanvas!

    g.setCanvas @canvas
    @canvas\clear 0,0,0,0
    fn!
    setCanvas old_canvas

    g.setBlendMode "premultiplied"
    g.setPixelEffect @effect unless @disabled
    @effect\send "R", @radius
    g.draw @canvas, 0,0
    g.setPixelEffect!
    g.setBlendMode "alpha"


class ColorSeparate
  shader: -> [[
    extern number factor;

    vec4 effect(vec4 color, sampler2D tex, vec2 st, vec2 pixel_coords) {
      // return Texel(tex, st);
      float dist = length((st - 0.5) * 2);

      if (dist < 0.5) {
        return Texel(tex, st);
      }

      dist -= 0.5;

      float delta = dist/factor;

      float r = Texel(tex, vec2(st.x + delta, st.y)).r;
      float g = Texel(tex, vec2(st.x, st.y + delta)).g;
      float b = Texel(tex, vec2(st.x - delta, st.y)).b;
      float a = Texel(tex, vec2(st.x, st.y)).a;

      return vec4(r,g,b, a);
    }
  ]]

  new: (@factor=50) =>
    @canvas = g.newCanvas!
    @canvas\setFilter "nearest", "nearest"
    @canvas\setWrap "repeat", "repeat"
    @effect = g.newPixelEffect @shader!

  render: (fn) =>
    old_canvas = g.getCanvas!

    g.setCanvas @canvas
    @canvas\clear 0,0,0,0
    fn!
    setCanvas old_canvas

    g.setBlendMode "premultiplied"
    g.setPixelEffect @effect unless @disabled
    @effect\send "factor", @factor
    g.draw @canvas, 0,0
    g.setPixelEffect!
    g.setBlendMode "alpha"


