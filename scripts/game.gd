extends Node2D

onready var screenTitle = $canvas/title
onready var screenGame = $canvas/game_screen
onready var screenCredits = $canvas/credits
onready var screenLevelCompete = $canvas/levelComplete
onready var screenSettings = $canvas/settings
onready var screenLevelSelect = $canvas/level_select
onready var screenLevels = $canvas/level_select/MarginContainer/CenterContainer/rows/levels

onready var soundTrack = $soundTrack
onready var soundTrackAnim:AnimationPlayer = $soundTrack/anim

onready var labMoves = $canvas/levelComplete/CenterContainer/VBoxContainer/labMoves
onready var ctlStars = $canvas/levelComplete/CenterContainer/VBoxContainer/CenterContainer/stars

var level0 = load('res://levels/level0.tscn')
var level1 = load('res://levels/level1.tscn')
var level2 = load('res://levels/level2.tscn')
var level3 = load('res://levels/level3.tscn')
var level4 = load('res://levels/level4.tscn')
var level5 = load('res://levels/level5.tscn')
var level6 = load('res://levels/level6.tscn')
var level7 = load('res://levels/level7.tscn')
var level8 = load('res://levels/level8.tscn')
var level9 = load('res://levels/level9.tscn')
var level10 = load('res://levels/level10.tscn')
var level99 = load('res://levels/level99.tscn')

var LEVELS = [
  level0,
  level1,
  level2,
  level3,
  level4,
  level5,
  level6,
  level7,
  level8,
  level9,
  level10,
#  level99,
]

var current_level
var current_level_par:int
var current_screen

var game_data = {
  'version': 1,
  'levels': {},
}

onready var board = $board

func _ready() -> void:
  assert(!Globals.connect('level_complete', self, '_level_complete'))
  assert(!Globals.connect('level_restart', self, '_on_btnRestart_pressed'))
  assert(!Globals.connect('back_to_title', self, '_on_btnMenu_pressed'))
  assert(!Globals.connect('play_level', self, 'on_play_level'))
  load_game()
  show_screen(screenTitle)

func load_level(lvl:int):
  current_level = lvl
  for c in board.get_children():
    board.remove_child(c)
    c.queue_free()
  var scn = LEVELS[lvl].instance()
  board.add_child(scn)
  current_level_par = scn.par
  screenLevelCompete.visible = false
  Globals.emit_signal('level_loaded', lvl)

func _on_btnRestart_pressed() -> void:
  load_level(current_level)

func _level_complete(moves:int):
  screenLevelCompete.visible = true
  screenLevelCompete.grab_focus()
  labMoves.text = "%d Moves" % moves
  var numStars = 1
  if moves <= current_level_par * 2.0:
    numStars += 1
  if moves <= current_level_par:
    numStars += 1
  print('moves ', moves, ' par ', current_level_par, ' stars ', numStars)
  ctlStars.set_stars(numStars, true)
  soundTrackAnim.play('mute')
  var lab = 'level%d' % current_level
  if !game_data.levels.has(lab):
    game_data.levels[lab] = {
      'moves': moves,
      'stars': numStars,
    }
  else:
    var info = game_data.levels[lab]
    info.moves = min(moves, info.moves)
    info.stars = max(numStars, info.stars)
  save_game()


func _on_btnNext_pressed() -> void:
  while true:
    current_level = (current_level + 1) % LEVELS.size()
    if LEVELS[current_level]:
      break
  soundTrackAnim.play_backwards('mute')
  load_level(current_level)

func _on_btnUndo_pressed() -> void:
  Globals.emit_signal('undo_move')

func show_screen(scn:Control)->void:
  if scn != current_screen:
    if current_screen:
      current_screen.hide()
    current_screen = scn
  scn.show()
  if scn.focus_mode:
    scn.grab_focus()

func _on_btnQuit_pressed() -> void:
  get_tree().quit()

func _on_btnCredits_pressed() -> void:
  show_screen(screenCredits)

func _on_btnSettings_pressed() -> void:
  show_screen(screenSettings)

func _on_btnPlay_pressed() -> void:
  if !game_data.levels.has('level0'):
    on_play_level(0)
    return
  show_screen(screenLevelSelect)
  var i = 0
  var wasPlayed = true
  for lev in screenLevels.get_children():
    lev.set_level(i)
    lev.set_enabled(wasPlayed)
    wasPlayed = false
    var lab = 'level%d' % i
    if game_data.levels.has(lab):
      var info = game_data.levels[lab]
      wasPlayed = true
      lev.set_num_stars(info.stars)
    else:
      lev.set_num_stars(0)
    i += 1

func on_play_level(num)->void:
  load_level(num)
  soundTrackAnim.play('RESET')
  soundTrack.play()
  show_screen(screenGame)

func _on_btnBack_pressed() -> void:
  show_screen(screenTitle)

func _on_btnMenu_pressed() -> void:
  soundTrack.stop()
  show_screen(screenTitle)

# warning-ignore:unused_argument
func _process(delta)->void:
  if Input.is_action_just_pressed('ui_print'):
    var image = get_viewport().get_texture().get_data()
    image.flip_y()
    var path = '%s/screenshot-%d.png' % [OS.get_user_data_dir(), OS.get_system_time_secs()];
    image.save_png(path)
    print('screenshot saved to ', path)

func load_game()->void:
  var file = File.new()
  if !file.open('user://save_game.json', file.READ):
    var text = file.get_as_text()
    file.close()
    game_data = parse_json(text)
    print('loaded game data', game_data)

func save_game()->void:
  var file = File.new()
  var err = file.open('user://save_game.json', file.WRITE)
  if err:
    print('error opening file ', err)
  else:
    file.store_line(to_json(game_data))
    file.close()
