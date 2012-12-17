
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
      wait math.random!

      dir = Vec2d.random!
      during 0.5, (dt) ->
        @move dt, dir

      -- if player is in range, shoiot
      player_pos = Vec2d @world.player.x, @world.player.y
      vec = player_pos - Vec2d @x, @y

      if vec\len! < 250 and math.random! > 0.5
        during 0.5, (dt) ->
          if @aim_to dt, player_pos
            "cancel"
        @shoot dt
      else
        during 1.0, (dt) ->
          @move dt, vec\normalized!

      wait math.random!
      again!

  take_hit: (thing, world) =>
    return if @health < 0

    if thing.is_bullet and not thing.hurts_player
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
  score: 78
  health: 40

  ox: 7
  oy: 6
  sprite: "17,34,14,12"

class Blue extends Enemy
  score: 128
  health: 60

  ox: 9
  oy: 7
  sprite: "17,49,15,14"

  loadout: =>
    @mount_gun TankGun, 0, -3
    @mount_gun TankGun, 0, 3


class Red extends Enemy
  score: 179
  health: 70

  ox: 5
  oy: 7
  sprite: "17,65,14,14"

  loadout: =>
    @mount_gun SpreadGun, 0, 0

class Orange extends Enemy
  score: 205
  health: 80

  ox: 8
  oy: 6
  sprite: "15,81,17,12"

  loadout: =>
    @mount_gun SpreadGun, 1, 1
    @mount_gun TankGun, -1, -1

gun_sprites = {
  green: "35,38,8,4"
  blue: "35,54,8,4"
  red: "35,70,8,4"
  orange: "35,85,8,4"
}

