
{graphics: g} = love
{:sqrt, :max, :min} = math

export *

class Energy extends Box
  is_energy: true
  size: 4

  sprite: "96,16,16,16"
  ox: 8
  oy: 8

  new: (x, y) =>
    @vel = Vec2d 0,0
    @accel = Vec2d 0,0
    @rot = 0

    super x,y, @size, @size

  on_collect: (world) =>
    sfx\play "energy-collect"
    world.particles\add EnergyEmitter world, @center!
    world.energy_count += 1
    @alive = false

  update: (dt) =>
    if @gravity_parent
      {:x,:y} = @gravity_parent
      to_thing = Vec2d(x, y) - Vec2d @center!
      p = to_thing\len! / @gravity_parent.suck_radius
      @accel = to_thing\normalized! * (p - 0.2) * 200

      if p < 1
        dampen_vector @vel, dt * max(@vel\len!, 1.0) * 2, 120
    else
      @accel[1] = 0
      @accel[2] = 0
      unless @vel\is_zero!
        dampen_vector @vel, dt * max(@vel\len!, 1.0) * 5

    @vel\adjust unpack @accel * dt
    @rot += @vel\len! / 1000
    @x += @vel.x * dt
    @y += @vel.y * dt
    true

  draw: =>
    half = @size/2
    sprite\draw @sprite, @x + half, @y + half, @rot, nil, nil, @ox, @oy
    -- g.setColor 255,100,100 if @gravity_parent
    -- g.rectangle "line", @unpack!
    -- g.setColor 255,255,255

  __tostring: => "Energy<>"


class BombPad extends Box
  w: 48
  h: 32

  seq: {
    "160,96,48,32",
    "160,128,48,32",
  }

  new: (@x, @y) =>
    @anim = sprite\seq @seq, 0.5

  draw: => @anim\draw @x, @y

  update: (dt, world) =>
    @anim\update dt
    if world.viewport\touches_box @
      for e in *world.collide\get_touching @
        if e.is_energy and e.alive
          e\on_collect world

