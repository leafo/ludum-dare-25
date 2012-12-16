
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

class Explosion extends Sequence
  alive: true

  Smoke = class extends Particle
    sprite: "64,16,16,16"
    new: (...) =>
      @rot = random! * math.pi / 2
      super ...
      @vel = Vec2d.random! * (random! * 20 + 20)
      @accel = @vel * -1

    draw: =>
      p = @p!
      a = (1 - p) * 255

      g.setColor @r, @g, @b, a

      scale = 1 + p * 0.5
      sprite\draw @sprite, @x, @y, p * @rot, scale, scale, 8, 8

  Flare = class extends Particle
    sprite: "48,32,32,32"
    draw: =>
      p = @p!

      a = if p < 0.5
        p * 2 * 255
      else
        (1 - p) * 2 * 255

      scale = @p! * 2 + 0.3

      g.setColor @r, @g, @b, a
      sprite\draw @sprite, @x, @y, nil, scale, scale, 16, 16

  Fire = class extends Particle
    sequence: { 3,4,5,6,7,8,9,10,11 }

    new: (x,y) =>
      super x,y
      @anim = Animator sprite, @sequence, 0.05
      @anim.once = true

    update: (dt) =>
      @anim\update dt
      super dt

    draw: =>
      a = linear_step @p!, 255,0, 0.5

      g.setColor @r, @g, @b, a
      @anim\draw @x - 8, @y - 8

  new: (@world, x, y) =>
    super ->
      @world.particles\add Fire x, y
      @world.particles\add Flare x, y

      for i=1,3
        @world.particles\add Smoke x, y

      for i=1,4
        wait 0.1
        rads = random! * math.pi * 2
        offset = Vec2d.from_radians(rads) * (random! * 5 + 5)
        @world.particles\add Fire x + offset.x, y + offset.y

  draw: =>
