
-- reloader = require "lovekit.reloader"
require "lovekit.all"

require "project"
require "particles"
require "guns"
require "tank"
require "enemies"
require "pickup"
require "ui"
require "world"

require "lovekit.screen_snap"

{graphics: g, :timer, :mouse} = love
{floor: f, min: _min, :cos, :sin, :abs} = math

p = (str, ...) -> g.print str\lower!, ...

export fonts = {}
export sprite, dispatch, sfx

local snapper
local Game

class Title
  new: =>
    @viewport = EffectViewport scale: 3
    @title_image = imgfy "img/title.png"
    @shroud_alpha = 0
    @colors = ColorSeparate!

  onload: =>
    sfx\play_music "xmoon-title"

  draw: =>
    @colors\render ->
      @viewport\apply!
      @title_image\draw 0,0

      cx, cy = @viewport\center!
      @box_text "Press Enter To Begin", cx, cy - 10

      if @shroud_alpha > 0
        @viewport\draw {0,0,0, @shroud_alpha}

      g.setColor 255,255,255,255
      @viewport\pop!

  box_text: (msg, x, y) =>
    msg = msg\lower!
    w, h = fonts.main\getWidth(msg), fonts.main\getHeight!
    g.push!
    g.translate x - w/2, y - h/2
    g.rectangle "fill", 0,0,w,h
    g.setColor 0,0,0
    g.print msg, 0,0
    g.pop!

  update: (dt) =>
    @seq\update dt if @seq
    @colors.factor = math.sin(timer.getTime! * 3) * 25 + 75

  on_key: (key) =>
    if key == "return" or key == " "
      @transition_to Game!

  transition_to: (state) =>
    @seq = Sequence ->
      tween @, 1.0, shroud_alpha: 255
      dispatch\push state
      @shroud_alpha = 0
      @seq = nil

class Game
  paused: false

  new: =>
    @player = Player 100, 100, @
    @world = World @player

  onload: =>
    sfx\play_music "xmoon"

  draw: => @world\draw!

  update: (dt) =>
    return if dt > 0.5

    reloader\update! if reloader
    return if @paused

    if mouse.isDown "l"
      @player\shoot!

    @world\update dt
    snapper\tick! if snapper

  on_key: (key) =>
    with @world
      switch key
        when "1"
          if snapper
            snapper\write!
            snapper = nil
          else
            snapper = ScreenSnap!
        when "p"
          @paused = not @paused
        when "x"
          .disable_project = not .disable_project
    false

  mousepressed: (x,y) =>
    x, y = @world.viewport\unproject x,y
    -- @world.particles\add EnergyEmitter @world, x,y
    @world.entities\add Energy, x,y
    -- print "boom: #{x}, #{y}"
    -- @world.particles\add Explosion @world, x,y

load_font = (img, chars)->
  font_image = imgfy img
  g.newImageFont font_image.tex, chars

love.load = ->
  g.setBackgroundColor 61/2, 52/2, 47/2
  g.setPointSize 12
  sprite = Spriter "img/sprite.png", 16
  fonts.main = load_font "img/font.png",
    [[ abcdefghijklmnopqrstuvwxyz-1234567890!.,:;'"?$&]]

  g.setFont fonts.main

  export sfx = lovekit.audio.Audio "sounds"
  sfx\preload {
    "machine-gun"
    "hit1"
    "boom"
    "energy-collect"
  }

  sfx.play_music = ->
  dispatch = Dispatcher Game! -- Title!
  dispatch\bind love

