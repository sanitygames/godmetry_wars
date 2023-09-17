extends Sprite2D

signal position_changed(pos: Vector2)
signal on_pressed(pos: Vector2)

var force := 10.0
var prev_position := Vector2.ZERO

func _input(event):
	# inputイベントがマウスの移動だったら、postionを変える。シグナルも出す。
	if event is InputEventMouseMotion:
		position = event.position
		position_changed.emit(position)

	# inputイベントがマウスクリックだったら、シグナルを出す。
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT && event.pressed:
			on_pressed.emit(position, force)
			force = 10.0

# マウスの動かし方で爆発の威力, spriteのスケールを変える
func _process(_delta):
	force = clamp(force * 0.95 + (prev_position - position).length() * 0.2, 30.0, 500.0)
	scale = Vector2.ONE * inverse_lerp(30.0, 500.0, force) * 3
	prev_position = position
