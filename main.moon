
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
controls = require "controls"

export fonts = {}
export sprite, dispatch, sfx

-- world pixels are scaled by WORLD_SCALE, HUD text by HUD_SCALE
-- 800x450 desktop gets a 267x150 view, 640x480 handheld a 213x160 view
-- title and tutorial art is drawn for 800x450 at 3x, MENU_SCALE stretches it to fit other windows
export WORLD_SCALE, HUD_SCALE, MENU_SCALE

p = (str, ...) -> g.print str\lower!, ...

-- dim the screen and center the lines of text at HUD scale
draw_overlay = (lines) ->
  g.push!
  g.origin!
  g.scale HUD_SCALE
  w, h = g.getWidth! / HUD_SCALE, g.getHeight! / HUD_SCALE
  g.setColor 0,0,0, 0.6
  g.rectangle "fill", 0, 0, w, h

  line_h = 12
  y = h / 2 - (#lines * line_h) / 2 + line_h / 2
  for line in *lines
    box_text line, w / 2, y
    y += line_h
  g.setColor 1,1,1
  g.pop!

local snapper
local Game, Tutorial, Title

class FadeOutScreen
  base_factor: 75
  scale: => WORLD_SCALE

  new: =>
    @viewport = EffectViewport scale: @scale!
    @shroud_alpha = 0
    @colors = ColorSeparate!

  draw_inner: =>

  -- run fn with the HUD's integer scale so text stays crisp when the screen's
  -- own scale is fractional. fn gets the HUD size, and to_hud converts a point
  -- in this screen's viewport into HUD coordinates snapped to whole pixels
  draw_hud: (fn) =>
    g.push!
    g.translate @viewport.x, @viewport.y
    g.scale HUD_SCALE / @scale!
    to_hud = (x, y) ->
      f = @scale! / HUD_SCALE
      math.floor((x - @viewport.x) * f + 0.5), math.floor((y - @viewport.y) * f + 0.5)
    fn g.getWidth! / HUD_SCALE, g.getHeight! / HUD_SCALE, to_hud
    g.pop!

  update: (dt) =>
    @seq\update dt if @seq
    @colors.factor = math.sin(timer.getTime! * 3) * 25 + @base_factor

  draw: =>
    @colors\render ->
      @viewport\apply!
      @draw_inner!

      if @shroud_alpha > 0
        @viewport\draw {0,0,0, @shroud_alpha}

      g.setColor 1,1,1,1
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
  scale: => MENU_SCALE

  new: (...) =>
    @title_image = imgfy "img/title.png"
    super ...

  on_show: =>
    print "loading title..."
    sfx\play_music "xmoon-title"

  draw_inner: =>
    cx, cy = @viewport\center!
    @title_image\draw_center cx, cy

    @draw_hud (w, h, to_hud) ->
      box_text "Press #{controls.prompts.confirm!} To Begin", to_hud cx, cy - 10

      -- a joystick without a gamepad mapping needs the raw values to write one
      lines = controls.debug_lines!
      if #lines > 3 and lines[3]\match "false"
        for i, line in ipairs lines
          box_text line, 4, 6 + i * 10, false

  on_key: (key) =>
    if key == "return" or key == "space"
      @transition_to Tutorial!

class Tutorial extends FadeOutScreen
  base_factor: 300
  scale: => MENU_SCALE / 2

  new: (...) =>
    @tut_image = imgfy "img/tutorial.png"
    super ...

  draw_inner: =>
    cx, cy = @viewport\center!
    @tut_image\draw_center cx, cy

    if controls.has_pad!
      -- the image scale is too small for text, draw the hint at HUD scale
      @draw_hud (w, h) ->
        box_text "Left Stick: Move", w / 2, h - 46
        box_text "Right Stick: Aim and Shoot", w / 2, h - 34
        box_text "L1: Tractor Beam   X: Detonate", w / 2, h - 22
        box_text "Start: Pause   Select: Quit", w / 2, h - 10

  on_key: (key) =>
    if key == "return" or key == "space"
      @transition_to Game!

class Intermission extends FadeOutScreen
  new: (@game, @fn, ...) =>
    super ...

  draw_inner: =>
    cx, cy = @viewport\center!
    box_text "You Beat Level #{@game.current_level}", cx, cy - 10
    box_text "Press #{controls.prompts.confirm!} To Go To Next Level", cx, cy + 10

  on_key: (key) =>
    if key == "return" or key == "space"
      @transition @fn

class GameOver extends FadeOutScreen
  new: (@player, @game, ...) =>
    super ...

  draw_inner: =>
    cx, cy = @viewport\center!
    box_text "Game Over", cx, cy - 10
    box_text "Score: #{@player.score} - Level: #{@game.current_level}", cx, cy + 10

    box_text "Press #{controls.prompts.confirm!} To Return To Title", cx, cy + 30

  on_key: (key) =>
    if key == "return" or key == "space"
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
  show_fps: false

  new: =>
    @player = Player 100, 100, @
    @current_level = 0
    @load_next_world!

  load_next_world: =>
    @current_level += 1
    w = @levels[@current_level]
    w = @levels[#@levels] unless w

    @world = w @, @player

  on_show: =>
    sfx\play_music "xmoon"

  draw: =>
    @world\draw!
    if @show_fps
      g.scale HUD_SCALE
      p tostring(timer.getFPS!), 2, 50

    if @paused
      draw_overlay { "Paused", "Press #{controls.prompts.pause!} to resume" }

  update: (dt) =>
    return if dt > 0.5

    reloader\update! if reloader
    return if @paused

    if mouse.isDown(1) or controls.shooting!
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
        when "f3"
          @show_fps = not @show_fps
        when "f4"
          Projector.lit = not Projector.lit
    false

  mousepressed: (x,y, btn) =>
    x, y = @world.viewport\unproject x,y
    if btn == 2 and keyboard.isDown "f2"
      @world.entities\add Energy x,y

    -- @world.particles\add EnergyEmitter @world, x,y
    -- print "boom: #{x}, #{y}"
    -- @world.particles\add Explosion @world, x,y

load_font = (img, chars)->
  with g.newImageFont img, chars
    \setFilter "nearest", "nearest"

-- windowed at the native design size, fullscreen on displays too small for it
-- (the RG35XX is 640x480)
-- `love . --window 640x480` or XMOON_WINDOW=640x480 forces a windowed size for testing
open_window = (args={}) ->
  size = os.getenv "XMOON_WINDOW"
  for i, arg in ipairs args
    size = args[i + 1] if arg == "--window"

  if size
    w, h = size\match "^(%d+)x(%d+)$"
    error "bad --window size, expected WxH: #{size}" unless w
    love.window.setMode tonumber(w), tonumber(h)
    love.window.setTitle "X-Moon by leafo - Ludum Dare 25"
    return

  dw, dh = love.window.getDesktopDimensions!
  if dw < 800 or dh < 450
    love.window.setMode 0, 0, fullscreen: true, fullscreentype: "desktop"
    mouse.setVisible false
  else
    love.window.setMode 800, 450

  love.window.setTitle "X-Moon by leafo - Ludum Dare 25"

love.load = (args) ->
  open_window args
  g.setBackgroundColor 61/510, 52/510, 47/510

  WORLD_SCALE = 3
  HUD_SCALE = 3
  -- fill the window with the 267x150 title art, letterboxing the leftover axis
  MENU_SCALE = math.min g.getWidth! / 267, g.getHeight! / 150

  if love.filesystem.getInfo "gamecontrollerdb.txt"
    love.joystick.loadGamepadMappings "gamecontrollerdb.txt"

  controls.update_pad!
  sprite = Spriter "img/sprite.png", 16
  fonts.main = load_font "img/font.png",
    [[ abcdefghijklmnopqrstuvwxyz-1234567890!.,:;'"?$&]]

  g.setFont fonts.main

  export sfx = Audio "sounds"
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

  love.joystickadded = controls.update_pad
  love.joystickremoved = controls.update_pad

  -- there's no keyboard on the handheld, so holding select turns the face
  -- buttons into these while an overlay lists them
  menu_actions = {
    {"a", "Quit", -> love.event.push "quit"}
    {"x", "Toggle FPS", -> dispatch\keypressed "f3"}
    {"y", "Toggle Shaders", -> dispatch\keypressed "f1"}
    {"b", "Toggle Lighting", -> dispatch\keypressed "f4"}
  }

  love.gamepadpressed = (joy, btn) ->
    if controls.menu_open!
      for {menu_btn, _, fn} in *menu_actions
        fn! if menu_btn == btn
      return

    if key = controls.button_key btn
      dispatch\keypressed key

  dispatch_draw = love.draw
  love.draw = ->
    dispatch_draw!
    if controls.menu_open!
      draw_overlay ["#{btn\upper!}: #{label}" for {btn, label} in *menu_actions]

  dispatch_mousemoved = love.mousemoved
  love.mousemoved = (...) ->
    controls.mouse_moved!
    dispatch_mousemoved ...

