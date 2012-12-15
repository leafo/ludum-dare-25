
require "lovekit.all"

require "project"

{:effects} = lovekit
{graphics: g, :timer, :mouse} = love
{floor: f} = math

p = (str, ...) -> g.print str\lower!, ...

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


class Bullet extends Box
  size: 3
  alive: true
  is_bullet: true

  new: (@vel, x, y, @tank) =>
    super x,y, @size, @size

  update: (dt, world) =>
    @move unpack @vel * dt
    world.viewport\touches_box @

  draw: =>
    g.rectangle "line", @x, @y, @w, @h

  __tostring: => "Bullet<#{Box.__tostring self}>"

class Gun
  w: 2
  h: 10

  ox: 0
  oy: 0

  speed: 130

  new: (@tank) =>
    @dir = Vec2d 1,0

  draw: =>
    g.push!
    g.rotate @dir\radians!
    g.setColor 180, 180, 180
    g.rectangle "fill", -1 + @ox, -1 + @oy, f(@h), 2
    g.pop!

  update: (dt) =>
    if @seq and not @seq\update dt
      @seq = nil

  aim_to: (dt, dir) =>
    spin = @spin or @tank.spin
    approach_dir @dir, dir, dt * spin

  shoot: =>
    return if @seq

    x = @tank.x + @dir.x * @h
    y = @tank.y + @dir.y * @h

    vel = @dir * @speed

    if @tank.moving
      new_vel = vel + @tank.dir * @tank.speed
      unless new_vel\len! < @speed
        vel = new_vel

    @tank.world.entities\add Bullet, vel, x,y, @tank

    @seq = Sequence ->
      tween @, 0.1, ox: -2
      tween @, 0.2, ox: 0

class Tank
  w: 10
  h: 12

  size: 8

  color: {255,255,255}

  speed: 80
  spin: 10 -- rads a second

  new: (@x, @y) =>
    @box = Box 0,0, @size, @size
    @dir = Vec2d 1,0
    @gun = Gun @
    @update_box!

    if @effects
      @effects\clear @
    else
      @effects = EffectList @

  update: (dt) =>
    @moving = false
    @gun\update dt if @gun
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
    hw = f @w/2
    hh = f @h/2

    @effects\before!

    g.push!
    g.translate @x, @y

    -- body
    g.push!
    g.rotate @dir\radians!

    g.setColor @color
    g.rectangle "fill", -hh, -hw, @h, @w

    g.setColor 255, 100, 100
    g.rectangle "fill", f(hh/3), -1, 2,2
    g.pop!

    @gun\draw! if @gun

    g.setColor 255, 255, 255
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
    if @gun
      aim_dir = mpos - Vec2d(@x, @y)
      approach_dir @gun.dir, aim_dir, dt * @spin

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

      dir = Vec2d.random!
      during 0.5, (dt) ->
        if @gun\aim_to dt, dir
          "cancel"

      @gun\shoot dt, @world
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

    sprite = Spriter "img/tiles.png", 16
    tiles = setmetatable { {tid: 0} }, { __index: => @[1] }
    @map = with TileMap 32, 32
      .sprite = sprite
      \add_tiles tiles

    @map_box = Box 0,0, @map.real_width, @map.real_height

    -- create some enemies
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
    g.rectangle "fill", 0, g.getHeight! - hud_height, g.getWidth!, hud_height
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
      @player.gun\shoot!

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

  fonts.main = load_font "img/font.png", [[ abcdefghijklmnopqrstuvwxyz-1234567890!.,:;'"?$&]]

  g.setFont fonts.main

  d = Dispatcher Game!
  d\bind love

