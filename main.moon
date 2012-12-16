
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
require "levels"

require "lovekit.screen_snap"

{graphics: g, :timer, :mouse} = love
{floor: f, min: _min, :cos, :sin, :abs} = math

import box_text from require "util"

export fonts = {}
export sprite, dispatch, sfx

p = (str, ...) -> g.print str\lower!, ...

local snapper
local Game

class FadeOutScreen
  new: =>
    @viewport = EffectViewport scale: 3
    @shroud_alpha = 0
    @colors = ColorSeparate!

  draw_inner: =>

  update: (dt) =>
    @seq\update dt if @seq
    @colors.factor = math.sin(timer.getTime! * 3) * 25 + 75

  draw: =>
    @colors\render ->
      @viewport\apply!
      @draw_inner!

      if @shroud_alpha > 0
        @viewport\draw {0,0,0, @shroud_alpha}

      g.setColor 255,255,255,255
      @viewport\pop!

  transition: (fn) =>
    return if @seq
    @seq = Sequence ->
      tween @, 1.0, shroud_alpha: 255
      fn!
      @shroud_alpha = 0
      @seq = nil

  transition_to: (state) =>
    @transition -> dispatch\push state

class Title extends FadeOutScreen
  new: (...) =>
    @title_image = imgfy "img/title.png"
    super ...

  onload: =>
    sfx\play_music "xmoon-title"

  draw_inner: =>
    @title_image\draw 0,0
    cx, cy = @viewport\center!
    box_text "Press Enter To Begin", cx, cy - 10

  on_key: (key) =>
    if key == "return" or key == " "
      @transition_to Game!

class Intermission extends FadeOutScreen
  new: (@fn, ...) =>
    super ...

  draw_inner: =>
    cx, cy = @viewport\center!
    box_text "Congratulations", cx, cy - 10
    box_text "Press Enter To Go To Next Level", cx, cy + 10

  on_key: (key) =>
    if key == "return" or key == " "
      @transition @fn

class Game
  levels: {
    Level1
    Level2
  }

  paused: false

  new: =>
    @player = Player 100, 100, @
    @current_level = 0
    @load_next_world!

  load_next_world: =>
    @current_level += 1
    w = @levels[@current_level]
    error "Ran out of levels!" unless w
    @world = w @, @player

  onload: =>
    sfx\play_music "xmoon"

  draw: =>
    @world\draw!
    g.scale 2
    p tostring(timer.getFPS!), 2, 50

  update: (dt) =>
    return if dt > 0.5

    reloader\update! if reloader
    return if @paused

    if mouse.isDown "l"
      @player\shoot!

    @world\update dt
    snapper\tick! if snapper

  end_world: =>
    dispatch\push Intermission ->
      @load_next_world!

  on_key: (key) =>
    with @world
      switch key
        when "e"
          if @world\ready_to_blow!
            @world\blow_up_planet!
        -- when "1"
        --   if snapper
        --     snapper\write!
        --     snapper = nil
        --   else
        --     snapper = ScreenSnap!
        when "p"
          @paused = not @paused
        when "f1"
          .disable_project = not .disable_project
    false

  mousepressed: (x,y) =>
    x, y = @world.viewport\unproject x,y
    -- @world.particles\add EnergyEmitter @world, x,y
    -- @world.entities\add Energy x,y
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
    "hit2"
    "boom"
    "energy-collect"
  }

  sfx.play_music = ->
  dispatch = Dispatcher Title! -- Game!
  dispatch\bind love

