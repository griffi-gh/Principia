extends Camera

export var smooth_zoom = true
export var smooth_zoom_speed = 4.0
export var zoom_amount = 0.25

var cam_move_point = Vector2(0,0)
onready var target_cam_z = global_transform.origin.z

func _ready():
	pass

func _process(delta):
	#handle camera movement
	if Input.is_action_just_pressed('move_cam'):
		cam_move_point = Global.plane_mouse_pos()
	elif Input.is_action_pressed('move_cam'):
		var ref = Global.plane_mouse_pos()
		global_transform.origin.x -= (ref.x - cam_move_point.x)
		global_transform.origin.y -= (ref.y - cam_move_point.y)

func _physics_process(delta):
	#handle camera smooth zoom
	if smooth_zoom:
		var diff = target_cam_z - global_transform.origin.z
		if diff != 0:
			var dist = smooth_zoom_speed * delta
			if diff < 0:
				dist *= -1
			global_transform.origin.z += dist
	else:
		global_transform.origin.z = target_cam_z
	size = global_transform.origin.z * 1.5

func _unhandled_input(event):
	if event.is_action("zoom_in") and event.pressed:
		target_cam_z -= zoom_amount
	elif event.is_action("zoom_out") and event.pressed:
		target_cam_z += zoom_amount

func _on_Projection_pressed():
	projection = !projection
