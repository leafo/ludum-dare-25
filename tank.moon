
{:effects} = lovekit
{graphics: g, :timer, :mouse} = love

import approach_dir from require "util"

export *

class Tank
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
    for mount in *@guns
      {gun, gx, gy} = mount
      {ox, oy} = Vec2d(gx, gy)\rotate @dir\radians!
      dir = pt - Vec2d @x + ox, @y + oy
      gun\aim_to dt, dir

  shoot: =>
    for mount in *@guns
      mount[1]\shoot unpack mount, 2

  move: (dt, dir) =>
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
    @effects\before!

    g.push!
    g.translate @x, @y

    -- body
    sprite\draw @sprite, 0,0, @dir\radians!, nil, nil, @ox, @oy

    for mount in *@guns
      mount[1]\draw unpack mount, 2

    g.pop!

    @effects\after!
    -- @box\outline!

class Player extends Tank
  mover = make_mover "w", "s", "a", "d"

  new: (x, y, @world) =>
    super x,y

  loadout: =>
    @mount_gun MachineGun, 0, -4
    @mount_gun MachineGun, 0, 4

  update: (dt) =>
    super dt

    unless @hit_seq
      dir = mover!
      if not dir\is_zero!
        @move dt, dir

    mpos = Vec2d @world.viewport\unproject mouse.getPosition!
    @aim_to dt, mpos

  take_hit: (thing) =>
    return if @hit_seq
    if thing.is_enemy
      @world.viewport\shake!
      @shove thing.box


