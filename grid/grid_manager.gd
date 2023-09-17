extends Control

var grid: Grid

var is_rainbow = false

# 右クリックを受けたらレインボー、ノーマルの切り替え。
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT && event.is_pressed():
			is_rainbow = !is_rainbow

# gridデータオブジェクトの生成。
func _ready():
	grid = Grid.new(get_rect(), Vector2(30.0, 30.0))

# gridの描画
func _draw():
	var f_draw_line = func(points: Array[PackedVector2Array], color: Array[PackedColorArray], width: float):
		for i in points.size():
			for j in points[i].size() - 1:
				var _color = color[i][j] if is_rainbow else Color.from_string("4df098", Color.WHEAT)
				draw_line(
					points[i][j],
					points[i][j + 1],
					_color,
					width
				)
	f_draw_line.call(grid.points_h, grid.points_h_color, 1.0)
	f_draw_line.call(grid.points_v, grid.points_v_color, 1.0)
	f_draw_line.call(grid.sub_points_h, grid.points_h_color, 1.0)
	f_draw_line.call(grid.sub_points_v, grid.points_v_color, 1.0)
	
# gridのアップデートと再描画
func _process(_delta):
	grid.update()
	queue_redraw()

	
# gridに力を加える関数を使いやすい場所においただけ。
func apply_explosive_force(force: float, pos: Vector3, radius: float) -> void:
	grid.physics_grid.apply_explosive_force(force, pos, radius)

# gridに力を加える関数を使いやすい場所においただけ。
func apply_directed_force(force: Vector3, pos: Vector3, radius: float) -> void:
	grid.physics_grid.apply_directed_force(force, pos, radius)

