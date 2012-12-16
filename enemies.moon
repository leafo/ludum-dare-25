
export *

class Enemy extends Tank
  is_enemy: true
  color: {255, 200, 200}
  spin: 4
  speed: 20
  health: 40

  score: 78

  new: (...) =>
    super ...
    @health = @@health
    @ai = Sequence ->
      dir = Vec2d.random!
      during 0.5, (dt) ->
        @move dt, dir

      pt = Vec2d.random! * 50 + Vec2d @x, @y
      during 0.5, (dt) ->
        if @aim_to dt, pt
          "cancel"

      @shoot dt
      wait 1.0

      again!

  take_hit: (thing, world) =>
    return if @health < 0

    if thing.is_bullet
      damage = thing\on_hit thing, world

      thing.alive = false
      @shove thing, 5, 0.2

      cx, cy = @box\center!
      bdir = thing.vel\normalized!
      bx, by = unpack bdir * 2 + Vec2d thing\center!

      @health -= damage

      with world.particles
        \add NumberParticle cx,cy, math.floor damage + 0.5
        \add SparkEmitter @world, bx, by, bdir

        if @health <= 0
          \add Explosion @world, cx, cy
          world.player\enemy_killed @, world


  update: (dt, world) =>
    @world = world
    @ai\update dt
    super dt
    @health > 0

  __tostring: => "Enemy<#{@box}>"

class Green extends Enemy
  ox: 7
  oy: 6
  sprite: "17,34,14,12"

class Blue extends Enemy
  ox: 9
  oy: 7
  sprite: "17,49,15,14"

class Red extends Enemy
  ox: 5
  oy: 7
  spite: "17,65,14,14"

class Orange extends Enemy
  ox: 8
  oy: 6
  spite: "15,81,17,12"

gun_sprites = {
  green: "35,38,8,4"
  blue: "35,54,8,4"
  red: "35,70,8,4"
  orange: "35,85,8,4"
}



