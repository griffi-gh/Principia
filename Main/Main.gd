extends Spatial

signal mode_switched

var objects = []
var held_object = null
var selected_object = null
# mode : 0 - editor; 1 - play

func switch_mode(nmode):
	emit_signal("mode_switched", nmode, Global.current_mode)
	Global.current_mode = nmode
	if nmode==1:
		$GUI/Edit.hide()
		$GUI/Play.text = 'Back'
	elif nmode==0:
		$GUI/Edit.show()
		$GUI/Play.text = 'Play'

func load_objects():
	var f = Global.dir_contents('res://Objects/')
	for v in f.dir:
		print('loading object: ' + v + '...')
		var obj = {
			'scene': ResourceLoader.load(
				'res://Objects/{0}/{0}.tscn'.format([v])
			),
			'info':  ResourceLoader.load(
				'res://Objects/{0}/Info.gd'.format([v])
			)
		}
		objects.append(obj)
	generate_menu()

func generate_prop(obj = null):
	var prop = $GUI/Edit/Prop
	for n in prop.get_children():
		n.queue_free()
	if obj != null:
		for i in obj.actions.size():
			var action = obj.actions[i]
			var button = Button.new()
			button.text = action.name
			button.connect("pressed", obj, action.callback, [button, i])
			prop.add_child(button)

func generate_menu():
	var items = $GUI/Edit/Inv/Items
	for i in objects.size():
		var obj = objects[i].info
		if obj.obj_menu_show:
			var button = Button.new()
			button.text = obj.obj_name
			button.set_tooltip(obj.obj_description)
			button.connect("pressed", self, "_menu_obj_spawn", [i])
			items.add_child(button)

func _menu_obj_spawn(id):
	if held_object:
		held_object.drop()
		held_object.queue_free()
		held_object = null
	var new_obj = add_object(id)
	held_object = new_obj
	new_obj.pickup(true)

func _ready():
	Engine.set_iterations_per_second(120)
	load_objects()
	Global.main_scene = self
	Global.objects = objects
	Global.current_mode = 0
	
func _process(delta):
	#debug gui
	$GUI/JoitnCnt.text = str($GlobalJoints.get_child_count())
	#handle selected_object
	if held_object:
		selected_object = weakref(held_object)
	if selected_object:
		if selected_object.get_ref() == null:
			$GUI/Edit/Prop.hide()
			selected_object = null
			generate_prop(null)
		else:
			$GUI/Edit/Prop.show()
	#handle weld icons
	var weldbtns = $GUI/Edit/WeldBtn
	for v in weldbtns.get_children():
		v.hide()
		v.queue_free()
	if selected_object:
		var soref = selected_object.get_ref()
		for v in soref.touches:
			var body = v.body
			var skip = false
			for j in soref.joints:
				assert(j != null)
				var b = Global.get_joint_node(j, soref)
				if b == body:
					skip = true
					break
			if !skip:
				var pos = (body.global_transform.origin + soref.global_transform.origin) / 2
				var screen_pos = $Camera.unproject_position(pos)
				var weld_icon = Button.new()
				weld_icon.text = 'Weld'
				var weld_icon_size = weld_icon.get_combined_minimum_size()
				weld_icon.margin_left = screen_pos.x - weld_icon_size.x / 2
				weld_icon.margin_top  = screen_pos.y - weld_icon_size.y / 2
				weld_icon.connect("pressed", self, "_on_weld_pressed", [v, selected_object])
				weldbtns.add_child(weld_icon)

func _physics_process(delta):
	pass

const WELD_TYPES = [
	"weld_static"
]

func weld(a, b, type = 'weld_static'):
	var joint
	if type == 'weld_static':
		joint = SliderJoint.new()
		joint.set_param(joint.PARAM_LINEAR_LIMIT_LOWER, 0)
		joint.set_param(joint.PARAM_LINEAR_LIMIT_UPPER, 0)
	joint.set_node_a(a.get_path())
	joint.set_node_b(b.get_path())
	$GlobalJoints.add_child(joint)
	a.joints.append(joint.get_path())
	b.joints.append(joint.get_path())
	#a.get_node("Joints").add_child(joint)
	#b.get_node("Joints").add_child(joint.duplicate())
	return joint

func get_area_weld_type(area):
	for t in WELD_TYPES:
		if area.is_in_group(t):
			return t

func _on_weld_pressed(weld, to):
	weld(
		to.get_ref(), 
		weld.body,
		get_area_weld_type(weld.area)
	)

func _on_Play_pressed():
	if Global.current_mode==0:
		switch_mode(1)
	else:
		switch_mode(0)

func _on_pickable_clicked(obj):
	if Global.current_mode==0 or obj.is_in_group("pickable_interactive"):
		if obj.is_in_group("pickable"):
			if !held_object:
				held_object = obj
				held_object.pickup()
		selected_object = weakref(obj)
		generate_prop(obj) 

func _unhandled_input(event): #
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		if !event.pressed:
			if held_object:
				held_object.drop()
				held_object = null
		else:
			if selected_object and selected_object.get_ref():
				selected_object = null
				generate_prop(null)

func add_object(id):
	var new_obj = objects[id].scene.instance()
	$World/Objects.add_child(new_obj)
	return new_obj
