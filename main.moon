
require "lovekit.all"

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

class Gun
  w: 2
  h: 10

  new: (@tank) =>
    @dir = Vec2d 1,0

  draw: =>
    g.push!
    g.rotate @dir\radians!
    g.setColor 180, 180, 180
    g.rectangle "fill", -1, -1, f(@h), 2
    g.pop!

  update: (dt) =>

class Tank
  w: 10
  h: 12

  speed: 80
  spin: 10 -- rads a second

  new: (@x, @y) =>
    @dir = Vec2d 1,0
    @gun = Gun @

  update: (dt) =>
    -- @gun\update! if @gun

  move: (dt, dir) =>
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
    dir = mover!
    if not dir\is_zero!
      @move dt, dir

    mpos = Vec2d @world.viewport\unproject mouse.getPosition!
    if @gun
      aim_dir = mpos - Vec2d(@x, @y)
      approach_dir @gun.dir, aim_dir, dt * @spin

class Game
  new: =>
    @viewport = EffectViewport scale: 3
    @player = Player 100, 100, @

  draw: =>
    @viewport\apply!
    @player\draw dt
    p tostring(timer.getFPS!), 2, 2
    @viewport\pop!

  update: (dt) =>
    @player\update dt

  keypressed: (key) =>
    print "key: #{key}"

  mousepressed: (x,y) =>
    print "mouse", x,y


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

