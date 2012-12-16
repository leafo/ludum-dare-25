
{graphics: g} = love

import approach_dir from require "util"

export *

class Bullet extends Box
  size: 3
  alive: true
  is_bullet: true
  speed: -> 130

  new: (@vel, x, y, @tank) =>
    super x,y, @size, @size
    @rads = @vel\normalized!\radians!

  update: (dt, world) =>
    @move unpack @vel * dt
    world.viewport\touches_box @

  draw: =>
    g.rectangle "line", @x, @y, @w, @h

  __tostring: => "Bullet<#{Box.__tostring self}>"

class Gun
  ox: 2
  oy: 2

  recoil_1: 0.1
  recoil_2: 0.2

  bullet: Bullet
  speed: 130

  w: 9 -- to tip of gun from origin

  sprite: "24,12,11,4"

  new: (@tank) =>
    @dir = Vec2d 1,0
    @time = 0

  draw: (gx, gy) =>
    gx, gy = unpack Vec2d(gx, gy)\rotate @tank.dir\radians!
    sprite\draw @sprite, gx, gy, @dir\radians!, nil, nil, @ox, @oy

  update: (dt) =>
    @time += dt*4
    if @seq and not @seq\update dt
      @seq = nil

  aim_to: (dt, dir) =>
    spin = @spin or @tank.spin
    approach_dir @dir, dir, dt * spin

  shoot: (gx, gy) =>
    return if @seq

    offset = Vec2d(@w, 0)\rotate(@dir\radians!) + Vec2d(gx, gy)\rotate @tank.dir\radians!

    x = @tank.x + offset.x
    y = @tank.y + offset.y

    dir = if @spread
      rad = @dir\radians!
      Vec2d.from_radians rad + @spread * (math.random! - 0.5)
    else
      @dir

    speed = @bullet.speed!
    vel = dir * @bullet.speed!

    if @tank.moving
      new_vel = vel + @tank.dir * @tank.speed / 2
      unless new_vel\len! < speed
        vel = new_vel

    @tank.world.entities\add @bullet, vel, x,y, @tank

    @seq = Sequence ->
      ox = @ox
      tween @, @recoil_1, ox: ox - 2
      tween @, @recoil_2, ox: ox

class MachineGun extends Gun
  recoil_1: 0.05
  recoil_2: 0.05

  spread: math.pi / 8

  bullet: class extends Bullet
    ox: 4
    oy: 1

    sprite: "38,12,6,3"
    size: 1
    draw: =>
      sprite\draw @sprite, @x, @y, @rads, nil, nil, @ox, @oy


