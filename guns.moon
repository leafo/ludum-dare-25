
{graphics: g} = love

import approach_dir from require "util"

export *

class Bullet extends Box
  size: 3
  alive: true
  is_bullet: true
  speed: -> 130
  damage: {1,2}

  new: (@vel, x, y, @tank) =>
    super x,y, @size, @size
    @rads = @vel\normalized!\radians!

  update: (dt, world) =>
    @move unpack @vel * dt
    world.viewport\touches_box @

  draw: =>
    g.rectangle "line", @x, @y, @w, @h

  -- kill bullet and return damage
  on_hit: (thing, world) =>
    sfx\play "hit1"
    @alive = false
    {min, max} = @damage
    math.random! * (max - min) + min

  __tostring: => "Bullet<#{Box.__tostring self}>"


class SpriteBullet extends Bullet
  draw: =>
    sprite\draw @sprite, @x, @y, @rads, nil, nil, @ox, @oy

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
    @seq\update dt if @seq

  aim_to: (dt, dir) =>
    spin = @spin or @tank.spin
    approach_dir @dir, dir, dt * spin

  spawn_bullet: (vel, x,y) =>
    @tank.world.entities\add self.bullet vel, x,y, @tank

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

    @spawn_bullet vel, x, y

    @seq = Sequence ->
      ox = @ox
      tween @, @recoil_1, ox: ox + 2
      tween @, @recoil_2, ox: ox
      @seq = nil

    true

class MachineGun extends Gun
  recoil_1: 0.05
  recoil_2: 0.05

  sprite: "35,85,8,4"
  w: 6

  spread: math.pi / 8

  bullet: class extends SpriteBullet
    damage: {2,4}

    ox: 4
    oy: 1
    sprite: "38,12,6,3"
    size: 1

  spawn_bullet: (...) =>
    sfx\play "machine-gun"
    super ...

class TankGun extends Gun
  recoil_1: 0.1
  recoil_2: 0.4

  bullet: class extends SpriteBullet
    damage: {8,16}

    ox: 6
    oy: 2
    sprite: "35,5,9,5"

    on_hit: (thing, world) =>
      world.particles\add Explosion.Fire @x, @y
      super thing, world

  spawn_bullet: (...) =>
    sfx\play "shoot1"
    super ...

class SpreadGun extends Gun
  recoil_1: 0.1
  recoil_2: 0.3

  bullet: class extends SpriteBullet
    ox: 3
    oy: 3
    damage: {6,7}
    sprite: "40,18,7,7"

  spawn_bullet: (vel, x,y) =>
    sfx\play "shoot1"

    left = vel\rotate -0.2
    right = vel\rotate 0.2

    @tank.world.entities\add self.bullet left, x,y, @tank
    @tank.world.entities\add self.bullet vel, x,y, @tank
    @tank.world.entities\add self.bullet right, x,y, @tank

