extends Node2D

var level0 = load('res://levels/level0.tscn')
var level1 = load('res://levels/level1.tscn')

var LEVELS = [
  level0,
  level1,
]

var current_level = 0

onready var board = $board

func _ready() -> void:
  assert(!Globals.connect('level_complete', self, '_level_complete'))
  load_level(0)

func load_level(lvl:int):
  current_level = lvl
  for c in board.get_children():
    board.remove_child(c)
    c.queue_free()
  var scn = LEVELS[lvl].instance()
  board.add_child(scn)
  $canvas/levelComplete.visible = false
  Globals.emit_signal('level_loaded', lvl)

func _on_btnRestart_pressed() -> void:
  load_level(current_level)

func _level_complete(moves:int):
  $canvas/levelComplete.visible = true
