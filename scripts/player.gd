extends Node2D

class_name Player

var dir:int = 0 setget set_dir

var pos:Vector2 = Vector2.ZERO setget set_pos

onready var world := get_parent()

func set_dir(v:int):
  dir = v
  for s in $sprite.get_children():
    s.visible = v == 0
    v -= 1

func move_to(v:Vector2):
  pos = v

func set_pos(v:Vector2):
  pos = v
  transform.origin = world.grid2cart(v)


