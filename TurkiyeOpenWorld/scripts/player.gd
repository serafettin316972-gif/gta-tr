extends CharacterBody3D

# Third-person character controller. The model is assembled from shaded,
# articulated meshes so the project stays lightweight on integrated GPUs.
@export var walk_speed := 4.8
@export var run_speed := 7.2
@export var acceleration := 18.0
@export var jump_velocity := 4.6
@export var mouse_sensitivity := 0.0022

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var camera_pivot: Node3D
var camera: Camera3D
var visual: Node3D
var torso: Node3D
var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D
var animation_clock := 0.0
var driving := false
var current_vehicle: CharacterBody3D
var health := 100

var _materials: Dictionary = {}
var imported_animation_player: AnimationPlayer
var imported_animations: Dictionary = {}
var imported_current_animation := ""

func _ready() -> void:
	_build_character()
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.32
	shape.height = 1.82
	collision.shape = shape
	collision.position.y = 0.91
	add_child(collision)

	camera_pivot = Node3D.new()
	camera_pivot.position = Vector3(0, 1.48, 0)
	add_child(camera_pivot)
	camera = Camera3D.new()
	camera.position = Vector3(0, 0.35, 5.4)
	camera.rotation_degrees.x = -7
	camera.fov = 72
	camera.current = true
	camera_pivot.add_child(camera)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _material(key: String, color: Color, roughness := 0.78, metallic := 0.0) -> StandardMaterial3D:
	if _materials.has(key):
		return _materials[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	_materials[key] = material
	return material

func _mesh(parent: Node3D, mesh: Mesh, pos: Vector3, mat: Material, scale_v := Vector3.ONE) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = pos
	node.scale = scale_v
	node.material_override = mat
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(node)
	return node

func _capsule(parent: Node3D, pos: Vector3, radius: float, height: float, mat: Material) -> MeshInstance3D:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	return _mesh(parent, mesh, pos, mat)

func _sphere(parent: Node3D, pos: Vector3, scale_v: Vector3, mat: Material) -> MeshInstance3D:
	return _mesh(parent, SphereMesh.new(), pos, mat, scale_v)

func _box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _mesh(parent, mesh, pos, mat)

func _build_character() -> void:
	visual = Node3D.new()
	add_child(visual)

	# Prefer the custom GLB character downloaded by the Windows build workflow.
	var imported_scene := load("res://assets/man-base-character-rigged.glb") as PackedScene
	if imported_scene != null:
		var imported_model := imported_scene.instantiate() as Node3D
		if imported_model != null:
			visual.add_child(imported_model)
			_fit_imported_model(imported_model)
			_setup_imported_animations(imported_model)
			return

	var tracksuit := _material("tracksuit", Color(0.018, 0.024, 0.032))
	var tracksuit_dark := _material("tracksuit_dark", Color(0.009, 0.013, 0.019))
	var stripe := _material("stripe", Color(0.83, 0.85, 0.84), 0.55)
	var skin := _material("skin", Color(0.61, 0.39, 0.28), 0.88)
	var skin_light := _material("skin_light", Color(0.72, 0.49, 0.36), 0.86)
	var hair := _material("hair", Color(0.025, 0.019, 0.016))
	var white := _material("shirt", Color(0.88, 0.87, 0.82), 0.9)
	var shoe := _material("shoe", Color(0.91, 0.91, 0.87), 0.65)
	var eye := _material("eye", Color(0.055, 0.04, 0.03), 0.4)
	var red := _material("flag_red", Color(0.72, 0.035, 0.045), 0.65)

	# Torso and layered jacket.
	torso = Node3D.new()
	torso.position.y = 0.98
	visual.add_child(torso)
	_capsule(torso, Vector3(0, 0.22, 0), 0.255, 0.78, tracksuit)
	_capsule(torso, Vector3(0, -0.22, 0), 0.22, 0.28, tracksuit_dark)
	_box(torso, Vector3(0, 0.22, -0.226), Vector3(0.29, 0.43, 0.025), white)
	_box(torso, Vector3(0, 0.22, -0.244), Vector3(0.018, 0.42, 0.012), stripe)
	_box(torso, Vector3(0.19, 0.02, -0.214), Vector3(0.075, 0.055, 0.018), red)
	_box(torso, Vector3(0.19, 0.02, -0.226), Vector3(0.032, 0.025, 0.008), white)

	# Neck and head.
	_capsule(visual, Vector3(0, 1.43, 0), 0.105, 0.24, skin)
	_sphere(visual, Vector3(0, 1.65, 0), Vector3(0.205, 0.245, 0.185), skin)
	_sphere(visual, Vector3(0, 1.81, 0.015), Vector3(0.215, 0.115, 0.19), hair)
	_sphere(visual, Vector3(-0.19, 1.67, 0.015), Vector3(0.045, 0.15, 0.17), hair)
	_sphere(visual, Vector3(0.19, 1.67, 0.015), Vector3(0.045, 0.15, 0.17), hair)
	_sphere(visual, Vector3(0, 1.57, 0.095), Vector3(0.18, 0.12, 0.10), hair)
	# Joined eyebrow, eyes, nose and mouth are kept subtle and readable.
	_box(visual, Vector3(0, 1.704, -0.177), Vector3(0.245, 0.035, 0.025), hair)
	_sphere(visual, Vector3(-0.075, 1.66, -0.174), Vector3(0.025, 0.018, 0.012), eye)
	_sphere(visual, Vector3(0.075, 1.66, -0.174), Vector3(0.025, 0.018, 0.012), eye)
	_sphere(visual, Vector3(0, 1.625, -0.195), Vector3(0.035, 0.04, 0.035), skin_light)
	_box(visual, Vector3(0, 1.555, -0.178), Vector3(0.075, 0.012, 0.012), hair)

	# Articulated arms: separate shoulder pivots make the walk cycle visible.
	left_arm = _make_arm(-1, tracksuit, stripe, skin)
	right_arm = _make_arm(1, tracksuit, stripe, skin)
	left_leg = _make_leg(-1, tracksuit, stripe, shoe)
	right_leg = _make_leg(1, tracksuit, stripe, shoe)

func _fit_imported_model(model: Node3D) -> void:
	var meshes := model.find_children("*", "MeshInstance3D", true, false)
	var found_mesh := false
	var min_y := INF
	var max_y := -INF
	for item in meshes:
		var mesh_instance := item as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null:
			continue
		var bounds: AABB = mesh_instance.global_transform * mesh_instance.get_aabb()
		min_y = minf(min_y, bounds.position.y)
		max_y = maxf(max_y, bounds.position.y + bounds.size.y)
		found_mesh = true
	if found_mesh and max_y - min_y > 0.001:
		var fit_scale := 1.75 / (max_y - min_y)
		model.scale *= fit_scale
		model.position.y = -min_y * fit_scale

func _setup_imported_animations(model: Node3D) -> void:
	# GLB imports may expose one or more AnimationPlayer nodes. Cache clips by
	# their names so locomotion can switch between idle, walk and run safely.
	var players := model.find_children("*", "AnimationPlayer", true, false)
	for item in players:
		var candidate_player := item as AnimationPlayer
		if candidate_player == null:
			continue
		var clips := candidate_player.get_animation_list()
		if clips.is_empty():
			continue
		imported_animation_player = candidate_player
		for clip in clips:
			var clip_name := str(clip)
			var normalized := clip_name.to_lower().replace("_", "").replace("-", "").replace(" ", "")
			if normalized.contains("idle") or normalized.contains("breath"):
				imported_animations["idle"] = clip_name
			elif normalized.contains("run") or normalized.contains("sprint"):
				imported_animations["run"] = clip_name
			elif normalized.contains("walk") or normalized.contains("jog"):
				imported_animations["walk"] = clip_name
		break
	_play_imported_animation("idle")

func _play_imported_animation(state: String) -> void:
	if imported_animation_player == null:
		return
	var selected := ""
	if imported_animations.has(state):
		selected = str(imported_animations[state])
	elif state == "run" and imported_animations.has("walk"):
		selected = str(imported_animations["walk"])
	elif imported_animations.has("idle"):
		selected = str(imported_animations["idle"])
	else:
		var clips := imported_animation_player.get_animation_list()
		if not clips.is_empty():
			selected = str(clips[0])
	if selected.is_empty() or selected == imported_current_animation:
		return
	imported_current_animation = selected
	imported_animation_player.play(selected, 0.18)

func _update_imported_animation(moving: bool, running: bool) -> void:
	if imported_animation_player == null:
		return
	if not moving:
		_play_imported_animation("idle")
	elif running:
		_play_imported_animation("run")
	else:
		_play_imported_animation("walk")

func _make_arm(side: int, jacket: Material, stripe_mat: Material, hand_mat: Material) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = Vector3(0.31 * side, 1.29, 0)
	visual.add_child(pivot)
	_capsule(pivot, Vector3(0, -0.22, 0), 0.105, 0.48, jacket)
	_box(pivot, Vector3(0.105 * side, -0.22, -0.005), Vector3(0.025, 0.38, 0.12), stripe_mat)
	_capsule(pivot, Vector3(0, -0.57, 0), 0.085, 0.38, jacket)
	_sphere(pivot, Vector3(0, -0.79, -0.005), Vector3(0.075, 0.09, 0.07), hand_mat)
	return pivot

func _make_leg(side: int, pants: Material, stripe_mat: Material, shoe_mat: Material) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = Vector3(0.135 * side, 0.77, 0)
	visual.add_child(pivot)
	_capsule(pivot, Vector3(0, -0.22, 0), 0.12, 0.52, pants)
	_box(pivot, Vector3(0.105 * side, -0.22, -0.005), Vector3(0.025, 0.40, 0.13), stripe_mat)
	_capsule(pivot, Vector3(0, -0.57, 0), 0.105, 0.43, pants)
	_box(pivot, Vector3(0, -0.70, -0.055), Vector3(0.22, 0.13, 0.34), shoe_mat)
	_box(pivot, Vector3(0, -0.765, -0.07), Vector3(0.22, 0.025, 0.33), stripe_mat)
	return pivot

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not driving:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera_pivot.rotate_x(-event.relative.y * mouse_sensitivity)
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -0.48, 0.28)
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if driving and is_instance_valid(current_vehicle):
		global_position = current_vehicle.global_position + Vector3(0, 1.0, 0)
		rotation.y = current_vehicle.rotation.y
		return

	var input_dir := Vector2.ZERO
	input_dir.x = float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
	input_dir.y = float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
	input_dir = input_dir.normalized()
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var running := Input.is_key_pressed(KEY_SHIFT)
	var target_speed := run_speed if running else walk_speed
	if direction.length_squared() > 0.0001:
		velocity.x = move_toward(velocity.x, direction.x * target_speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * target_speed, acceleration * delta)
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-direction.x, -direction.z) - rotation.y, delta * 11.0)
	else:
		velocity.x = move_toward(velocity.x, 0.0, acceleration * 1.35 * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * 1.35 * delta)

	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_key_pressed(KEY_SPACE):
		velocity.y = jump_velocity

	move_and_slide()
	var is_moving := input_dir.length() > 0.05
	if imported_animation_player != null:
		_update_imported_animation(is_moving, running)
	else:
		_animate_character(delta, is_moving, running)

func _animate_character(delta: float, moving: bool, running: bool) -> void:
	if left_leg == null or right_leg == null or left_arm == null or right_arm == null or torso == null:
		return
	var amount := 1.0 if moving else 0.0
	var frequency := 11.5 if running else 8.2
	if moving:
		animation_clock += delta * frequency
	var swing := sin(animation_clock) * (0.78 if running else 0.52) * amount
	var blend_speed := delta * 12.0
	left_leg.rotation.x = lerp_angle(left_leg.rotation.x, swing, blend_speed)
	right_leg.rotation.x = lerp_angle(right_leg.rotation.x, -swing, blend_speed)
	left_arm.rotation.x = lerp_angle(left_arm.rotation.x, -swing * 0.72, blend_speed)
	right_arm.rotation.x = lerp_angle(right_arm.rotation.x, swing * 0.72, blend_speed)
	torso.position.y = lerp(torso.position.y, 0.98 + (abs(sin(animation_clock * 2.0)) * 0.035 * amount), blend_speed)
