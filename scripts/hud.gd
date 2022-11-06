extends Control

onready var labMoves:Label = $hud/GridContainer/HBoxContainer/labMoves
onready var labLevel:Label = $hud/GridContainer/labLevel

func _ready() -> void:
  assert(!Globals.connect('moves_changed', self, '_update_moves'))
  assert(!Globals.connect('level_loaded', self, '_level_loaded'))

func _update_moves(moves:int):
  labMoves.text = 'Moves: %d' % moves

func _level_loaded(level:int):
  labLevel.text = 'Level %d' % (level + 1)

