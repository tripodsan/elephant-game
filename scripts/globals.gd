extends Node

class_name Gobals

signal moves_changed(moves)

signal level_loaded(level_nr)

signal level_complete(moves)

const GRID_DX := 64
const GRID_DX2 := 32
const GRID_DY := 32
const GRID_DY2 := 16
const GRID_OX := 384
const GRID_OY := 240

const DIRS = [
  Vector2(0, -1),  # up
  Vector2(1, 0),  # right
  Vector2(0, 1), # down
  Vector2(-1, 0) # left
]
