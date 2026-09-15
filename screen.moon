
{graphics: g, :mouse} = love

-- the game is drawn at the 640x480 handheld's pixel density. on taller windows
-- it renders into a canvas BASE_HEIGHT tall, as wide as the window's aspect,
-- and that canvas is scaled up to fill the window. shorter windows draw directly
BASE_HEIGHT = 480

-- sharp bilinear: nearest inside each canvas pixel, blending only across the
-- one screen pixel where a fractional scale puts a pixel edge between screen pixels
SHARP_BILINEAR = [[
  extern vec2 source_size;
  extern number scale;

  vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen_coords) {
    vec2 texel = uv * source_size;
    vec2 offset = fract(texel) - 0.5;
    float region = 0.5 - 0.5 / scale;
    vec2 f = (offset - clamp(offset, -region, region)) * scale + 0.5;
    return Texel(tex, (floor(texel) + f) / source_size) * color;
  }
]]

class Screen
  -- false scales the canvas up with plain nearest, for comparison
  sharp: true

  new: =>
    real_w, real_h = g.getWidth!, g.getHeight!
    @scale = real_h / BASE_HEIGHT
    return if @scale <= 1

    @w = math.floor real_w / @scale
    @h = BASE_HEIGHT
    @ox = math.floor (real_w - @w * @scale) / 2
    @oy = 0

    @canvas = with g.newCanvas @w, @h
      \setFilter "linear", "linear"

    @shader = with g.newShader SHARP_BILINEAR
      \send "source_size", { @w, @h }
      \send "scale", @scale

    -- everything that sizes itself from the screen sees the canvas instead.
    -- g.newCanvas! with no size still reads the real window, so size canvases explicitly
    g.getWidth = -> @w
    g.getHeight = -> @h
    g.getDimensions = -> @w, @h

    real_get_position = mouse.getPosition
    mouse.getPosition = -> @to_canvas real_get_position!

  toggle_sharp: =>
    @sharp = not @sharp
    return unless @canvas
    filter = if @sharp then "linear" else "nearest"
    @canvas\setFilter filter, filter

  -- window coordinates -> canvas coordinates
  to_canvas: (x, y) =>
    return x, y unless @canvas
    (x - @ox) / @scale, (y - @oy) / @scale

  draw: (fn) =>
    return fn! unless @canvas

    g.setCanvas @canvas
    g.clear g.getBackgroundColor!
    fn!
    g.setCanvas!

    g.origin!
    g.setColor 1,1,1,1
    g.setShader @shader if @sharp
    g.draw @canvas, @ox, @oy, 0, @scale, @scale
    g.setShader!

{ :Screen }
