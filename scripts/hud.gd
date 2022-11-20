extends Control

onready var labMoves:Label = $hud/GridContainer/HBoxContainer/labMoves
onready var labLevel:Label = $hud/GridContainer/labLevel
onready var btnUndo:TextureButton = $hud/GridContainer/HBoxContainer/btnUndo

func _ready() -> void:
  assert(!Globals.connect('moves_changed', self, '_update_moves'))
  assert(!Globals.connect('level_loaded', self, '_level_loaded'))
  assert(!Globals.connect('history_changed', self, '_history_changed'))

func _update_moves(moves:int):
  labMoves.text = 'Moves: %d' % moves

func _level_loaded(level:int):
  labLevel.text = 'Level %d' % (level + 1)
  btnUndo.disabled = true

func _history_changed(size:int):
  btnUndo.disabled = size == 0

