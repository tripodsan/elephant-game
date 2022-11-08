extends Node2D

class_name Player

var dir:int = 0 setget set_dir

var pos:Vector2 = Vector2.ZERO setget set_pos

onready var world := get_parent()

onready var move_tween:Tween = $movement

func set_dir(v:int):
  dir = v
  for s in $sprite.get_children():
    s.visible = v == 0
    v -= 1

func is_moving()->bool:
  return move_tween.is_active()

func move_to(v:Vector2):
  pos = v
  move_tween.interpolate_property(self, 'position',
  transform.origin, world.grid2cart(pos), 0.4,
  Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
  move_tween.start()

func set_pos(v:Vector2):
  pos = v
  transform.origin = world.grid2cart(v)


