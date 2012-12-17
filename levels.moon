
export *

width = 32
tid = (row, col) -> row * width + col

class Level1 extends World
  energy_needed: 20

  bg_tiles: {
    { 100, tid 0, 1 }
    { 20,   tid 1, 1 }
    { 5,   tid 2, 1 }
    { 5,   tid 3, 1 }
    { 1,   tid 4, 1 }
    { 50,  tid 5, 1 }
  }

class Level2 extends World
  energy_needed: 40

