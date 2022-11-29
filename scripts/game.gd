extends Node2D

onready var screenTitle = $canvas/title
onready var screenGame = $canvas/game_screen
onready var screenCredits = $canvas/credits
onready var screenLevelCompete = $canvas/levelComplete
onready var screenSettings = $canvas/settings

onready var soundTrack = $soundTrack
onready var soundTrackAnim = $soundTrack/anim

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
var current_screen

onready var board = $board

func _ready() -> void:
  assert(!Globals.connect('level_complete', self, '_level_complete'))
  assert(!Globals.connect('level_restart', self, '_on_btnRestart_pressed'))
  show_screen(screenTitle)

func load_level(lvl:int):
  current_level = lvl
  for c in board.get_children():
    board.remove_child(c)
    c.queue_free()
  var scn = LEVELS[lvl].instance()
  board.add_child(scn)
  screenLevelCompete.visible = false
  soundTrackAnim.play('RESET')
  soundTrack.play()
  Globals.emit_signal('level_loaded', lvl)

func _on_btnRestart_pressed() -> void:
  load_level(current_level)

func _level_complete(moves:int):
  screenLevelCompete.visible = true
  screenLevelCompete.grab_focus()
  soundTrackAnim.play('mute')

func _on_btnNext_pressed() -> void:
  while true:
    current_level = (current_level + 1) % LEVELS.size()
    if LEVELS[current_level]:
      break
  load_level(current_level)

func _on_btnUndo_pressed() -> void:
  Globals.emit_signal('undo_move')

func show_screen(scn)->void:
  if scn != current_screen:
    if current_screen:
      current_screen.hide()
    current_screen = scn
  scn.show()
  scn.grab_focus()

func _on_btnQuit_pressed() -> void:
  get_tree().quit()


func _on_btnCredits_pressed() -> void:
  show_screen(screenCredits)

func _on_btnSettings_pressed() -> void:
  show_screen(screenSettings)

func _on_btnPlay_pressed() -> void:
  load_level(0)
  show_screen(screenGame)

func _on_btnBack_pressed() -> void:
  show_screen(screenTitle)

func _on_btnMenu_pressed() -> void:
  soundTrack.stop()
  show_screen(screenTitle)
