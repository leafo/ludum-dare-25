
require "lovekit.all"

require "project"

{:effects} = lovekit
{graphics: g, :timer, :mouse} = love
{floor: f} = math

p = (str, ...) -> g.print str\lower!, ...

import cos,sin,abs from math

local sprite

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

class Tank
  ox: -6
  oy: -6
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

    @mount_gun MachineGun, 0, -4
    @mount_gun MachineGun, 0, 4

    if @effects
      @effects\clear @
    else
      @effects = EffectList @

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
    g.push!
    g.rotate @dir\radians!

    sprite\draw_cell @sprite, @ox, @oy

    g.pop!

    for mount in *@guns
      mount[1]\draw unpack mount, 2

    g.pop!

    @effects\after!
    -- @box\outline!

class Player extends Tank
  mover = make_mover "w", "s", "a", "d"

  new: (x, y, @world) =>
    super x,y

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

class Enemy extends Tank
  is_enemy: true
  color: {255, 200, 200}
  spin: 4
  speed: 20

  new: (...) =>
    super ...
    @ai = Sequence ->
      dir = Vec2d.random!
      during 0.5, (dt) ->
        @move dt, dir

      pt = Vec2d.random! * 50 + Vec2d @x, @y
      during 0.5, (dt) ->
        if @aim_to dt, pt
          "cancel"

      @shoot dt
      wait 1.0

      again!

  take_hit: (thing) =>
    if thing.is_bullet
      thing.alive = false
      @shove thing, 5, 0.2

  update: (dt, world) =>
    @world = world
    @ai\update dt
    super dt
    true

  __tostring: => "Enemy<#{@box}>"

class World
  disable_project: false
  blur_scale: 0.2

  new: (@player) =>
    @viewport = EffectViewport scale: 3
    @player.world = @
    @collide = UniformGrid!

    @entities = ReuseList!

    @ground_project = Projector 1.2
    @entity_project = Projector 1.3

    -- @blur_project = Glow @blur_scale

    tile_sprite = Spriter "img/tiles.png", 16
    tiles = setmetatable { {tid: 0} }, { __index: => @[1] }
    @map = with TileMap 32, 32
      .sprite = tile_sprite
      \add_tiles tiles

    @map_box = Box 0,0, @map.real_width, @map.real_height

    -- -- create some enemies
    @entities\add Enemy, 150, 150

  draw_ground: =>
    @viewport\apply!
    @map\draw @viewport
    @viewport\pop!

  draw_entities: =>
    @viewport\apply!
    @player\draw dt
    @entities\draw!
    @viewport\pop!

  draw: =>
    @viewport\center_on_pt @player.x, @player.y, @map_box

    if @disable_project
      @draw_ground!
      @draw_entities!
    else
      @ground_project\render -> @draw_ground!
      @entity_project\render -> @draw_entities!

    g.setColor 0,0,0
    hud_height = 80
    g.rectangle "fill", 0, 0, g.getWidth!, hud_height

    g.rectangle "fill", 0, g.getHeight! - hud_height,
      g.getWidth!, hud_height

    g.setColor 255,255,255

    g.scale 2
    p tostring(timer.getFPS!), 2, 2

  update: (dt) =>
    @viewport\update dt
    @map\update dt
    @player\update dt
    @entities\update dt, @

    -- respond to collision
    @collide\clear!
    @collide\add @player.box, @player
    for e in *@entities
      if e.alive != false
        if e.box
          @collide\add e.box, e
        else
          @collide\add e

    for thing in *@collide\get_touching @player.box
      @player\take_hit thing

    for enemy in *@entities
      continue unless enemy.is_enemy
      for thing in *@collide\get_touching enemy.box
        enemy\take_hit thing

class Game
  new: =>
    @player = Player 100, 100, @
    @world = World @player

  draw: => @world\draw!
  update: (dt) =>
    if mouse.isDown "l"
      @player\shoot!

    @world\update dt

  on_key: (key) =>
    with @world
      switch key
        when " "
          .disable_project = not .disable_project
    false

  mousepressed: (x,y) =>

export fonts = {}
load_font = (img, chars)->
  font_image = imgfy img
  g.newImageFont font_image.tex, chars

love.load = ->
  g.setBackgroundColor 61/2, 52/2, 47/2
  sprite = Spriter "img/sprite.png"
  fonts.main = load_font "img/font.png",
    [[ abcdefghijklmnopqrstuvwxyz-1234567890!.,:;'"?$&]]

  g.setFont fonts.main

  d = Dispatcher Game!
  d\bind love

