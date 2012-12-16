
-- reloader = require "lovekit.reloader"
require "lovekit.all"

require "project"
require "particles"
require "guns"
require "tank"
require "enemies"
require "pickup"

require "lovekit.screen_snap"

import cos,sin,abs from math

{graphics: g, :timer, :mouse} = love
{floor: f} = math

p = (str, ...) -> g.print str\lower!, ...

export fonts = {}
export sprite, dispatch, sfx

local snapper
local Game

class World
  disable_project: false
  energy_count: 0

  new: (@player) =>
    @viewport = EffectViewport scale: 3
    @player.world = @
    @collide = UniformGrid!

    @entities = ReuseList!
    @particles = DrawList!

    @ground_project = Projector 1.2
    @entity_project = Projector 1.3

    @colors = ColorSeparate!

    tile_sprite = Spriter "img/tiles.png", 16
    tiles = setmetatable { {tid: 0} }, { __index: => @[1] }
    @map = with TileMap 32, 32
      .sprite = tile_sprite
      \add_tiles tiles

    @map_box = Box 0,0, @map.real_width, @map.real_height
    @bomb_pad = BombPad 80, 80

    -- create some enemies
    for xx = 1,2
      for yy = 1,2
        @entities\add Green, 150 + xx * 40, 150 + yy * 40

    @background = TiledBackground "img/stars.png", @viewport

    @explode = Animator sprite, {
      3,4,5,6,7,8,9,10,11
    }, 0.05
    @flare = (...) => sprite\draw "48,32,32,32", ...

  draw_background: =>
    g.push!
    g.scale @viewport.screen.scale
    @background\draw -@viewport.x, -@viewport.y
    g.pop!

  draw_ground: =>
    @viewport\apply!
    @map\draw @viewport
    @bomb_pad\draw!

    @viewport\pop!

  draw_entities: =>
    @viewport\apply!
    @player\draw dt
    @entities\draw!
    @particles\draw!
    g.setColor 255,255,255,255

    -- @explode\draw @player.x, @player.y
    -- @flare @player.x, @player.y

    @viewport\pop!

  draw: =>
    @viewport\center_on_pt @player.x, @player.y, @map_box

    @draw_background!

    if @disable_project
      @draw_ground!
      @draw_entities!
    else
      @colors\render ->
        @ground_project\render -> @draw_ground!
        @entity_project\render -> @draw_entities!

    g.setColor 0,0,0

    g.setColor 255,255,255

    g.scale 2
    p tostring(timer.getFPS!), 2, 2
    p "Energy: #{@energy_count}", 2, 12

  update: (dt) =>
    @viewport\update dt
    @map\update dt
    @player\update dt, @
    @entities\update dt, @
    @particles\update dt, @

    @bomb_pad\update dt, @

    @explode\update dt

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
      @player\take_hit thing, @

    for enemy in *@entities
      continue unless enemy.is_enemy
      for thing in *@collide\get_touching enemy.box
        enemy\take_hit thing, @


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

  dispatch = Dispatcher Title!
  dispatch\bind love

