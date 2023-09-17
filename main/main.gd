extends CanvasLayer

@onready var grid_manager = get_node("GridManager")


# プレイヤーが移動したときのシグナルを受信し、gridに力を加える
func _on_player_position_changed(pos: Vector2):
	grid_manager.apply_directed_force(
		Vector3(0, 0, 200),
		Vector3(pos.x, pos.y, 0),
		100.0
	)

# プレイヤーがクリックされたときのシグナルを受信し、gridに力を加える
func _on_player_on_pressed(pos: Vector2, force: float):
	grid_manager.apply_explosive_force(
		force,
		Vector3(pos.x, pos.y, 0),
		force * 2.0,
	)
