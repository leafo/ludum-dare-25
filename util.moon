
import cos,sin,abs from math

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


{ :approach_dir }

