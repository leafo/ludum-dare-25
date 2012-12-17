
{graphics: g, :timer, :mouse} = love
{floor: f, min: _min, max: _max, :cos, :sin, :abs, :random} = math

import box_text from require "util"

export *

class TilePicker
  new: (inputs) =>
    sum = 0
    for tuple in *inputs
      sum += tuple[1]

    low = 0
    @table = for tuple in *inputs
      {k, v} = tuple
      with {low, v}
        low += k / sum

  pick_rand: =>
    local out
    r = random!
    for tuple in *@table
      {low, val} = tuple
      if r > low
        out = val
      else
        break

    out, r

class World
  disable_project: false
  energy_count: 0
  energy_needed: 100

  bg_tiles: { {1, 0} }

  new: (@game, @player) =>
    @viewport = EffectViewport scale: 3
    @player.world = @
    @player\reset!

    @collide = UniformGrid!

    @entities = DrawList!
    @particles = DrawList!

    @ground_project = Projector 1.2
    @entity_project = Projector 1.3

    @colors = ColorSeparate!

    picker = TilePicker @bg_tiles

    tile_sprite = Spriter "img/tiles.png", 16, 16, 16
    tiles = setmetatable { }, {
      __index: (i) =>
        with tile = { tid: picker\pick_rand! }
          @[i] = tile
    }

    @map = with TileMap 32, 32
      .sprite = tile_sprite
      \add_tiles tiles

    @map_box = Box 0,0, @map.real_width, @map.real_height
    @bomb_pad = BombPad 80, 80

    @background = TiledBackground "img/stars.png", @viewport

    @level_progress = with HorizBar 80, 6
      .color = { 128, 128 , 255, 128 }

    @health_bar = HorizBar 80, 6

    @prepare_enemies!

  prepare_enemies: =>
    return unless @enemy_types
    num = @num_spawns or 2

    bounds = @map\to_box!\shrink 120
    for i=1,num
      x,y = bounds\random_point!
      @particles\add EnemySpawner @,x,y, @enemy_types

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

    box_text "Energy: #{@energy_count or 0}", 10, 10, false

    score = f @player.display_score or @player.score or 0
    box_text "Score: #{score}", 10, 20, false

    @level_progress\draw w - 10 - @level_progress.w, 7
    @health_bar\draw (w - @health_bar.w)/2, h - @health_bar.h - 8

    if @energy_count >= @energy_needed and timer.getTime! % 1 >= 0.5
      box_text "Press E", w - 10, 20, 1.0

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

    if @start_fadeout
      elapsed = timer.getTime! - @start_fadeout
      a = _min(1.0, elapsed / 4) * 255
      Box(0,0, g.getWidth!, g.getHeight!)\draw {0,0,0,a}

      if elapsed > 4
        @game\end_world @

    g.setColor 255,255,255

  update: (dt) =>
    @viewport\update dt
    @map\update dt
    @player\update dt, @
    @entities\update dt, @
    @particles\update dt, @

    @bomb_pad\update dt, @
    @seq\update dt if @seq

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

    @level_progress.value = _min 1.0, @energy_count / @energy_needed
    @health_bar.value = _max 0, @player.health / @player.__class.health

  ready_to_blow: =>
    @energy_count >= @energy_needed

  blow_up_planet: =>
    @player\take_off ->
      @viewport\shake 15
      @player.hidden = true
      @seq = Sequence ->
        for i=1,100
          cx, cy = @viewport.x, @viewport.y

          @start_fadeout = timer.getTime! if i == 5

          for i=1,3
            x = cx + random! * @viewport.w
            y = cy + random! * @viewport.h
            @particles\add Explosion @, x, y

          wait 0.1

        @seq = nil

