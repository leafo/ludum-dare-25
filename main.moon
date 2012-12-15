
require "lovekit.all"

require "project"

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


class Bullet extends Box
  size: 3
  alive: true

  new: (@vel, x, y) =>
    super x,y, @size, @size

  update: (dt, world) =>
    @move unpack @vel * dt
    world.viewport\touches_box @

  draw: =>
    g.rectangle "line", @x, @y, @w, @h

class Gun
  w: 2
  h: 10

  ox: 0
  oy: 0

  speed: 100

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

  shoot: =>
    return if @seq

    x = @tank.x + @dir.x * @h
    y = @tank.y + @dir.y * @h

    vel = @dir * @speed

    if @tank.moving
      new_vel = vel + @tank.dir * @tank.speed
      unless new_vel\len! < @speed
        vel = new_vel

    @tank.world.entities\add Bullet, vel, x,y

    @seq = Sequence ->
      tween @, 0.1, ox: -2
      tween @, 0.2, ox: 0

class Tank
  w: 10
  h: 12

  speed: 80
  spin: 10 -- rads a second

  new: (@x, @y) =>
    @dir = Vec2d 1,0
    @gun = Gun @

  update: (dt) =>
    @moving = false
    @gun\update dt if @gun

  move: (dt, dir) =>
    @moving = true
    approach_dir @dir, dir, @spin * dt

    @x += @dir[1] * @speed * dt
    @y += @dir[2] * @speed * dt

  draw: =>
    hw = f @w/2
    hh = f @h/2

    g.push!
    g.translate @x, @y

    -- body
    g.push!
    g.rotate @dir\radians!

    g.rectangle "fill", -hh, -hw, @h, @w -- this is confusing..

    g.setColor 255, 100, 100
    g.rectangle "fill", f(hh/3), -1, 2,2
    g.pop!

    @gun\draw! if @gun

    g.setColor 255, 255, 255
    g.pop!

class Player extends Tank
  mover = make_mover "w", "s", "a", "d"

  new: (x, y, @world) =>
    super x,y

  update: (dt) =>
    super dt
    dir = mover!
    if not dir\is_zero!
      @move dt, dir

    mpos = Vec2d @world.viewport\unproject mouse.getPosition!
    if @gun
      aim_dir = mpos - Vec2d(@x, @y)
      approach_dir @gun.dir, aim_dir, dt * @spin

class World
  disable_project: false
  blur_scale: 0.2

  new: (@player) =>
    @viewport = EffectViewport scale: 3
    @player.world = @

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
    @map\update dt
    @player\update dt
    @entities\update dt, @

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

