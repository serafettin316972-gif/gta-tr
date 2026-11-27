extends CharacterBody3D

var origin: Vector3
var phase := 0.0
var walk_clock := 0.0
var left_leg: Node3D
var right_leg: Node3D
var left_arm: Node3D
var right_arm: Node3D

func _ready() -> void:
	origin = global_position
	phase = randf() * TAU
	_build_pedestrian()
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.27
	shape.height = 1.72
	col.shape = shape
	col.position.y = 0.86
	add_child(col)

func _mat(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.86
	return mat

func _capsule(parent: Node3D, pos: Vector3, radius: float, height: float, mat: Material) -> MeshInstance3D:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = pos
	node.material_override = mat
	parent.add_child(node)
	return node

func _build_pedestrian() -> void:
	var skin := _mat(Color(randf_range(0.40, 0.75), randf_range(0.27, 0.52), randf_range(0.18, 0.38)))
	var shirt := _mat([Color(0.20, 0.28, 0.38), Color(0.48, 0.24, 0.18), Color(0.32, 0.38, 0.27), Color(0.55, 0.52, 0.45)][randi() % 4])
	var trousers := _mat([Color(0.07, 0.09, 0.12), Color(0.18, 0.20, 0.22), Color(0.25, 0.20, 0.16)][randi() % 3])
	var hair := _mat(Color(0.035, 0.028, 0.023))
	var shoes := _mat(Color(0.08, 0.08, 0.075))

	_capsule(self, Vector3(0, 1.12, 0), 0.23, 0.65, shirt)
	_capsule(self, Vector3(0, 1.63, 0), 0.155, 0.34, skin)
	var head_hair := MeshInstance3D.new()
	head_hair.mesh = SphereMesh.new()
	head_hair.position = Vector3(0, 1.77, 0.015)
	head_hair.scale = Vector3(0.16, 0.075, 0.15)
	head_hair.material_override = hair
	add_child(head_hair)

	left_arm = Node3D.new()
	left_arm.position = Vector3(-0.27, 1.35, 0)
	add_child(left_arm)
	right_arm = Node3D.new()
	right_arm.position = Vector3(0.27, 1.35, 0)
	add_child(right_arm)
	for arm in [left_arm, right_arm]:
		_capsule(arm, Vector3(0, -0.23, 0), 0.075, 0.48, shirt)
		_capsule(arm, Vector3(0, -0.53, 0), 0.065, 0.24, skin)

	left_leg = Node3D.new()
	left_leg.position = Vector3(-0.12, 0.82, 0)
	add_child(left_leg)
	right_leg = Node3D.new()
	right_leg.position = Vector3(0.12, 0.82, 0)
	add_child(right_leg)
	for leg in [left_leg, right_leg]:
		_capsule(leg, Vector3(0, -0.25, 0), 0.09, 0.52, trousers)
		_capsule(leg, Vector3(0, -0.57, 0), 0.08, 0.42, trousers)
		var foot := MeshInstance3D.new()
		var foot_mesh := BoxMesh.new()
		foot_mesh.size = Vector3(0.17, 0.10, 0.27)
		foot.mesh = foot_mesh
		foot.position = Vector3(0, -0.79, -0.045)
		foot.material_override = shoes
		leg.add_child(foot)

func _physics_process(delta: float) -> void:
	phase += delta * 0.24
	walk_clock += delta * 4.8
	var target := origin + Vector3(sin(phase) * 4.0, 0, cos(phase * 0.7) * 4.0)
	var direction := target - global_position
	if direction.length() > 0.55:
		velocity.x = move_toward(velocity.x, direction.normalized().x * 1.05, delta * 2.8)
		velocity.z = move_toward(velocity.z, direction.normalized().z * 1.05, delta * 2.8)
		rotation.y = lerp_angle(rotation.y, atan2(-velocity.x, -velocity.z), delta * 3.0)
	else:
		velocity.x = move_toward(velocity.x, 0.0, delta * 2.0)
		velocity.z = move_toward(velocity.z, 0.0, delta * 2.0)
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	move_and_slide()

	var walking := Vector2(velocity.x, velocity.z).length() > 0.25
	var swing := sin(walk_clock) * 0.38 if walking else 0.0
	left_leg.rotation.x = lerp_angle(left_leg.rotation.x, swing, delta * 7.0)
	right_leg.rotation.x = lerp_angle(right_leg.rotation.x, -swing, delta * 7.0)
	left_arm.rotation.x = lerp_angle(left_arm.rotation.x, -swing, delta * 7.0)
	right_arm.rotation.x = lerp_angle(right_arm.rotation.x, swing, delta * 7.0)
