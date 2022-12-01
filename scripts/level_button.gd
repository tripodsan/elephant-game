extends VBoxContainer

var level:= 0

func set_level(num):
  level = num
  $btnLevel.text = '  %d  ' % (num + 1)

func set_enabled(value:bool):
  $btnLevel.disabled = !value

func set_num_stars(num):
  $stars.set_stars(num)

func _on_btnLevel_pressed() -> void:
  Globals.emit_signal('play_level', level)
