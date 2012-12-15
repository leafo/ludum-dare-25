
require "lovekit.all"

{graphics: g, :timer} = love

p = (str, ...) -> g.print str\lower!, ...

class Player
  size: 10
  x: 10
  y: 10

  update: (dt) =>

  draw: =>
    g.rectangle "fill", @x, @y, @size, @size

class Game
  new: =>
    @viewport = EffectViewport scale: 3

    @player = Player!

  draw: =>
    @viewport\apply!
    @player\draw dt
    p tostring(timer.getFPS!), 2, 2
    @viewport\pop!

  update: (dt) =>
    @player\update dt

  keypressed: (key) =>
    print "key: #{key}"


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

