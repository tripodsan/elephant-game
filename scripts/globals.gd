extends Node

class_name Gobals

signal moves_changed(moves)

signal history_changed(size)

signal level_loaded(level_nr)

signal level_complete(moves)

signal play_level(num)

signal undo_move()

signal level_restart()

signal back_to_title()

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
