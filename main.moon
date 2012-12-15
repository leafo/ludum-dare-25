
require "lovekit.all"

{graphics: g, :timer} = love
{floor: f} = math

p = (str, ...) -> g.print str\lower!, ...

import cos,sin,abs from math

class Tank
  w: 10
  h: 12

  speed: 80
  spin: 8 -- rads a second

  new: (@x, @y) =>
    @dir = Vec2d 1,0
    @shoot_dir = Vec2d 1,0

  update: (dt) =>

  move: (dt, dir) =>
    rads = @dir\radians!
    target = dir\radians!

    sep = target - rads
    if sep < -math.pi
      target += 2 * math.pi
    elseif sep > math.pi
      rads += 2 * math.pi

    delta = @spin * dt

    local new_dir
    if rads < target
      new_dir = rads + delta
      new_dir = target if new_dir > target
    else
      new_dir = rads - delta
      new_dir = target if new_dir < target

    @dir[1] = cos new_dir
    @dir[2] = sin new_dir

    @x += @dir[1] * @speed * dt
    @y += @dir[2] * @speed * dt

  draw: =>
    hw = f @w/2
    hh = f @h/2

    g.push!
    g.translate @x, @y

    g.rotate @dir\radians!

    g.rectangle "fill", -hh, -hw, @h, @w -- this is confusing..

    g.setColor 255, 100, 100
    g.rectangle "fill", f(hh/3), -1, 2,2
    g.setColor 255, 255, 255

    g.pop!

class Player extends Tank
  mover = make_mover "w", "s", "a", "d"

  update: (dt) =>
    dir = mover!
    if not dir\is_zero!
      @move dt, dir
      move = dir * @speed * dt

    -- @rot += dt

class Game
  new: =>
    @viewport = EffectViewport scale: 3

    @player = Player 100, 100

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

