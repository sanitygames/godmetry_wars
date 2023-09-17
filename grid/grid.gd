extends Object
class_name Grid

# 質点のクラス(よくわからない)
class PointMass:
	var position := Vector3.ZERO
	var velocity := Vector3.ZERO
	var inverse_mass := 0.0
	var acceleration := Vector3.ZERO
	var damping := 0.98


	func set_point_mass(p_postition: Vector3, p_inverse_mass: float) -> void:
		position = p_postition
		inverse_mass = p_inverse_mass

	func apply_force(force: Vector3) -> void:
		acceleration += force * inverse_mass

	func increase_damping(factor: float) -> void:
		damping *= factor

	func update() -> void:
		velocity += acceleration
		position += velocity
		acceleration = Vector3.ZERO
		if velocity.length_squared() < 0.001:
			velocity = Vector3.ZERO
		else:
			velocity *= damping
		damping = 0.98

# バネクラス(なんか物理の計算のアレ)
class Spring:
	var end1 :PointMass
	var end2 :PointMass
	var target_length: float
	var stiffness: float
	var damping: float

	func _init(p_end1: PointMass, p_end2: PointMass, p_stiffness: float, p_damping: float) -> void:
		end1 = p_end1
		end2 = p_end2
		target_length = end1.position.distance_to(end2.position) * 0.95
		stiffness = p_stiffness
		damping = p_damping

	func update() -> void:
		var distance: Vector3 = end1.position - end2.position
		var length = distance.length()
		if length > target_length:
			distance = (distance / length) * (length - target_length)
			var delta_velocity = end2.velocity - end1.velocity
			var force = distance * stiffness - delta_velocity * damping
			end1.apply_force(-force)
			end2.apply_force(force)

# バネと質点を並べて仮想の物理的なグリッドを表現
class PhysicsGrid:
	var screen_size: Vector2
	var springs: Array[Spring]
	var cols: int
	var rows: int
	var points: Array[PointMass]
	var fixed_points: Array[PointMass]

	# 初期化、グリッドの仕様を決めて、バネと質点を設定する。
	func _init(rect: Rect2, spacing: Vector2) -> void:
		cols = int(rect.size.x / spacing.x) + 1
		rows = int(rect.size.y / spacing.y) + 1
		screen_size = rect.size
		var y = rect.position.y 
		while y <= rect.end.y:
			y += spacing.y
			var x = rect.position.x
			while x <= rect.end.x:
				x += spacing.x
				var pos_v = Vector3(x, y, 0.0)

				var point_mass = PointMass.new()
				point_mass.set_point_mass(pos_v, 1.0)
				points.push_back(point_mass)

				var fixed_point_mass = PointMass.new()
				fixed_point_mass.set_point_mass(pos_v, 0.0)
				fixed_points.push_back(fixed_point_mass)
				

		# 点が端や特定の位置の場合、バネの一方は固定されたりするので。
		for _y in rows:
			for _x in cols:
				if _x == 0 || _y == 0 || _x == cols - 1 || _y == rows - 1:
					var s = Spring.new(
						fixed_points[_y * cols + _x],
						points[_y * cols + _x],
						0.1, 
						0.1
					)
					springs.push_back(s)
				elif _x % 3 == 0 || _y % 3 == 0:
					var s = Spring.new(
						fixed_points[_y * cols + _x],
						points[_y * cols + _x],
						0.002,
						0.02
					)
					springs.push_back(s)

				if _x > 0:
					var s = Spring.new(
						points[_y * cols + (_x - 1)],
						points[_y * cols + _x],
						0.28, 
						0.06
					)
					springs.push_back(s)

				if _y > 0:
					var s = Spring.new(
						points[(_y - 1) * cols + _x],
						points[_y * cols + _x],
						0.28, 
						0.06,
					)
					springs.push_back(s)

	# 左からx、上からyの質点のスクリーン座標を返す
	func get_point(x: int, y: int) -> Vector2:
		var point = points[y * cols + x]
		var px = point.position
		return _to_vec2(screen_size, px)

	# 概念としてのz座標を考慮して2次元座標を返す。
	func _to_vec2(ss: Vector2, v: Vector3) -> Vector2:
		var factor: float = (v.z + 2000.0) * 0.0005
		return (Vector2(v.x, v.y) - ss * 0.5) * factor + ss * 0.5

	# 質点のz座標を返す(レインボー対応用)
	func get_point_z(x: int, y: int) -> float:
		return points[y * cols + x].position.z

	# 色々な物理の再計算
	func update() -> void:
		for i in springs.size():
			springs[i].update()
		for i in cols * rows:
			points[i].update()

	# 爆発の力を与える
	func apply_explosive_force(force: float, pos: Vector3, radius: float) -> void:
		for i in rows * cols:
			var dist2 = pos.distance_squared_to(points[i].position)
			if dist2 < radius * radius:
				var point = points[i].position
				points[i].apply_force((point - pos) * (force * 100.0) / 10000.0)

	# 押し引きの力を与える
	func apply_directed_force(force: Vector3, pos: Vector3, radius: float) -> void:
		for i in rows * cols:
			if pos.distance_squared_to(points[i].position) < radius * radius:
				points[i].apply_force(force * 10.0 / (10.0 + pos.distance_to(points[i].position)))

################################################################################
# ここからメイン。PhysicsGridの計算結果をArray[PackedVector2Array]に収める。
################################################################################
var physics_grid: PhysicsGrid 
var points_h: Array[PackedVector2Array] # ちゃんと計算して描く横線
var points_v: Array[PackedVector2Array] # ちゃんと計算して描く縦線
var points_h_color: Array[PackedColorArray] # 横線の色情報（レインボー用)
var points_v_color: Array[PackedColorArray] # 縦線の色情報（レインボー用)
var sub_points_h: Array[PackedVector2Array] # 見える線のうち半分は線と線の間ってことで計算を簡略化してる。
var sub_points_v: Array[PackedVector2Array] # ので、k物理的な計算をしてる点は全体の1/4


# 初期化
func _init(p_rect: Rect2, p_spacing: Vector2, _p_resolution: int = 1):
	physics_grid = PhysicsGrid.new(p_rect, p_spacing)

	var cols = physics_grid.cols
	var rows = physics_grid.rows

	var f_get_packed_vector2_array = func(size):
		var _a = PackedVector2Array()
		_a.resize(size)
		_a.fill(Vector2.ZERO)
		return _a
	
	var f_get_packed_color_array = func(size):
		var _a = PackedColorArray()
		_a.resize(size)
		_a.fill(Color.from_hsv(1.0, 1.0, 1.0))
		return _a

	for __ in rows:
		points_h.push_back(f_get_packed_vector2_array.call(cols))
		points_h_color.push_back(f_get_packed_color_array.call(cols))
		sub_points_h.push_back(f_get_packed_vector2_array.call(cols))

	for __ in cols:
		points_v.push_back(f_get_packed_vector2_array.call(rows))
		points_v_color.push_back(f_get_packed_color_array.call(rows))
		sub_points_v.push_back(f_get_packed_vector2_array.call(rows))


# 物理計算をして、結果をArray[PackedXXXArray]に。収める。
# sub_points_XX(物理演算をしない点)は線と線の中間の点を収める。
func update() -> void:
	physics_grid.update()
	for y in physics_grid.rows:
		for x in physics_grid.cols:
			points_h[y][x] = physics_grid.get_point(x, y)
			points_h_color[y][x].h = physics_grid.get_point_z(x, y) * 0.003

	for x in physics_grid.cols:
		for y in physics_grid.rows:
			points_v[x][y] = physics_grid.get_point(x, y)
			points_v_color[x][y].h = physics_grid.get_point_z(x, y) * 0.003


	for y in sub_points_h.size() - 1:
		for x in sub_points_h[y].size(): 
			sub_points_h[y][x] = Vector2(
				points_h[y][x].x,
				(points_h[y + 1][x].y - points_h[y][x].y) * 0.5 + points_h[y][x].y
			)

	for x in sub_points_v.size() - 1:
		for y in sub_points_v[x].size():
			sub_points_v[x][y] = Vector2(
				(points_v[x + 1][y].x - points_v[x][y].x) * 0.5 + points_v[x][y].x,
				points_v[x][y].y
			)


