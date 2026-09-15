
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
    @effect = g.newShader @shader!

  render: (fn) =>
    old_canvas = g.getCanvas!

    g.setCanvas @canvas
    g.clear 0,0,0,0
    g.push!
    g.scale @scale, @scale
    fn!
    g.pop!
    setCanvas old_canvas

    fn!
    g.setColor 1,1,1,100/255

    g.push!
    g.scale 1/@scale, 1/@scale
    g.draw @canvas, 0,0
    g.pop!

    g.setColor 1,1,1,1


class Projector
  -- preview toggles, see Game keypressed
  @lit: true
  @azimuthal: true

  -- azimuthal: where the planet's rim sits as a fraction of the screen's half
  -- width, so the sides always show space. the vertical crop follows from the
  -- aspect: 25% overflow on 16:9, 11% on 4:3
  az_width_fill: 0.845

  -- shading shared by both projections: pos is the screen point in sphere
  -- units, P its length, nz the z of the surface normal there
  shade_src: [[
    extern number R;
    extern number lit;    // 1 = directional lighting, 0 = the original rim darken
    extern number edge_w; // width of one screen pixel in pos units, for the rim AA

    vec4 shade(vec4 final, vec2 pos, float P, float nz) {
      if (lit < 0.5) {
        float darken = min(1.0, 1.1 - pow(P / R, 5.0));
        return vec4(final.rgb * darken, final.a);
      }

      // the surface normal is the sphere point itself
      vec3 n = vec3(pos / R, nz);
      vec3 light = normalize(vec3(-0.5, -0.6, 0.7));
      float lambert = max(0.0, dot(n, light));
      float shade = 0.3 + 0.7 * lambert;
      // keep true colors around the player, let the shading fade in toward the rim
      shade = mix(1.0, shade, smoothstep(0.15, 1.0, P / R));
      // faint light wrapping around the far edge, premultiplied by alpha
      float rim = 0.25 * pow(1.0 - nz, 3.0) * final.a;

      // soften the silhouette over one pixel
      float edge = 1.0 - smoothstep(R - edge_w, R, P);

      vec3 rgb = final.rgb * shade + vec3(rim);
      return vec4(rgb, final.a) * edge;
    }
  ]]

  -- the original: canvas rows and columns become lines of latitude and
  -- longitude, with per axis gains that fit the sphere to the canvas
  shader: => @shade_src .. [[
    extern number yscale;
    extern number lat_scale;

    float PI = 3.14159265358979323846264;
    vec4 effect(vec4 color, sampler2D tex, vec2 st, vec2 pixel_coords) {
      vec2 pos = (st - 0.5) * 2.0;
      pos.x = pos.x * 1.4;
      pos.y = pos.y * yscale;

      float P = length(pos);
      if (P > R) {
        return vec4(0.0);
      }

      float C = asin(P/R);
      float _long = atan(pos.x * sin(C), P * cos(C));
      float lat = asin(pos.y * sin(C) / P);

      lat *= lat_scale;
      _long *= 0.8;

      vec2 source = (vec2(_long, lat) / PI * 2.0 + 1.0) / 2.0;
      return shade(Texel(tex, source), pos, P, cos(C));
    }
  ]]

  -- azimuthal equidistant: the canvas is a flat map tangent at the player,
  -- distance from the center on the canvas is proportional to the angle on
  -- the sphere. pos is isotropic in screen pixels so the planet is a circle
  azimuthal_shader: => @shade_src .. [[
    extern vec2 pos_scale; // screen uv to sphere units, aspect and overflow
    extern number zoom;    // canvas pixels per radian
    extern vec2 texel;     // size of one canvas pixel in uv

    vec4 effect(vec4 color, sampler2D tex, vec2 st, vec2 pixel_coords) {
      vec2 pos = (st - 0.5) * 2.0 * pos_scale;

      float P = length(pos);
      if (P > R) {
        return vec4(0.0);
      }

      float C = asin(min(1.0, P / R));
      vec2 source = 0.5 + (pos / max(P, 1e-5)) * C * zoom * texel;
      return shade(Texel(tex, source), pos, P, cos(C));
    }
  ]]

  new: (@radius=1.2) =>
    w, h = g.getWidth!, g.getHeight!

    -- equirect: the planet is an ellipse in screen space, squash y so it stays round on any aspect
    @yscale = 1.48 * h / w
    -- 1.8 was tuned for 16:9 where the screen edge cuts the sphere before the
    -- canvas edge. on taller aspects the top of the screen would sample past the
    -- canvas and smear its last row, so cap the gain to land on the edge instead.
    -- measured against the ground radius so every projector shares the same gain
    @lat_scale = math.min 1.8, math.pi / (2 * math.asin math.min 1, @yscale / 1.2)
    @edge_w = 2 * math.max 1.4 / w, @yscale / h

    -- azimuthal: zoom in until the screen edges reach the canvas edges, whichever
    -- axis hits first. measured against the ground radius so the layers line up
    half_w = 1.2 / @az_width_fill
    @pos_scale = { half_w, half_w * h / w }
    top_angle = math.asin math.min 1, @pos_scale[2] / 1.2
    side_angle = math.asin math.min 1, @pos_scale[1] / 1.2
    @zoom = math.min (h / 2) / top_angle, (w / 2) / side_angle
    @az_edge_w = 2 * @pos_scale[2] / h

    @canvas = g.newCanvas w, h
    @effect = g.newShader @shader!
    @az_effect = g.newShader @azimuthal_shader!

  render: (fn) =>
    old_canvas = g.getCanvas!

    g.setCanvas @canvas
    g.clear 0,0,0,0
    fn!
    setCanvas old_canvas

    -- linear filtering calms the shimmer where the rim squeezes many canvas
    -- pixels into one, nearest keeps the original look for comparison
    lit = @@lit
    filter = if lit then "linear" else "nearest"
    @canvas\setFilter filter, filter

    g.setBlendMode "alpha", "premultiplied"
    effect = if @@azimuthal
      with @az_effect
        \send "pos_scale", @pos_scale
        \send "zoom", @zoom
        \send "texel", { 1 / @canvas\getWidth!, 1 / @canvas\getHeight! }
        \send "edge_w", @az_edge_w
    else
      with @effect
        \send "yscale", @yscale
        \send "lat_scale", @lat_scale
        \send "edge_w", @edge_w

    effect\send "R", @radius
    effect\send "lit", lit and 1 or 0
    g.setShader effect unless @disabled
    g.draw @canvas, 0,0
    g.setShader!
    g.setBlendMode "alpha"


class ColorSeparate
  shader: -> [[
    extern number factor;

    vec4 effect(vec4 color, sampler2D tex, vec2 st, vec2 pixel_coords) {
      // return Texel(tex, st);
      float dist = length((st - 0.5) * 2.0);

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
    @canvas = g.newCanvas g.getWidth!, g.getHeight!
    @canvas\setFilter "nearest", "nearest"
    @effect = g.newShader @shader!

  render: (fn) =>
    old_canvas = g.getCanvas!

    g.setCanvas @canvas
    g.clear 0,0,0,0
    fn!
    setCanvas old_canvas

    g.setBlendMode "alpha", "premultiplied"
    g.setShader @effect unless @disabled
    @effect\send "factor", @factor
    g.draw @canvas, 0,0
    g.setShader!
    g.setBlendMode "alpha"


