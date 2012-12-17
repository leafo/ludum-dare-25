
{:effects} = lovekit
{graphics: g, :timer, :mouse, :keyboard} = love

{:sin, :cos, :min} = math

import approach_dir from require "util"

export *

class FlyOut extends effects.Effect
  before: =>
    g.push!
    p = @p!
    g.scale p*2 + 1
    g.setColor 255,255,255, (1 - p) * 255

  after: =>
    g.pop!

class Tank
  locked: false
  hidden: false

  ox: 6
  oy: 6
  sprite: "8,8,14,12"

  size: 8

  speed: 80
  spin: 10 -- rads a second

  new: (@x, @y) =>
    @box = Box 0,0, @size, @size
    @dir = Vec2d 1,0
    @guns = {}
    -- @gun = MachineGun @
    @update_box!

    @loadout!

    if @effects
      @effects\clear @
    else
      @effects = EffectList @

  loadout: =>
    @mount_gun TankGun, 0, 0

  mount_gun: (gun, x=0, y=0) =>
    table.insert @guns, { gun(@), x, y }

  update: (dt) =>
    @moving = false
    for mount in *@guns
      mount[1]\update dt

    @effects\update dt

    if @hit_seq
      @hit_seq\update dt
      @update_box!

  shove: (box, dist=10, dur=0.3) =>
    @effects\add effects.Flash!
    @hit_seq = Sequence ->
      dir = box\vector_to(@box)\normalized! * dist
      tween @, dur, x: @x + dir.x, y: @y + dir.y
      @hit_seq = nil

  aim_to: (dt, pt) =>
    return if @locked

    for mount in *@guns
      {gun, gx, gy} = mount
      {ox, oy} = Vec2d(gx, gy)\rotate @dir\radians!
      dir = pt - Vec2d @x + ox, @y + oy
      gun\aim_to dt, dir

  shoot: =>
    return if @locked

    for mount in *@guns
      mount[1]\shoot unpack mount, 2

  move: (dt, dir) =>
    return if @locked

    @moving = true
    approach_dir @dir, dir, @spin * dt

    @x += @dir[1] * @speed * dt
    @y += @dir[2] * @speed * dt
    @update_box!

  update_box: =>
    hsize = @size/2
    @box.x = @x - hsize
    @box.y = @y - hsize

  draw: =>
    return if @hidden

    g.push!
    g.translate @x, @y

    @effects\before!

    -- body
    sprite\draw @sprite, 0,0, @dir\radians!, nil, nil, @ox, @oy

    for mount in *@guns
      mount[1]\draw unpack mount, 2

    @effects\after!

    g.pop!
    -- @box\outline!

class Player extends Tank
  suck_radius: 50
  mover = make_mover "w", "s", "a", "d"

  score: 0
  display_score: 0

  inner_ring: {
    sprite: "101,133,22,22"
    size: 22
  }

  outer_ring: {
    sprite: "92,92,40,40"
    size: 40
  }

  new: (x, y) =>
    super x,y
    @held_energy = {}
    @ring_alpha = 0

  loadout: =>
    -- @mount_gun MachineGun, 0, -4
    -- @mount_gun MachineGun, 0, 4
    @mount_gun SpreadGun, 0, 0

  shoot: (...) =>
    return if @sucking
    super ...

  update: (dt, world) =>
    super dt

    unless @hit_seq
      dir = mover!
      if not dir\is_zero!
        @move dt, dir

    mpos = Vec2d world.viewport\unproject mouse.getPosition!
    @aim_to dt, mpos

    if @sucking = keyboard.isDown " "
      radius = @suck_radius_box!
      for e in *world.collide\get_touching radius
        if e.is_energy and e.alive and not e.gravity_parent
          table.insert @held_energy, e
          e.gravity_parent = @
    else
      for e in *@held_energy
        e.gravity_parent = nil
      @held_energy = {}

    target_alpha, alpha_rate = if @sucking then 255, 5 else 0, 3
    @ring_alpha = approach @ring_alpha, target_alpha, dt * 255 * alpha_rate

    @display_score = approach @display_score, @score,
      dt * ((@score - @display_score) * 1.5 + 14)

  take_hit: (thing, world) =>
    return if @hit_seq
    if thing.is_enemy
      sfx\play "hit2"
      world.viewport\shake!
      @shove thing.box

  enemy_killed: (thing, world) =>
    @score += thing.score if thing.score
    if math.random! > 0.5
      world.entities\add Energy thing.x, thing.y

  draw: =>
    super!
    if @ring_alpha > 0
      t = timer.getTime()
      scale = 1.0 + sin(t * 8) * 0.1

      g.setColor 255,255,255, @ring_alpha
      half = @outer_ring.size / 2
      sprite\draw @outer_ring.sprite, @x, @y, t * 4,
        scale, nil, half, half

      half = @inner_ring.size / 2
      sprite\draw @inner_ring.sprite, @x, @y, t * -5,
        scale, nil, half, half

      g.setColor 255,255,255, 255

      -- @suck_radius_box!\outline!

  suck_radius_box: =>
    half = @suck_radius / 2
    Box @x - half, @y - half, @suck_radius, @suck_radius

  __tostring: => "Player<>"

  take_off: (done_fn) =>
    return if @locked

    @locked = true
    e = FlyOut 0.5
    e.on_finish = done_fn
    @effects\add e

