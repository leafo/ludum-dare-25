
{graphics: g} = love

import random from math

export *

linear_step = (p, left, right, start=0, stop=1) ->
  return left if p <= start
  return right if p >= stop

  p = (p - start) / (stop - start)
  right * p + left * (1 - p)

spread_dir = (dir, spread) ->
  dir\rotate (random! - 0.5) * spread

class NumberParticle extends Particle
  life: 0.8
  speed: 100
  spread: math.pi / 2

  new: (x, y, @str) =>
    super x,y
    rad = math.pi/2 + (random! - 0.5) * @spread
    @vel = Vec2d.from_radians(rad) * -@speed
    @accel = Vec2d 0, 400

    @dr = (random! - 0.5) * @spread
  
  draw: =>
    p = @p!
    a = linear_step p, 255, 0, 0.5

    g.setColor @r, @g, @b, a
    g.push!
    g.translate @x, @y
    g.print @str, 0,0, p * @dr, nil, nil, 4,4
    g.pop!


class SparkEmitter extends Emitter
  spread: math.pi / 8
  speed: 60

  P = class extends PixelParticle
    size: 1
    life: 0.3

  make_particle: (x,y) =>
    P x,y, spread_dir @dir * @speed, @spread

  new: (world, x,y, @dir) =>
    super world, x,y

