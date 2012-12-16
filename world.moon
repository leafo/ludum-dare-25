
{graphics: g, :timer, :mouse} = love
{floor: f, min: _min, :cos, :sin, :abs} = math

import box_text from require "util"

export *

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

    @level_progress = HorizBar 80, 10

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

  draw_hud: =>
    w, h = g.getWidth!, g.getHeight!
    r = w/h

    g.push!
    g.scale w/2, h/2
    g.translate 1, 1
    g.scale 0.9, 1.2

    for e in *@entities
      continue unless e.alive

      cx, cy, rr,gg,bb = if e.is_enemy
        e.x, e.y, 255,100,100
      elseif e.is_energy
        ex,ey = e\center!
        ex, ey, 140,140,255, 180
      else
        continue

      to_thing = Vec2d(cx - @player.x, cy - @player.y)
      aa = _min(0.8, to_thing\len! / 100) * 255

      vec = to_thing\normalized!

      vec[2] = 0.8 if vec[2] > 0.8
      vec[2] = -0.8 if vec[2] < -0.8

      g.setColor rr,gg,bb, aa
      g.point unpack vec

    g.setColor 255,255,255,255
    g.pop!

    g.push!
    g.scale @viewport.screen.scale

    w = w/3
    h = h/3

    box_text "Energy: #{@player.energy_count or 0}", 10, 10, false
    box_text "Score: #{@player.score or 0}", 10, 20, false

    @level_progress\draw w - 10 - @level_progress.w, 7
    g.pop!


  draw: =>
    @viewport\center_on_pt @player.x, @player.y, @map_box

    @draw_background!

    if @disable_project
      @draw_ground!
      @draw_entities!
      @draw_hud!
    else
      @colors.factor = 50
      @colors\render ->
        @ground_project\render -> @draw_ground!
        @entity_project\render -> @draw_entities!

      @colors.factor = 200
      @colors\render ->
        @draw_hud!


    g.setColor 255,255,255

    g.scale 2
    -- p tostring(timer.getFPS!), 2, 2
    -- p "Energy: #{@energy_count}", 2, 12

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

