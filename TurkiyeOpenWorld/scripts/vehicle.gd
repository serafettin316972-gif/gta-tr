extends CharacterBody3D

var speed := 0.0
var max_speed := 22.0
var occupied := false
var driver: Node3D
var body_material: StandardMaterial3D

func _ready() -> void:
	_build_car()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.95, 1.55, 3.85)
	collision.shape = shape
	collision.position.y = 0.78
	add_child(collision)

func _mat(color: Color, roughness := 0.55, metallic := 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	return mat

func _box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material, tilt := 0.0) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = pos
	node.rotation.x = tilt
	node.material_override = mat
	parent.add_child(node)
	return node

func _build_car() -> void:
	var paint_colors := [Color(0.10, 0.19, 0.28), Color(0.48, 0.12, 0.075), Color(0.68, 0.66, 0.59), Color(0.12, 0.24, 0.17)]
	body_material = _mat(paint_colors[randi() % paint_colors.size()], 0.27, 0.48)
	var dark := _mat(Color(0.035, 0.045, 0.052), 0.32)
	var glass := _mat(Color(0.055, 0.13, 0.17), 0.18, 0.18)
	var chrome := _mat(Color(0.55, 0.57, 0.57), 0.25, 0.72)
	var headlight := _mat(Color(0.96, 0.86, 0.62), 0.2)
	var tail_light := _mat(Color(0.62, 0.025, 0.025), 0.25)

	# Main body, bonnet, boot and raised passenger cabin.
	_box(self, Vector3(0, 0.68, 0), Vector3(1.88, 0.58, 3.75), body_material)
	_box(self, Vector3(0, 0.92, -1.12), Vector3(1.82, 0.25, 1.15), body_material)
	_box(self, Vector3(0, 0.91, 1.28), Vector3(1.82, 0.24, 0.78), body_material)
	_box(self, Vector3(0, 1.27, 0.12), Vector3(1.48, 0.72, 1.88), body_material)

	# Dark windows and pillars.
	_box(self, Vector3(0, 1.31, -0.83), Vector3(1.30, 0.48, 0.035), glass, -0.20)
	_box(self, Vector3(0, 1.31, 1.08), Vector3(1.30, 0.48, 0.035), glass, 0.20)
	for side in [-1, 1]:
		_box(self, Vector3(side * 0.755, 1.31, 0.12), Vector3(0.035, 0.47, 1.48), glass)
		_box(self, Vector3(side * 0.76, 1.31, -0.73), Vector3(0.055, 0.55, 0.09), dark)
		_box(self, Vector3(side * 0.76, 1.31, 0.91), Vector3(0.055, 0.55, 0.09), dark)
		_box(self, Vector3(side * 0.98, 1.12, -0.52), Vector3(0.24, 0.12, 0.20), body_material)

	# Front and rear details.
	_box(self, Vector3(0, 0.52, -1.91), Vector3(1.72, 0.16, 0.10), chrome)
	_box(self, Vector3(0, 0.67, -1.91), Vector3(0.62, 0.19, 0.035), dark)
	_box(self, Vector3(-0.63, 0.83, -1.91), Vector3(0.38, 0.20, 0.06), headlight)
	_box(self, Vector3(0.63, 0.83, -1.91), Vector3(0.38, 0.20, 0.06), headlight)
	_box(self, Vector3(-0.66, 0.82, 1.90), Vector3(0.32, 0.22, 0.055), tail_light)
	_box(self, Vector3(0.66, 0.82, 1.90), Vector3(0.32, 0.22, 0.055), tail_light)
	_box(self, Vector3(0, 0.53, 1.91), Vector3(1.72, 0.14, 0.10), chrome)

	# Wheels, tyres and simple metallic hubs.
	for x in [-0.91, 0.91]:
		for z in [-1.22, 1.22]:
			var tyre := MeshInstance3D.new()
			var tyre_mesh := CylinderMesh.new()
			tyre_mesh.top_radius = 0.36
			tyre_mesh.bottom_radius = 0.36
			tyre_mesh.height = 0.22
			tyre.mesh = tyre_mesh
			tyre.rotation.z = PI / 2.0
			tyre.position = Vector3(x, 0.39, z)
			tyre.material_override = dark
			add_child(tyre)
			var hub := MeshInstance3D.new()
			var hub_mesh := CylinderMesh.new()
			hub_mesh.top_radius = 0.19
			hub_mesh.bottom_radius = 0.19
			hub_mesh.height = 0.235
			hub.mesh = hub_mesh
			hub.rotation.z = PI / 2.0
			hub.position = Vector3(x * 1.015, 0.39, z)
			hub.material_override = chrome
			add_child(hub)

func _physics_process(delta: float) -> void:
	if not occupied:
		return
	var throttle := float(Input.is_key_pressed(KEY_W)) - float(Input.is_key_pressed(KEY_S))
	var steer := float(Input.is_key_pressed(KEY_A)) - float(Input.is_key_pressed(KEY_D))
	speed = move_toward(speed, throttle * max_speed, 9.0 * delta)
	if Input.is_key_pressed(KEY_SPACE):
		speed = move_toward(speed, 0.0, 20.0 * delta)
	rotation.y += steer * sign(speed) * delta * clamp(abs(speed) / 7.0, 0.12, 1.0) * 1.25
	var forward: Vector3 = -global_transform.basis.z
	velocity.x = forward.x * speed
	velocity.z = forward.z * speed
	velocity.y -= 9.8 * delta
	move_and_slide()
