extends Node3D

const PlayerScript = preload("res://scripts/player.gd")
const VehicleScript = preload("res://scripts/vehicle.gd")
const NPCScript = preload("res://scripts/npc.gd")
var player
var hud: CanvasLayer
var info: Label
var money := 1250
var wanted := 0
var mission_stage := 0
var mission_reward := 750
var nearby_vehicle: CharacterBody3D
var shop_position := Vector3(8,0,-10)
var day_time := 12.0
var phone_open := false
var inventory_open := false
var e_was_down := false

func _ready() -> void:
	_setup_world()
	_spawn_environment_assets()
	_spawn_player()
	_spawn_traffic()
	_spawn_player_vehicle()
	_spawn_npcs()
	_setup_hud()
	_load_game()

func _mat(color: Color, rough := 0.85) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = rough
	return material

func _box(parent: Node3D, pos: Vector3, size: Vector3, color: Variant) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = pos
	node.material_override = color if color is Material else _mat(color)
	parent.add_child(node)
	return node

func _static_box(pos: Vector3, size: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	add_child(body)
	_box(body, Vector3.ZERO, size, color)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)

func _setup_world() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = Sky.new()
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.72, 0.76, 0.82)
	environment.ambient_light_energy = 0.65
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.63, 0.70, 0.77)
	environment.fog_density = 0.0018
	world_environment.environment = environment
	add_child(world_environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -35, 0)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 90.0
	sun.shadow_bias = 0.08
	add_child(sun)
	_static_box(Vector3(0, -0.35, 0), Vector3(260, 0.6, 260), Color(0.28, 0.34, 0.29))
	for i in range(-5, 6):
		_static_box(Vector3(i * 24, 0.0, 0), Vector3(9, 0.12, 250), Color(0.105, 0.115, 0.12))
		_static_box(Vector3(0, 0.01, i * 24), Vector3(250, 0.12, 9), Color(0.105, 0.115, 0.12))
		for side in [-1, 1]:
			_static_box(Vector3(i * 24 + side * 6, 0.08, 0), Vector3(2, 0.22, 250), Color(0.52, 0.5, 0.45))
			_static_box(Vector3(0, 0.08, i * 24 + side * 6), Vector3(250, 0.22, 2), Color(0.52, 0.5, 0.45))
	# Fewer, larger blocks leave room for streets and keep draw calls controlled.
	for x in range(-3, 4):
		for z in range(-3, 4):
			var center := Vector3(x * 24 + 12, 0, z * 24 + 12)
			var height := randf_range(9, 22)
			var width := randf_range(8.5, 12.0)
			var depth := randf_range(8.5, 12.0)
			var palette := [Color(0.62, 0.53, 0.44), Color(0.72, 0.68, 0.59), Color(0.48, 0.52, 0.55), Color(0.77, 0.72, 0.62), Color(0.54, 0.42, 0.34)]
			_create_building(center, width, height, depth, palette[randi() % palette.size()])

	# Dashed lane markings and a small pedestrian crossing near the spawn.
	var road_paint := _mat(Color(0.82, 0.81, 0.75), 0.92)
	for dash in range(-9, 10):
		_box(self, Vector3(dash * 4.0, 0.075, 0), Vector3(2.0, 0.025, 0.13), road_paint)
		_box(self, Vector3(0, 0.075, dash * 4.0), Vector3(0.13, 0.025, 2.0), road_paint)
	for stripe_index in range(6):
		_box(self, Vector3(-3.0 + stripe_index * 1.2, 0.09, 5.1), Vector3(0.72, 0.035, 2.0), road_paint)

	# Simple street lamps add scale cues without expensive lighting effects.
	for lamp_index in range(12):
		var lamp := Node3D.new()
		lamp.position = Vector3(-72 + lamp_index * 13.0, 0, 7.2)
		add_child(lamp)
		_box(lamp, Vector3(0, 2.4, 0), Vector3(0.12, 4.8, 0.12), Color(0.18, 0.19, 0.2))
		_box(lamp, Vector3(0.55, 4.65, 0), Vector3(1.15, 0.12, 0.12), Color(0.18, 0.19, 0.2))
		_box(lamp, Vector3(1.05, 4.55, 0), Vector3(0.45, 0.18, 0.34), Color(0.92, 0.82, 0.58))
	_box(self, Vector3(0, -0.2, -132), Vector3(260, 0.2, 20), Color(0.12, 0.34, 0.48))
	_box(self, Vector3(-28, 0.08, 28), Vector3(17, 0.18, 18), Color(0.18, 0.38, 0.2))
	for i in range(18):
		var tree := Node3D.new()
		tree.position = Vector3(randf_range(-35, -21), 0, randf_range(20, 36))
		add_child(tree)
		_box(tree, Vector3(0, 1.5, 0), Vector3(0.35, 3, 0.35), Color(0.25, 0.16, 0.1))
		var crown := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		crown.mesh = sphere
		crown.position.y = 3.5
		crown.scale = Vector3(1.5, 1.8, 1.5)
		crown.material_override = _mat(Color(0.12, 0.32, 0.16))
		tree.add_child(crown)
	var shop := Area3D.new()
	shop.position = shop_position + Vector3(0, 1, 0)
	shop.name = "Mahalle Marketi"
	add_child(shop)
	var shop_collision := CollisionShape3D.new()
	var shop_shape := BoxShape3D.new()
	shop_shape.size = Vector3(5, 3, 4)
	shop_collision.shape = shop_shape
	shop.add_child(shop_collision)
	_box(self, shop_position + Vector3(0, 1.8, -1), Vector3(5, 3.6, 0.45), Color(0.72, 0.57, 0.36))
	_box(self, shop_position + Vector3(0, 3.75, -1), Vector3(5.2, 0.45, 0.5), Color(0.72, 0.04, 0.04))
	var mosque := Node3D.new()
	mosque.position = Vector3(38, 0, -38)
	add_child(mosque)
	_box(mosque, Vector3(0, 2, 0), Vector3(12, 4, 10), Color(0.76, 0.72, 0.62))
	var dome := MeshInstance3D.new()
	var dome_mesh := SphereMesh.new()
	dome.mesh = dome_mesh
	dome.scale = Vector3(3.8, 2, 3.8)
	dome.position.y = 5
	dome.material_override = _mat(Color(0.55, 0.58, 0.56))
	mosque.add_child(dome)
	for x in [-5, 5]:
		var minaret := MeshInstance3D.new()
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 0.22
		cylinder.bottom_radius = 0.42
		cylinder.height = 13
		minaret.mesh = cylinder
		minaret.position = Vector3(x, 6.5, 0)
		minaret.material_override = _mat(Color(0.8, 0.76, 0.67))
		mosque.add_child(minaret)


func _spawn_asset(file_name: String, world_position: Vector3, model_scale: float = 1.0, yaw: float = 0.0) -> Node3D:
	var packed := load("res://assets/" + file_name) as PackedScene
	if packed == null:
		push_warning("3D asset could not be loaded: " + file_name)
		return null
	var instance := packed.instantiate() as Node3D
	if instance == null:
		push_warning("3D asset root is not Node3D: " + file_name)
		return null
	instance.position = world_position
	instance.rotation.y = yaw
	instance.scale = Vector3.ONE * model_scale
	instance.name = file_name.get_basename().replace("-", "_")
	add_child(instance)
	return instance


func _spawn_environment_assets() -> void:
	# Two extra parked vehicles add variety while keeping the player's pickup unique.
	_spawn_asset("1950s-roadster.glb", Vector3(-7.0, 0.0, 7.5), 1.0, PI * 0.5)
	_spawn_asset("1990s-taxi.glb", Vector3(9.0, 0.0, -7.5), 1.0, -PI * 0.5)

	# A compact traffic island on a distant four-way intersection.
	_spawn_asset("roundabout-light.glb", Vector3(-48.0, 0.02, -48.0), 0.8, 0.0)

	# Street-side construction details and barriers.
	for index in range(4):
		_spawn_asset("concrete-barrier.glb", Vector3(20.0 + index * 2.5, 0.0, 18.0), 0.9, PI * 0.5)
	for index in range(2):
		_spawn_asset("construction-barrier.glb", Vector3(17.0 + index * 4.0, 0.0, 21.0), 0.85, PI * 0.5)

	# Fencing and brick boundary around the small green area.
	_spawn_asset("brick-wall.glb", Vector3(-36.0, 0.0, 19.0), 0.8, 0.0)
	_spawn_asset("brick-wall.glb", Vector3(-36.0, 0.0, 31.0), 0.8, 0.0)
	_spawn_asset("chain-link-fence-light.glb", Vector3(-19.0, 0.0, 22.0), 0.8, PI * 0.5)
	_spawn_asset("chain-link-fence-light.glb", Vector3(-19.0, 0.0, 31.0), 0.8, PI * 0.5)

	# Hydrants are spaced along sidewalks instead of clustered together.
	for hydrant_position in [
		Vector3(-8.0, 0.0, 8.5),
		Vector3(14.0, 0.0, -8.5),
		Vector3(-31.0, 0.0, 7.5),
		Vector3(31.0, 0.0, 7.5)
	]:
		_spawn_asset("fire-hydrant.glb", hydrant_position, 0.7, 0.0)

	# A directional street marker at the nearby junction.
	_spawn_asset("direction-arrow.glb", Vector3(5.5, 0.0, -5.5), 0.8, PI * 0.25)

func _multi_boxes(parent: Node3D, size: Vector3, material: Material, transforms: Array[Transform3D]) -> void:
	if transforms.is_empty():
		return
	var mesh := BoxMesh.new()
	mesh.size = size
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.mesh = mesh
	instances.instance_count = transforms.size()
	for index in range(transforms.size()):
		instances.set_instance_transform(index, transforms[index])
	var node := MultiMeshInstance3D.new()
	node.multimesh = instances
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(node)

func _create_building(center: Vector3, width: float, height: float, depth: float, wall_color: Color) -> void:
	var building := StaticBody3D.new()
	building.position = center
	add_child(building)
	_box(building, Vector3(0, height * 0.5, 0), Vector3(width, height, depth), wall_color)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(width, height, depth)
	collision.shape = shape
	collision.position.y = height * 0.5
	building.add_child(collision)

	# Repeated facade details are batched into MultiMeshes: far fewer draw calls
	# than creating an individual MeshInstance for every window and railing.
	var glass := _mat(Color(0.075, 0.16, 0.22), 0.24)
	var frame := _mat(Color(0.18, 0.19, 0.18), 0.68)
	var balcony := _mat(Color(0.36, 0.35, 0.32), 0.76)
	var floors := max(2, int(height / 3.1))
	var glass_transforms: Array[Transform3D] = []
	var frame_transforms: Array[Transform3D] = []
	var sill_transforms: Array[Transform3D] = []
	var rail_transforms: Array[Transform3D] = []
	for floor_index in range(floors):
		var y := 1.55 + floor_index * 3.05
		for column in range(2):
			var x := -width * 0.25 if column == 0 else width * 0.25
			var front_z := -depth * 0.5 - 0.045
			glass_transforms.append(Transform3D(Basis(), Vector3(x, y, front_z)))
			frame_transforms.append(Transform3D(Basis(), Vector3(x - 0.72, y, front_z - 0.018)))
			frame_transforms.append(Transform3D(Basis(), Vector3(x + 0.72, y, front_z - 0.018)))
			frame_transforms.append(Transform3D(Basis(), Vector3(x, y + 0.78, front_z - 0.018)))
			frame_transforms.append(Transform3D(Basis(), Vector3(x, y - 0.78, front_z - 0.018)))
			sill_transforms.append(Transform3D(Basis(), Vector3(x, y - 0.86, front_z - 0.05)))
			rail_transforms.append(Transform3D(Basis(), Vector3(x, y - 0.52, front_z - 0.10)))
			for rail_x in [-0.68, 0.0, 0.68]:
				rail_transforms.append(Transform3D(Basis(), Vector3(x + rail_x, y - 0.52, front_z - 0.12)))
	_multi_boxes(building, Vector3(1.25, 1.35, 0.045), glass, glass_transforms)
	_multi_boxes(building, Vector3(0.045, 1.52, 0.07), frame, frame_transforms)
	_multi_boxes(building, Vector3(1.52, 0.075, 0.15), balcony, sill_transforms)
	_multi_boxes(building, Vector3(1.48, 0.055, 0.06), balcony, rail_transforms)

	# A contrasting ground floor and restrained sign panel make blocks read as
	# occupied Turkish neighbourhood buildings rather than plain cubes.
	_box(building, Vector3(0, 0.72, -depth * 0.5 - 0.035), Vector3(width * 0.82, 1.35, 0.10), _mat(wall_color.darkened(0.22)))
	_box(building, Vector3(0, 1.52, -depth * 0.5 - 0.10), Vector3(width * 0.48, 0.22, 0.06), _mat(Color(0.72, 0.12, 0.075), 0.6))

	# Roof parapet and a small water tank vary the skyline.
	for side in [-1, 1]:
		_box(building, Vector3(side * width * 0.5, height + 0.22, 0), Vector3(0.18, 0.44, depth + 0.20), wall_color.darkened(0.14))
		_box(building, Vector3(0, height + 0.22, side * depth * 0.5), Vector3(width + 0.20, 0.44, 0.18), wall_color.darkened(0.14))
	if height > 13.0:
		var tank := MeshInstance3D.new()
		var tank_mesh := CylinderMesh.new()
		tank_mesh.top_radius = 0.62
		tank_mesh.bottom_radius = 0.68
		tank_mesh.height = 1.35
		tank.mesh = tank_mesh
		tank.position = Vector3(width * 0.22, height + 0.92, depth * 0.18)
		tank.material_override = _mat(Color(0.25, 0.30, 0.32), 0.5)
		building.add_child(tank)

func _spawn_player() -> void:
	player = PlayerScript.new()
	player.name = "AnaKarakter"
	player.position = Vector3(0, 0, 4)
	add_child(player)

func _spawn_traffic() -> void:
	# Keep traffic on the actual road grid instead of spawning inside buildings.
	for i in range(6):
		var car = VehicleScript.new()
		var along := randf_range(-100.0, 100.0)
		var lane := randf_range(-1.8, 1.8)
		var road_index := randi_range(-4, 4)
		if randf() < 0.5:
			car.position = Vector3(along, 0.0, road_index * 24.0 + lane)
			car.rotation.y = 0.0 if randf() < 0.5 else PI
		else:
			car.position = Vector3(road_index * 24.0 + lane, 0.0, along)
			car.rotation.y = PI / 2.0 if randf() < 0.5 else -PI / 2.0
		add_child(car)


func _spawn_player_vehicle() -> void:
	# The user's 1950s pickup is parked beside the starting point and is
	# immediately available as the player's personal vehicle.
	var pickup = VehicleScript.new()
	pickup.name = "Oyuncunun 1950ler Pickup Araci"
	pickup.position = Vector3(3.2, 0.0, 4.0)
	pickup.rotation.y = 0.0
	add_child(pickup)


func _spawn_npcs() -> void:
	# Pedestrians start on sidewalks/road edges, not inside apartment collision.
	for i in range(14):
		var npc = NPCScript.new()
		var along := randf_range(-100.0, 100.0)
		var road_index := randi_range(-4, 4)
		if randf() < 0.5:
			npc.position = Vector3(along, 0.0, road_index * 24.0 + randf_range(-3.0, 3.0))
		else:
			npc.position = Vector3(road_index * 24.0 + randf_range(-3.0, 3.0), 0.0, along)
		add_child(npc)

func _setup_hud() -> void:
	hud = CanvasLayer.new()
	add_child(hud)
	var panel := ColorRect.new()
	panel.position = Vector2(18, 16)
	panel.size = Vector2(300, 112)
	panel.color = Color(0.02, 0.025, 0.03, 0.78)
	hud.add_child(panel)
	info = Label.new()
	info.position = Vector2(32, 24)
	info.add_theme_font_size_override("font_size", 18)
	info.add_theme_color_override("font_color", Color(1, 1, 1))
	hud.add_child(info)
	var controls := Label.new()
	controls.text = "WASD Hareket  |  SHIFT Koş  |  SPACE Zıpla\nE Etkileşim / Araca bin  |  TAB Envanter\nP Telefon  |  M Harita  |  ESC Fareyi bırak"
	controls.position = Vector2(20, 620)
	controls.add_theme_font_size_override("font_size", 15)
	controls.add_theme_color_override("font_color", Color(1, 1, 1))
	hud.add_child(controls)
	var title := Label.new()
	title.text = "İSTANBUL  •  YENİ BİR HAYAT"
	title.position = Vector2(850, 22)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1, 1, 1))
	hud.add_child(title)

func _process(delta: float) -> void:
	day_time = fmod(day_time + delta * 0.025, 24.0)
	if not is_instance_valid(player):
		return
	var time_text := "%02d:%02d" % [int(day_time), int(fposmod(day_time * 60, 60))]
	info.text = "₺ %s\nSağlık: %d   Aranma: %s\nSaat: %s\nGörev: Mahalle marketine git" % [str(money), player.health, "★".repeat(wanted), time_text]
	var near_car = null
	for child in get_children():
		if child is CharacterBody3D and child != player and child.get_script() == VehicleScript and child.global_position.distance_to(player.global_position) < 4.0:
			near_car = child
			break
	nearby_vehicle = near_car
	var e_down := Input.is_key_pressed(KEY_E)
	if e_down and not e_was_down:
		if player.driving:
			_exit_vehicle()
		elif near_car:
			_enter_vehicle(near_car)
		elif player.global_position.distance_to(shop_position) < 8.0:
			_shop_interaction()
		elif mission_stage == 0 and player.global_position.distance_to(Vector3(38, 0, -38)) < 9.0:
			_complete_mission()
	e_was_down = e_down

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB:
			inventory_open = not inventory_open
			_popup("ENVANTER\nTelefon • Anahtar • Kozmetik\nŞimdilik temel envanter prototipi" if inventory_open else "")
		elif event.keycode == KEY_P:
			phone_open = not phone_open
			_popup("TELEFON\nHarita • Mesajlar • Görevler • Para: ₺%d" % money if phone_open else "")
		elif event.keycode == KEY_M:
			_popup("HARİTA\nMerkez: Başlangıç Meydanı\nKuzey: Sahil\nDoğu: Eski Mahalle\nGüney: Sanayi")
		elif event.keycode == KEY_F5:
			_save_game()
			_popup("Oyun kaydedildi.")
		elif event.keycode == KEY_F9:
			_load_game()
			_popup("Kayıt yüklendi.")

func _popup(message: String) -> void:
	var old = hud.get_node_or_null("Popup")
	if old:
		old.queue_free()
	if message.is_empty():
		return
	var panel := Panel.new()
	panel.name = "Popup"
	panel.position = Vector2(420, 230)
	panel.size = Vector2(440, 190)
	panel.modulate = Color(1, 1, 1, 0.96)
	hud.add_child(panel)
	var label := Label.new()
	label.text = message
	label.position = Vector2(20, 20)
	label.size = Vector2(400, 150)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 20)
	panel.add_child(label)

func _enter_vehicle(car) -> void:
	player.driving = true
	player.current_vehicle = car
	car.occupied = true
	car.driver = player
	player.visible = false
	_popup("Araca bindin. WASD sürüş, SPACE el freni, E in.")

func _exit_vehicle() -> void:
	var car = player.current_vehicle
	if is_instance_valid(car):
		car.occupied = false
		car.speed = 0
		player.global_position = car.global_position + car.global_transform.basis.x * 2.0
	player.driving = false
	player.current_vehicle = null
	player.visible = true
	_popup("Araçtan indin.")

func _shop_interaction() -> void:
	if money >= 100:
		money -= 100
		_popup("MAHALLE MARKETİ\nSu satın aldın: ₺100\nKalan para: ₺%d" % money)
	else:
		_popup("Yeterli paran yok.")

func _complete_mission() -> void:
	mission_stage = 1
	money += mission_reward
	_popup("GÖREV TAMAMLANDI\nMahalleye hoş geldin!\nÖdül: ₺%d" % mission_reward)

func _save_game() -> void:
	var data := {"money": money, "wanted": wanted, "mission_stage": mission_stage, "player_position": [player.global_position.x, player.global_position.y, player.global_position.z]}
	var file := FileAccess.open("user://savegame.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func _load_game() -> void:
	if not FileAccess.file_exists("user://savegame.json"):
		return
	var file := FileAccess.open("user://savegame.json", FileAccess.READ)
	if not file:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		money = int(parsed.get("money", money))
		wanted = int(parsed.get("wanted", 0))
		mission_stage = int(parsed.get("mission_stage", 0))
		var saved_position = parsed.get("player_position", [0, 0, 4])
		if saved_position.size() == 3:
			player.global_position = Vector3(saved_position[0], saved_position[1], saved_position[2])
