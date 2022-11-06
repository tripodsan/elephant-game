extends Node2D

onready var level:TileMap = $room

onready var player:Player = $player

const TILE_WALL = 1

var boxes:Array = []

var targets = {}

var moves:int = 0 setget set_moves

func _ready() -> void:
  print('tilemap rect ', level.get_used_rect())
  generate_sprites()
  self.moves = 0

func generate_sprites():
  var ts:TileSet = level.tile_set
  for pos in level.get_used_cells():
    var id = level.get_cellv(pos)
    var name = ts.tile_get_name(id)
    if name == 'start':
      level.set_cellv(pos, -1)
      player.set_pos(pos)
      continue

    if id != TILE_WALL && name != 'carpet':
      level.set_cellv(pos, -1)
      var s = Box.new(pos, name)
      s.texture = ts.tile_get_texture(id)
      s.centered = false
      s.region_enabled = true
      s.region_rect = ts.tile_get_region(id)
      s.offset = ts.tile_get_texture_offset(id) - Vector2(32, 0)
      s.transform.origin = level.map_to_world(pos)
      s.z_index = ts.tile_get_z_index(id)
      level.add_child(s)
      if s.is_target:
        targets[s.pos] = s
      else:
        boxes.push_back(s)

func player_move(dir:int):
  player.set_dir(dir)
  var newPos = player.pos + Gobals.DIRS[dir]
  var t = level.get_cellv(newPos)
  if t == TILE_WALL:
    return
  # check if box is in the way
  var f = get_box(newPos)
  if f && !box_move(f, dir):
    return
  if f:
    # box moved
    print('moved box to %s', f)
    f.transform.origin = level.map_to_world(f.pos)

  player.pos = newPos
  print('moved to %s facing %d. tile is %d' % [player.pos, dir, level.get_cellv(player.pos)])

func box_move(f:Box, dir:int)->bool:
  # check that all points of the box can move
  for p in f.positions:
    var newPos = p + Globals.DIRS[dir]
    var t = level.get_cellv(newPos)
    if t == TILE_WALL:
      return false
    var other = get_box(newPos)
    if other && other != f:
      return false

  # if box is on target, remove it
  if targets.has(f.pos):
    targets[f.pos].target_box = null

  # move box
  f.pos += Globals.DIRS[dir]
  self.moves += 1

  # check if box was moved on target
  if targets.has(f.pos):
    var t:Box = targets[f.pos]
    if t.dim == f.dim:
      t.target_box = f

  # check if all targets covered
  for t in targets.values():
    if !t.target_box:
      return true

  print('level complete!')
  Globals.emit_signal('level_complete', moves)
  return true

func _input(event:InputEvent)->void:
  if event.is_action_pressed('move_up'):
    player_move(0)
  if event.is_action_pressed('move_right'):
    player_move(1)
  if event.is_action_pressed('move_down'):
    player_move(2)
  if event.is_action_pressed('move_left'):
    player_move(3)

## converts the grid coordinates to world coordinates
func grid2cart(pos:Vector2)->Vector2:
  return level.map_to_world(pos)

func get_box(pos:Vector2)->Box:
  for f in boxes:
    if f.covers(pos):
      return f
  return null

func set_moves(m:int):
  moves = m
  Globals.emit_signal('moves_changed', moves)

class Box extends Sprite:
  ## position in tilemap
  var pos:Vector2 setget set_pos

  ## the positions this box covers
  var positions = []

  ## dimensions
  var dim:Vector2 = Vector2(1, 1)

  ## indicated target
  var is_target:bool

  ## valid box covering the target
  var target_box:Box

  func _init(p:Vector2, name:String):
    self.name = name
    # todo: improve
    if name.ends_with('1x2'):
      dim = Vector2(1, 2)
    elif name.ends_with('2x1'):
      dim = Vector2(2, 1)
    elif name.ends_with('2x2'):
      dim = Vector2(2, 2)
    is_target = name.begins_with('target')
    self.pos = p

  func covers(p:Vector2)->bool:
    return positions.find(p) != -1

  func set_pos(p:Vector2):
    pos = p
    positions.clear()
    for x in range(0, dim.x):
      for y in range(0, dim.y):
        positions.push_back(pos + Vector2(x, -y))

  func _to_string() -> String:
    return '%s %s' % [name, pos]
