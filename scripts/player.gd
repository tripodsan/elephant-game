extends Node2D

var dir:int = 0 setget set_dir

var pos:Vector2 = Vector2.ZERO setget set_pos

func _ready() -> void:
  self.pos = Vector2(0, 0)

func set_dir(v:int):
  dir = v
  for s in $sprite.get_children():
    s.visible = v == 0
    v -= 1

func set_pos(v:Vector2):
  pos = v
  transform.origin = Globals.grid2cart(pos)

func move(direction:int):
    self.dir = direction
    self.pos = pos + Globals.DIRS[dir]
    print('moved to %s facing %d' % [pos, dir])

func _process(delta: float) -> void:
  if Input.is_action_just_pressed('move_up'):
    move(0)
  if Input.is_action_just_pressed('move_right'):
    move(1)
  if Input.is_action_just_pressed('move_down'):
    move(2)
  if Input.is_action_just_pressed('move_left'):
    move(3)
