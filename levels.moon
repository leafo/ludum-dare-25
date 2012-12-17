
export *

width = 16
tid = (row, col) -> row * width + col

class Level1 extends World
  energy_needed: 10

  enemy_types: { Green }
  num_spawns: 3

  bg_tiles: {
    { 100,  tid 0, 1 }
    { 20,   tid 1, 1 }
    { 5,    tid 2, 1 }
    { 5,    tid 3, 1 }
    { 1,    tid 4, 1 }
    { 50,   tid 5, 1 }
  }

class Level2 extends World
  energy_needed: 20

  enemy_types: { Green, Blue }
  num_spawns: 4

  bg_tiles: {
    { 100,  tid 0, 0 }
    { 20,   tid 1, 0 }
    { 3,    tid 2, 0 }
  }

class Level3 extends World
  energy_needed: 30

  enemy_types: { Green, Blue, Red }
  num_spawns: 5

  bg_tiles: {
    { 100,  tid 0, 2 }
    { 20,   tid 1, 2 }
    { 3,    tid 2, 2 }
  }

class Endless extends World
  energy_needed: 40
  enemy_types: { Green, Blue, Red, Orange }
  num_spawns: 7

  new: (...) =>
    levels = { Level1, Level2, Level3 }
    @bg_tiles = levels[math.random #levels].bg_tiles
    super ...


