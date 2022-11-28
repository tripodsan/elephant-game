extends Node2D

## the current level tilemap
onready var level:TileMap = $room1

## the current level background
onready var background:TileMap = $background1

## the player node
onready var player:Player = $player

const TILE_WALL = 11
const TILE_FLOOR = 12
const TILE_PATH = 50

var boxes:Array = []

var targets = {}

## current selected box
var selected:Box

## direction of selected box
var selected_dir:int

## navigation class
var nav:AStar2D

## indicates that the play was already moving and the animation does not need
## an EASE_IN
var was_moving:bool = false

## flag indicating if the player moves along the naviation path
var fast_travel:bool = false

## the current move path
var move_path:Array = []

## the selected highlight_path
var highlight_path:Array = []

## the move history
## @type Array<Move>
var move_history:Array = []

## number of box moves
var moves:int = 0 setget set_moves

## tween used to animate boxes
var move_tween:Tween

## flag indicating if level is complete
var level_complete:bool

func _ready() -> void:
  generate_sprites()
  generate_nav()
  move_tween = Tween.new()
  assert(!move_tween.connect('tween_all_completed', self, '_move_completed'))
  assert(!Globals.connect('undo_move', self, '_undo_move'))
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
      add_child(s)
      s.generate_sprites(ts, id)
      s.transform.origin = grid2cart(pos)
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
func click(pos:Vector2):
  if level_complete:
    return
  if player_is_moving():
    return
  if selected:
    move_path.clear()
    fast_travel = false
    player_move(selected_dir)
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
    if !box_move(box, dir):
      Globals.emit_signal('history_changed', move_history.size())
      move_path.clear()
      return
    # box moved
    move_tween.interpolate_property(box, 'position', box.transform.origin,
      grid2cart(box.pos), 0.4, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)

  move_history.push_back(Move.new(dir, box))
  Globals.emit_signal('history_changed', move_history.size())
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
  # ensure hover is cleared
  hover(Vector2.ZERO, [])

func box_can_move(box:Box, dir:int)->bool:
  # check that all points of the box can move
  for p in box.positions:
    var newPos = p + Globals.DIRS[dir]
    if level.get_cellv(newPos) == TILE_WALL:
      return false
    if background.get_cellv(newPos) == -1:
      return false
    var other = get_box(newPos)
    if other && other != box:
      return false
  return true

func box_move(box:Box, dir:int)->bool:
  if !box_can_move(box, dir):
    return false

  # if box is on target, remove it
  if targets.has(box.pos):
    targets[box.pos].target_box = null

  # before move, remember positions
  var oldP = box.positions

  # move box
  box.pos += Globals.DIRS[dir]
  self.moves += 1

  # update nav accordingly. first enable all old positions
  for p in oldP:
    nav.set_point_disabled(nav.get_closest_point(p, true), false)
  # then disble new positions
  for p in box.positions:
    nav.set_point_disabled(nav.get_closest_point(p, true), true)

  # check if box was moved on target
  if targets.has(box.pos):
    var t:Box = targets[box.pos]
    if t.dim == box.dim:
      t.target_box = box

  # check if all targets covered
  for t in targets.values():
    if !t.target_box:
      return true

  print('level complete!')
  level_complete = true
  return true

func _undo_move()->void:
  if move_history.size() == 0 || level_complete || player_is_moving():
    return
  var last:Move = move_history.pop_back()
  Globals.emit_signal('history_changed', move_history.size())
  var dir = (last.dir + 2) % 4
  player.set_dir(last.dir)
  var pos = player.pos + Gobals.DIRS[dir]
  player.move_to(pos)
  # move box also back if needed
  if last.box:
    assert(box_move(last.box, dir), 'undo box move must always be possible')
    move_tween.interpolate_property(last.box, 'position', last.box.transform.origin,
      grid2cart(last.box.pos), 0.4, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)

  move_tween.interpolate_property(player, 'position',
    player.transform.origin, grid2cart(pos),
    0.4, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
  move_tween.start()
  was_moving = false

func _move_completed()->void:
  if level_complete:
    Globals.emit_signal('level_complete', moves)
  else:
    next_move()


## pixk the box that can be moved by the player
func pick_movable_box(boxes:Array):
  for box in boxes:
    var dir = -1
    for p in box.positions:
      dir = Globals.DIRS.find(p - player.pos)
      if dir >= 0 && box_can_move(box, dir):
        return { box=box, dir=dir }
  return null

## handles hover for the given tile coords and hovered box
## @param {Vector2} pos tile position the mouse hovers over
## @param {Array<Box} box the hovered box
func hover(pos:Vector2, boxes:Array)->void:
  # only allow hovering over boxes that might be moved
  var info = pick_movable_box(boxes)
  var box = info.box if info else null
  if box != selected:
    if selected:
      selected.modulate = Color.white
      selected.scale = Vector2(1, 1)
    selected = box
    selected_dir = info.dir if info else -1
  if selected:
    selected.modulate = Color(1.2, 1.2, 1.2)
    selected.scale = Vector2(1.01, 1.01)
    show_path([])
    return

  var id = background.get_cellv(pos)
  if id != TILE_FLOOR && id != TILE_PATH:
    show_path([])
    return
  if get_box(pos):
    show_path([])
    return

  if player.pos != pos:
    var p0 = nav.get_closest_point(player.pos)
    var p1 = nav.get_closest_point(pos)
    show_path(nav.get_point_path(p0, p1))
  else:
    show_path([])

func show_path(np:Array):
  var l0 = np.size();
  var l1 = highlight_path.size()
  if l0 == l1 && l0 > 1 && np[0] == highlight_path[0] && np[l0-1] == highlight_path[l1-1]:
    return
  for pos in highlight_path:
      background.set_cellv(pos, TILE_FLOOR)
  for pos in np:
      background.set_cellv(pos, TILE_PATH)
  highlight_path = np


func _unhandled_input(event:InputEvent)->void:
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
  if event.is_action_pressed('ui_undo'):
    _undo_move()
  if event is InputEventMouseButton:
    if event.pressed:
      var pos = get_local_mouse_position()
      var tile:Vector2 = level.world_to_map(pos)
      click(tile)
  if event is InputEventMouseMotion:
    if player_is_moving():
      return
    var mousePos = get_global_mouse_position()
    var space = get_world_2d().direct_space_state
    var boxes = []
    for info in space.intersect_point(mousePos, 8, [], -1, false, true):
      boxes.push_back(info.collider.get_parent())
    var pos = get_local_mouse_position()
    var tile:Vector2 = level.world_to_map(pos)
    hover(tile, boxes)

## converts the grid coordinates to world coordinates
func grid2cart(pos:Vector2)->Vector2:
  return level.map_to_world(pos) + Vector2(0, 112)

func get_box(pos:Vector2)->Box:
  for f in boxes:
    if f.covers(pos):
      return f
  return null

func set_moves(m:int):
  moves = m
  Globals.emit_signal('moves_changed', moves)

## The Boxes are anchored at the bottom most tile.
## so a 1x2 spans 0,0 and 0,1 where as a 2x1 spans 0,0 and -1,0
class Box extends YSort:
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
    elif name.ends_with('1x3'):
      dim = Vector2(1, 3)
    elif name.ends_with('3x1'):
      dim = Vector2(3, 1)
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

  ## generates the sprites from the ginve tileset tile. since some of the tiles have a texture wider
  ## than an isometric tile, the y-sort would produce errors when then player is in-fornt of a part
  ## of the texture that is behind. in order to fix this, the texture is split into several
  ## vertical strips, so that each sprite covers only 1 tile
  ##  2x1         1x2         2x2
  ##      ╳           ╳           ╳
  ##     ╱ ╲         ╱ ╲         ╱ ╲
  ##    ╳   ╳       ╳   ╳       ╳ ▒ ╳
  ##   ╱ ╲ ╱ ╲     ╱ ╲ ╱ ╲     ╱ ╲ ╱ ╲
  ##  ╳ █ ╳   ╳   ╳   ╳ ▒ ╳   ╳ █ ╳ ▓ ╳
  ##   ╲ ╱ ╲ ╱     ╲ ╱ ╲ ╱     ╲ ╱ ╲ ╱
  ##    ╳ ▒ ╳       ╳ █ ╳       ╳ ▒ ╳
  ##     ╲ ╱         ╲ ╱         ╲ ╱
  ##      ╳           ╳           ╳
  func generate_sprites(ts:TileSet, id:int)->void:
    var slices = []
    var r:Rect2 = ts.tile_get_region(id);
    var t:Texture = ts.tile_get_texture(id);
    var o:Vector2 = ts.tile_get_texture_offset(id) - Vector2(96, 112)
    # for 1x1 we only need 1 sprite
    if dim == Vector2(1,1):
      slices = [
        {dx=0,  dy= 0, tx= 0, w=r.size.x, h=r.size.y},
      ]
    elif dim == Vector2(2,1):
      slices = [
        {dx=0,  dy= 0, tx= 0, w=96, h=r.size.y - 56},
        {dx=96, dy=56, tx=96, w=r.size.x - 96, h=r.size.y},
      ]
    elif dim == Vector2(3,1):
      slices = [
        {dx=0,  dy= 0, tx= 0, w=96, h=r.size.y - 112},
        {dx=96,  dy=56, tx= 96, w=96, h=r.size.y - 56},
        {dx=192, dy=112, tx=192, w=r.size.x - 192, h=r.size.y},
      ]
    elif dim == Vector2(1,2):
      slices = [
        {dx=0,  dy= 0,  tx= 0, w=96, h=r.size.y},
        {dx=96, dy=-56, tx=96, w=r.size.x - 96, h=r.size.y},
      ]
    elif dim == Vector2(1,3):
      slices = [
        {dx=0,  dy= 0,  tx= 0, w=96, h=r.size.y},
        {dx=96, dy=-56, tx=96, w=96, h=r.size.y},
        {dx=192, dy=-112, tx=192, w=r.size.x - 192, h=r.size.y},
      ]
    elif dim == Vector2(2,2):
      slices = [
        {dx=0,  dy= 0, tx= 0,  w=96,  h=r.size.y - 56},
        {dx=96,  dy= 56, tx=96, w=96, h=r.size.y},
        {dx=192, dy=0, tx=192, w=r.size.x - 192, h=r.size.y},
      ]
    for p in slices:
      var s:Sprite = Sprite.new()
      s.texture = t;
      s.centered = false
      s.region_enabled = true
      s.region_rect = Rect2(r.position.x + p.tx, r.position.y, p.w, p.h)
      s.offset = o - Vector2(0, p.dy)
      s.z_index = ts.tile_get_z_index(id)
      s.transform.origin = Vector2(p.dx, p.dy)
      add_child(s)

    # create collision polygons from the sprite texture for non targets
    if is_target:
      return
    var area := Area2D.new()
    add_child(area)
    var img := Image.new()
    img.create(r.size.x, r.size.y, false, Image.FORMAT_RGBA8)
    img.blit_rect(t.get_data(), r, Vector2.ZERO)
    var bitmap = BitMap.new()
    bitmap.create_from_image_alpha(img)
    var polys = bitmap.opaque_to_polygons(Rect2(Vector2.ZERO, img.get_size()))
    for poly in polys:
      var p = CollisionPolygon2D.new()
      #p.color = Color.from_hsv(rand_range(0, 1), 1, 1)
      #p.z_index = 2
      p.polygon = poly
      p.position = o
      area.add_child(p)

class Move:
  ## direction of the move
  var dir:int
  ## moved box
  var box:Box

  func _init(dir:int, box:Box = null):
    self.dir = dir
    self.box = box
