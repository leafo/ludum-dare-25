
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

{graphics: g, :timer, :mouse, :keyboard} = love
{floor: f, min: _min, :cos, :sin, :abs} = math

import box_text from require "util"

export fonts = {}
export sprite, dispatch, sfx

p = (str, ...) -> g.print str\lower!, ...

local snapper
local Game, Tutorial, Title

class FadeOutScreen
  scale: 3
  base_factor: 75
  new: =>
    @viewport = EffectViewport scale: @scale
    @shroud_alpha = 0
    @colors = ColorSeparate!

  draw_inner: =>

  update: (dt) =>
    @seq\update dt if @seq
    @colors.factor = math.sin(timer.getTime! * 3) * 25 + @base_factor

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

  transition_to: (state) =>
    @transition -> dispatch\push state

class Title extends FadeOutScreen
  new: (...) =>
    @title_image = imgfy "img/title.png"
    super ...

  onload: =>
    print "loading title..."
    sfx\play_music "xmoon-title"

  draw_inner: =>
    @title_image\draw 0,0
    cx, cy = @viewport\center!
    box_text "Press Enter To Begin", cx, cy - 10

  on_key: (key) =>
    if key == "return" or key == " "
      @transition_to Tutorial!

class Tutorial extends FadeOutScreen
  scale: 1.5
  base_factor: 300

  new: (...) =>
    @tut_image = imgfy "img/tutorial.png"
    super ...

  draw_inner: =>
    @tut_image\draw 0,0

  on_key: (key) =>
    if key == "return" or key == " "
      @transition_to Game!

class Intermission extends FadeOutScreen
  new: (@game, @fn, ...) =>
    super ...

  draw_inner: =>
    cx, cy = @viewport\center!
    box_text "You Beat Level #{@game.current_level}", cx, cy - 10
    box_text "Press Enter To Go To Next Level", cx, cy + 10

  on_key: (key) =>
    if key == "return" or key == " "
      @transition @fn

class GameOver extends FadeOutScreen
  new: (@player, @game, ...) =>
    super ...

  draw_inner: =>
    cx, cy = @viewport\center!
    box_text "Game Over", cx, cy - 10
    box_text "Score: #{@player.score} - Level: #{@game.current_level}", cx, cy + 10

    box_text "Press Enter To Return To Title", cx, cy + 30

  on_key: (key) =>
    if key == "return" or key == " "
      @transition ->
        dispatch\reset Title!

class Game
  levels: {
    Level1
    Level2
    Level3
    Endless
  }

  paused: false

  new: =>
    @player = Player 100, 100, @
    @current_level = 0
    @load_next_world!

  load_next_world: =>
    @current_level += 1
    w = @levels[@current_level]
    w = @levels[#@levels] unless w

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
    if @player.health <= 0
      dispatch\push GameOver @player, @
    else
      dispatch\push Intermission @, ->
        dispatch\pop!
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

  mousepressed: (x,y, btn) =>
    x, y = @world.viewport\unproject x,y
    if btn == "r" and keyboard.isDown "f2"
      @world.entities\add Energy x,y

    -- @world.particles\add EnergyEmitter @world, x,y
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
    "shoot1"
    "boom"
    "energy-collect"
  }

  dispatch = Dispatcher Title!
  dispatch\bind love

