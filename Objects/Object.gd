extends RigidBody

signal clicked

var actions = []

var EDITOR_MODE = MODE_STATIC
var PLAY_MODE = MODE_RIGID
var EDITOR_GRAVITY_SCALE = 0.0
var PLAY_GRAVITY_SCALE = 1.0

var returnTo
var held = false
var val = []
var layer = 1
var temporary = false
var touches = []

var offset = Vector3(0,0,0)

#callbacks
func tick(_d):
	pass

func init():
	pass
	
func on_play():
	pass

#godot fn's
func apply_mode(m):
	gravity_scale = PLAY_GRAVITY_SCALE if m==1 else EDITOR_GRAVITY_SCALE
	mode = EDITOR_MODE if m==0 else PLAY_MODE 

func _menu_action_delete(b, i):
	p_destroy()
	
func _menu_action_layer(b, i):
	var change_to = max((layer + 1) % 4, 1)
	p_set_layer(change_to)
	var new_text = 'Layer: ' + str(layer) 
	actions[i].name = new_text
	b.text = new_text

func _menu_action_unweld(b, i):
	p_unweld()

func _ready():
	add_to_group("objects")
	set_axis_lock(PhysicsServer.BODY_AXIS_ANGULAR_X, true)
	set_axis_lock(PhysicsServer.BODY_AXIS_ANGULAR_Y, true)
	set_axis_lock(PhysicsServer.BODY_AXIS_LINEAR_Z,  true)
	###
	var joints_node = Node.new()
	joints_node.set_name("Joints")
	add_child(joints_node)
	###
	connect("input_event", self, "_on_input_event")
	for node in $Weld.get_children():
		node.connect("body_entered", self, "_weld_area_entered", [node])
		node.connect("body_exited",  self, "_weld_area_exited",  [node])
	Global.main_scene.connect("mode_switched", self, "mode_switched")
	connect("clicked", Global.main_scene, "_on_pickable_clicked")
	###
	p_set_layer(1)
	if Global.current_mode==1:
		temporary = true
		mode_switched(1, 0)
	elif Global.current_mode==0:
		add_to_group('pickable')
	apply_mode(Global.current_mode)
	###
	init()
	###
	actions.append(
		{
			'name': 'Delete',
			'callback': '_menu_action_delete'
		}
	)
	actions.append(
		{
			'name': 'Unweld',
			'callback': '_menu_action_unweld'
		}
	)
	actions.append(
		{
			'name': 'Layer: ' + str(layer),
			'callback': '_menu_action_layer'
		}
	)

func _process(delta):
	tick(delta)

func get_mouse_pos3d(mouse_pos = null):
	if mouse_pos == null:
		mouse_pos = get_viewport().get_mouse_position()
	var cam = get_viewport().get_camera() #Global.main_scene.get_node("Camera")
	var depth = abs(cam.global_transform.origin.z - global_transform.origin.z)
	var z = global_transform.origin.z
	var transform = cam.project_position(mouse_pos, depth)
	transform.z = z
	return transform

func _physics_process(delta):
	if held:
		#var offset = get_viewport().get_mouse_position() - obj_move_point 
		var z = global_transform.origin.z
		global_transform.origin = get_mouse_pos3d() + offset
		global_transform.origin.z = z

func _on_input_event(_a, event, _b, _c, _d):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			emit_signal("clicked", self)

func mode_switched(new,old):
	if new != old:
		apply_mode(new)
		if new==1:
			returnTo = global_transform
			on_play()
		elif new==0:
			if temporary:
				queue_free()
			else:
				global_transform = returnTo
				val = []

func debug_areas(body, area):
	print('self ' + str(self.get_instance_id()))
	print('body ' + str(body.get_instance_id()))
	print('area ' + str(area.get_instance_id()))

func _weld_area_entered(body, area):
	var valid = body != self and body.is_in_group("objects")
	if valid:
		touches.append({
			body = body,
			area = area 
		})
		print('valid enter')
	else:
		print('invalid enter')
	debug_areas(body, area)

func _weld_area_exited(body, area):
	if body != self:
		for i in touches.size():
			if touches[i].body == body:
				touches.remove(i)
				break
		print('exit')
		debug_areas(body, area)

func pickup(zero_offset = false):
	held = true
	if zero_offset:
		offset = Vector3(0,0,0)
	else:
		offset = transform.origin - get_mouse_pos3d(get_viewport().get_mouse_position())
	
func drop():
	held = false

#api
const layer_depth = 0.5

func p_set_layer(new_layer):
	global_transform.origin.z = (layer_depth / 2) + (-layer_depth * int(round(new_layer)))
	layer = new_layer

func p_get_layer():
	return layer

func p_set_position(x, y, layer = -1):
	if layer != -1:
		p_set_layer(layer)
	global_transform.origin.x = x
	global_transform.origin.y = y

func p_get_angle():
	return global_transform.basis.get_euler().y
		
func p_unweld():
	for joint in $Joints.get_children():
		joint.queue_free()

#func p_set_angle(deg):
#	set_rotation_deg(Vector3(0,45,0))

func p_destroy():
	queue_free()
