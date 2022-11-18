extends Node2D

## the current level tilemap
onready var level:TileMap = $room1

## the current level background
onready var background:TileMap = $background1

## the player node
onready var player:Player = $player

const TILE_WALL = 11

var boxes:Array = []

var targets = {}

## navigation class
var nav:AStar2D

## indicates that the play was already moving and the animation does not need
## an EASE_IN
var was_moving:bool = false

## flag indicating if the player moves along the naviation path
var fast_travel:bool = false

## the current move path
var move_path:Array = []

## number of box moves
var moves:int = 0 setget set_moves

## tween used to animate boxes
var move_tween:Tween

## flag indicating if level is complete
var level_complete:bool

func _ready() -> void:
  print('tilemap rect ', level.get_used_rect())
  generate_sprites()
  generate_nav()
  move_tween = Tween.new()
  assert(!move_tween.connect('tween_all_completed', self, '_move_completed'))
  add_child(move_tween)
  self.moves = 0

## iterates over the tilemap and creates sprites from the tiles that are boxes
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
      s.offset = ts.tile_get_texture_offset(id) - Vector2(96, 0)
      s.transform.origin = level.map_to_world(pos)
      s.z_index = ts.tile_get_z_index(id)
      level.add_child(s)
      if s.is_target:
        targets[s.pos] = s
      else:
        boxes.push_back(s)

## generates the navigation AStart2D instnce
func generate_nav():
  self.nav = AStar2D.new()
  # create the nav map with all the background cells that are not covered by a wall
  var points = {}
  for pos in background.get_used_cells():
    var id = level.get_cellv(pos)
    if id != TILE_WALL:
      var pId = nav.get_available_point_id()
      points[pos] = pId
      nav.add_point(pId, pos)
      # disable if covered by a box
      if get_box(pos):
        nav.set_point_disabled(pId, true)
  # now connect them
  for pos in points:
    var p0Id = points[pos]
    for dir in Gobals.DIRS:
      var nPos = pos + dir
      if points.has(nPos):
        var p1Id = points[nPos]
        nav.connect_points(p0Id, p1Id, false)

## checks if there is a next move in the moves_path and makes the player move
func next_move():
  if move_path.size() == 0:
    was_moving = false
    return
  var next = move_path.pop_front()
  var dir = Globals.DIRS.find(next - player.pos)
  assert(dir >= 0, 'move path must have valid direction')
  player_move(dir)

## checks if the player is currently moving (animating)
func player_is_moving()->bool:
  return move_tween.is_active()

## create move path for player to the desired location.
func player_movev(pos:Vector2):
  if level_complete:
    return
  if player_is_moving():
    return
  var dir = Globals.DIRS.find(pos - player.pos)
  if dir >= 0:
    # move by 1
    move_path.clear()
    fast_travel = false
    player_move(dir)
    return
  var p0 = nav.get_closest_point(player.pos)
  var p1 = nav.get_closest_point(pos)
  move_path = nav.get_point_path(p0, p1)
  move_path.pop_front()
  fast_travel = true
  next_move()

func player_move(dir:int):
  if level_complete:
    return
  if player_is_moving():
    # next_move = dir
    return
  player.set_dir(dir)
  var newPos = player.pos + Gobals.DIRS[dir]
  # check if background is not empty
  if background.get_cellv(newPos) == -1:
    move_path.clear()
    return
  # get level cell
  var t = level.get_cellv(newPos)
  if t == TILE_WALL:
    move_path.clear()
    return
  # check if box is in the way
  var box = get_box(newPos)
  if box:
    var oldP = box.positions
    if !box_move(box, dir):
      move_path.clear()
      return
    #print('moved box to %s', f)
    # box moved
    # update nav accordingly. first enable all old positions
    for p in oldP:
      nav.set_point_disabled(nav.get_closest_point(p, true), false)
    # then disble new positions
    for p in box.positions:
      nav.set_point_disabled(nav.get_closest_point(p, true), true)

    move_tween.interpolate_property(box, 'position', box.transform.origin,
      level.map_to_world(box.pos), 0.4, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)

  var ease_type = 0
  if move_path.size() == 0:
    # if move is finished, ease out
    ease_type += Tween.EASE_OUT
  if !was_moving:
    # if move starts, ease it
    ease_type += Tween.EASE_IN
  player.move_to(newPos)

  move_tween.interpolate_property(player, 'position',
    player.transform.origin, grid2cart(newPos),
    0.2 if fast_travel else 0.4,
    Tween.TRANS_LINEAR, ease_type)

  move_tween.start()
  was_moving = move_path.size() > 0
  #print('moved to %s facing %d. tile is %d' % [player.pos, dir, level.get_cellv(player.pos)])

func box_move(f:Box, dir:int)->bool:
  # check that all points of the box can move
  for p in f.positions:
    var newPos = p + Globals.DIRS[dir]
    if level.get_cellv(newPos) == TILE_WALL:
      return false
    if background.get_cellv(newPos) == -1:
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
  level_complete = true
  return true

func _move_completed()->void:
  if level_complete:
    Globals.emit_signal('level_complete', moves)
  else:
    next_move()

func _input(event:InputEvent)->void:
  if event.is_action_pressed('move_up'):
    fast_travel = false
    player_move(0)
  if event.is_action_pressed('move_right'):
    fast_travel = false
    player_move(1)
  if event.is_action_pressed('move_down'):
    fast_travel = false
    player_move(2)
  if event.is_action_pressed('move_left'):
    fast_travel = false
    player_move(3)
  if event is InputEventMouseButton:
    if event.pressed:
      var pos = get_local_mouse_position()
      var tile:Vector2 = level.world_to_map(pos)
      player_movev(tile)


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
    positions = [];
    for x in range(0, dim.x):
      for y in range(0, dim.y):
        positions.push_back(pos + Vector2(x, -y))

  func _to_string() -> String:
    return '%s %s' % [name, pos]
