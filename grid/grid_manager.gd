extends Control

@export_range(0.1, 4.0) var resolution = 1.0

var grid: Grid
var is_rainbow = false

# 右クリックを受けたらレインボー、ノーマルの切り替え。
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT && event.is_pressed():
			is_rainbow = !is_rainbow

# gridデータオブジェクトの生成。
func _ready():
	var rect = get_rect()
	var spacing = Vector2(60, 60) / resolution
	rect.position.x = fmod(rect.size.x, spacing.x) * 0.5
	rect.position.y = fmod(rect.size.y, spacing.y) * 0.5
	grid = Grid.new(rect, spacing)
	get_parent().get_node("DebugWindow").point_size = grid.point_size  


func _draw():
	if is_rainbow:
		for i in grid.points_h.size():
			draw_multiline_colors(grid.points_h[i], grid.points_h_color[i])
		for i in grid.points_v.size():
			draw_multiline_colors(grid.points_v[i], grid.points_v_color[i])
		for i in grid.sub_points_h.size():
			draw_multiline_colors(grid.sub_points_h[i], grid.points_h_color[i])
		for i in grid.sub_points_v.size():
			draw_multiline_colors(grid.sub_points_v[i], grid.points_v_color[i])
	else:
		var color = Color(0, 1.0, 0.5)
		for i in grid.points_h.size():
			draw_multiline(grid.points_h[i], color)
		for i in grid.points_v.size():
			draw_multiline(grid.points_v[i], color)
		for i in grid.sub_points_h.size():
			draw_multiline(grid.sub_points_h[i], color)
		for i in grid.sub_points_v.size():
			draw_multiline(grid.sub_points_v[i], color)

	
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

