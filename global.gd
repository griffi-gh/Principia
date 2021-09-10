extends Node

var main_scene
var current_mode
var objects
const layer_depth = 0.5

func get_node_by_path(npath):
	var path = str(npath)
	var properties = path.split(":")
	var obj = get_node_or_null(properties[0])
	if obj == null:
		return
	for i in range(1, len(properties)):
		obj = obj[properties[i]]
		if obj == null:
			return
	return obj

func get_joint_node(joint, obj):
	var a = get_node(get_node(joint).get_node_a())
	var b = get_node(get_node(joint).get_node_b())
	return (b if (a == obj) else a)

func dir_contents(path):
	var contents = {
		"dir": [],
		"files": []
	}
	var dir = Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				if file_name != '..' and file_name != '.':
					contents.dir.append(file_name)
			else:
				contents.files.append(file_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
	return contents

func plane_mouse_pos(obj = self):
	var mouse = obj.get_viewport().get_mouse_position()
	var cam = obj.get_viewport().get_camera()
	var vec = cam.project_position(mouse, cam.global_transform.origin.z)
	return Vector2(vec.x, vec.y)
