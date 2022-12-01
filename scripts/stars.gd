extends HBoxContainer

onready var stars = [
  $placeholder/star,
  $placeholder2/star,
  $placeholder3/star,
 ]
onready var tween:Tween = $Tween

var numStars:int = 0

func set_stars(num:int, animate:bool = false):
  for i in range(0, 3):
    var star:Sprite = stars[i]
    star.visible = i < num
    star.scale = Vector2.ONE
    if animate && star.visible:
      star.scale = Vector2.ZERO
      tween.interpolate_property(star, "scale",
        Vector2.ZERO, Vector2.ONE, 0.8,
        Tween.TRANS_BOUNCE, Tween.EASE_OUT, i/3.0 + 0.5)
  if animate:
    tween.start()
