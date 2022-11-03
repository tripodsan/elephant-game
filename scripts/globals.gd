extends Node

class_name Gobals


const GRID_DX := 64
const GRID_DX2 := 32
const GRID_DY := 32
const GRID_DY2 := 16
const GRID_OX := 384
const GRID_OY := 240

const DIRS = [
  Vector2(0, 1),  # up
  Vector2(1, 0),  # right
  Vector2(0, -1), # down
  Vector2(-1, 0) # left
]
## converts the grid coordinates to world coordinates
func grid2cart(pos:Vector2)->Vector2:
  return Vector2(
    GRID_OX + pos.x * GRID_DX2 + pos.y * GRID_DX2,
    GRID_OY + pos.x * GRID_DY2 - pos.y * GRID_DY2
  )
