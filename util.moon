
import cos,sin,abs from math

{graphics: g} = love

approach_dir = do
  PI = math.pi
  (vec, dir, delta) ->
    rads = vec\radians!
    target = dir\radians!

    sep = target - rads
    if sep < -PI
      target += 2 * PI
    elseif sep > PI
      rads += 2 * PI

    local new_dir
    if rads < target
      new_dir = rads + delta
      new_dir = target if new_dir > target
    else
      new_dir = rads - delta
      new_dir = target if new_dir < target

    vec[1] = cos new_dir
    vec[2] = sin new_dir
    new_dir == target

box_text = (msg, x, y, center=true) ->
  msg = msg\lower!

  w, h = fonts.main\getWidth(msg), fonts.main\getHeight!
  g.push!

  if center
    g.translate x - w/2, y - h/2
  else
    g.translate x, y - h/2

  g.setColor 255,255,255
  g.rectangle "fill", 0,0,w,h
  g.setColor 0,0,0
  g.print msg, 0,0
  g.pop!

{ :approach_dir, :box_text }

