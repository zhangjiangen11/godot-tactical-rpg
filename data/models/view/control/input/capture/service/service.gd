class_name InputCaptureService
extends RefCounted

var res: InputCaptureResource

func _init(_res: InputCaptureResource) -> void:
	res = _res


func process_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		# --- MOUSE BUTTONS ---
		if event.pressed:
			# free look toggle
			if event.is_action("camera_free_look"):
				res.free_look_pressed = true
		else:
			# free look toggle
			if event.is_action_released("camera_free_look"):
				res.free_look_pressed = false
		# free_look motion capture handled directly by camera model service's handle_input()
		# camera zoom scroll capture also handled by cam model service handle_input()
	elif event is InputEventKey:
		# ----- KEYS -----
		if event.pressed:
			# camera pan direction (WASD)
			for action: StringName in res.CAMERA_PAN_KEYS:
				if event.is_action(action):
					res.cam_direction = Input.get_vector(
							"camera_left", "camera_right", 
							"camera_forward", "camera_backwards")
					return
		# Handle key releases
		else:
			# camera pan direction (WASD)
			for action: StringName in res.CAMERA_PAN_KEYS:
				if event.is_action_released(action):
					# Recalculate cam_direction after key release
					res.cam_direction = Input.get_vector("camera_left", "camera_right", "camera_forward", "camera_backwards")
					return
	elif event is InputEventJoypadMotion:
		# --- JOYSTICKS ---
		# camera pan direction (left joystick)
		if event.axis in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y]:
			res.left_stick_x = Input.get_joy_axis(0, JoyAxis.JOY_AXIS_LEFT_X)
			res.left_stick_y = Input.get_joy_axis(0, JoyAxis.JOY_AXIS_LEFT_Y)
			
			# Calculate the magnitude of the joystick input
			var magnitude = Vector2(res.left_stick_x, res.left_stick_y).length()
			if magnitude > res.CONTROLLER_DEADZONE:
				res.cam_direction = Vector2(res.left_stick_x, res.left_stick_y)
			else:
				res.cam_direction = Vector2.ZERO
		# camera free look direction (right joystick)
		if event.axis in [JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y]:
			if abs(event.axis_value) > res.CONTROLLER_DEADZONE:
				res.right_stick_x = -Input.get_joy_axis(0, JoyAxis.JOY_AXIS_RIGHT_X)
				res.right_stick_y = Input.get_joy_axis(0, JoyAxis.JOY_AXIS_RIGHT_Y)
			elif abs(event.axis_value) < res.CONTROLLER_DEADZONE:
				res.right_stick_x = 0.0
				res.right_stick_y = 0.0
	elif event is InputEventJoypadButton:
		# --- JOY BUTTONS ---
		if event.pressed:
			# 
			pass
		else:
			# 
			pass


func handle_input(_event: InputEvent) -> void:
	pass


func project_mouse_position(collision_mask: int, is_joystick: bool, input_capture: InputCapture) -> CollisionObject3D:
	if !res:
		return
	var camera: Camera3D = input_capture.get_viewport().get_camera_3d()
	res.mouse_position = input_capture.get_viewport().get_mouse_position()
	var pointer_origin: Vector2 = res.mouse_position if not is_joystick else input_capture.get_viewport().size / 2
	
	var from: Vector3 = camera.project_ray_origin(pointer_origin)
	var to: Vector3 = from + camera.project_ray_normal(pointer_origin) * res.RAY_LENGTH
	
	if DebugLog.visual_debug:
		draw_debug_ray(from, to, input_capture.debug_ray_mesh, input_capture)
	
	var ray_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to, collision_mask, [])
	var collider: CollisionObject3D = input_capture.get_world_3d().direct_space_state.intersect_ray(ray_query).get("collider")
	
	return collider


func setup_debug_ray(parent: Node3D) -> MeshInstance3D:
	var debug_ray_mesh: MeshInstance3D = MeshInstance3D.new()
	var mesh: ImmediateMesh = ImmediateMesh.new()
	debug_ray_mesh.mesh = mesh
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.YELLOW
	material.vertex_color_use_as_albedo = true
	debug_ray_mesh.material_override = material
	parent.add_child(debug_ray_mesh)
	return debug_ray_mesh


func draw_debug_ray(from: Vector3, to: Vector3, debug_ray_mesh: MeshInstance3D, parent: Node3D) -> void:
	var mesh: ImmediateMesh = debug_ray_mesh.mesh as ImmediateMesh
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh.surface_add_vertex(parent.to_local(from))
	mesh.surface_add_vertex(parent.to_local(to))
	mesh.surface_end()
