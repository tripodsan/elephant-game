extends Node2D

var level0 = load('res://levels/level0.tscn')
var level1 = load('res://levels/level1.tscn')
var level2 = load('res://levels/level2.tscn')
var level3 = load('res://levels/level3.tscn')
var level5 = load('res://levels/level5.tscn')
var level6 = load('res://levels/level6.tscn')
var level8 = load('res://levels/level8.tscn')
var level99 = load('res://levels/level99.tscn')

var LEVELS = [
  level0,
  level1,
  level2,
  level3,
  null, # 4
  level5,
  level6,
  null, # 7
  level8,
  level99,
]

var current_level

onready var board = $board

func _ready() -> void:
  assert(!Globals.connect('level_complete', self, '_level_complete'))
  load_level(3)

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
  $canvas/levelComplete.grab_focus()


func _on_btnNext_pressed() -> void:
  while true:
    current_level = (current_level + 1) % LEVELS.size()
    if LEVELS[current_level]:
      break
  load_level(current_level)

func _on_btnUndo_pressed() -> void:
  Globals.emit_signal('undo_move')
