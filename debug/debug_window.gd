extends Panel

var point_size := 0: 
	set(value):
		point_size = value
		$Points.text = "Points: " + str(point_size)


func _input(event):
	if event.is_action_pressed("debug"):
		print("XX")
		visible = !visible



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if visible:
		$Fps.text = "FPS " + str(Engine.get_frames_per_second())