extends RefCounted
## Kenney CC0 place dressing for the unofficial Artifacts 3D client.
## Nature: https://kenney.nl/assets/nature-kit
## Castle: https://kenney.nl/assets/castle-kit
## Furniture: https://kenney.nl/assets/furniture-kit
## Licenses: res://assets/licenses/

const NATURE_DIR := "res://assets/kenney/nature/"
const FURNITURE_DIR := "res://assets/kenney/furniture/"
const CASTLE_DIR := "res://assets/kenney/castle/"

var _scenes: Dictionary = {}
var _failed: Dictionary = {}


func try_instance(path: String, scale: float = 1.0, y_offset: float = 0.0) -> Node3D:
	return try_instance_dir(NATURE_DIR, path, scale, y_offset)


func try_instance_dir(dir_path: String, file_name: String, scale: float = 1.0, y_offset: float = 0.0) -> Node3D:
	var scene := _load_scene_path(dir_path + file_name)
	if scene == null:
		return null
	var node := scene.instantiate()
	if not (node is Node3D):
		if node:
			node.queue_free()
		return null
	var root := node as Node3D
	root.scale = Vector3.ONE * scale
	root.position.y = y_offset
	root.rotation_degrees.y = randf() * 360.0
	return root


func tree(seed_key: int = 0) -> Node3D:
	var paths := [
		"tree_default.glb", "tree_oak.glb", "tree_tall.glb", "tree_simple.glb",
		"tree_detailed.glb", "tree_pineDefaultA.glb", "tree_pineTallA.glb",
		"tree_pineSmallA.glb", "tree_pineRoundA.glb", "tree_small.glb", "tree_cone.glb",
	]
	return try_instance(_pick(paths, seed_key), 0.55 + _frac(seed_key) * 0.35)


func pine(seed_key: int = 0) -> Node3D:
	var paths := [
		"tree_pineTallA.glb", "tree_pineDefaultA.glb", "tree_pineSmallA.glb",
		"tree_pineRoundA.glb", "tree_cone.glb",
	]
	return try_instance(_pick(paths, seed_key), 0.6 + _frac(seed_key) * 0.4)


func rock(seed_key: int = 0) -> Node3D:
	var paths := [
		"rock_largeA.glb", "rock_largeB.glb", "rock_smallA.glb", "rock_smallB.glb",
		"rock_tallA.glb", "stone_tallA.glb", "stone_smallA.glb",
	]
	return try_instance(_pick(paths, seed_key), 0.45 + _frac(seed_key) * 0.4)


func bush(seed_key: int = 0) -> Node3D:
	var paths := ["plant_bush.glb", "plant_bushDetailed.glb", "plant_bushLarge.glb"]
	return try_instance(_pick(paths, seed_key), 0.7 + _frac(seed_key) * 0.4)


func grass(seed_key: int = 0) -> Node3D:
	var paths := ["grass_large.glb", "grass.glb", "flower_purpleA.glb", "flower_redA.glb"]
	return try_instance(_pick(paths, seed_key), 0.8 + _frac(seed_key) * 0.5)


func campfire(seed_key: int = 0) -> Node3D:
	return try_instance("campfire_stones.glb", 0.9 + _frac(seed_key) * 0.2)


func tent(seed_key: int = 0) -> Node3D:
	var paths := ["tent_detailedOpen.glb", "tent_smallOpen.glb"]
	return try_instance(_pick(paths, seed_key), 0.85)


func path_stone(seed_key: int = 0) -> Node3D:
	return try_instance("path_stone.glb", 0.9, 0.01)


func crop(seed_key: int = 0) -> Node3D:
	return try_instance("crop_carrot.glb", 0.9 + _frac(seed_key) * 0.3)


func bank_building(seed_key: int = 0) -> Node3D:
	## Tall vault tower + teller desk — blue/stone bank silhouette.
	var root := Node3D.new()
	var tower := try_instance_dir(CASTLE_DIR, "tower-square-base.glb", 0.52)
	if tower:
		_freeze_yaw(tower)
		root.add_child(tower)
	var mid := try_instance_dir(CASTLE_DIR, "tower-square-mid-door.glb", 0.52, 0.52)
	if mid:
		_freeze_yaw(mid)
		root.add_child(mid)
	var top := try_instance_dir(CASTLE_DIR, "tower-square-mid.glb", 0.52, 1.04)
	if top:
		_freeze_yaw(top)
		root.add_child(top)
	var roof := try_instance_dir(CASTLE_DIR, "tower-square-top-roof.glb", 0.52, 1.56)
	if roof:
		_freeze_yaw(roof)
		root.add_child(roof)
	var gate := try_instance_dir(CASTLE_DIR, "wall-narrow-gate.glb", 0.42)
	if gate:
		_freeze_yaw(gate)
		gate.position = Vector3(0.0, 0.0, 0.72)
		root.add_child(gate)
	var vault := try_instance_dir(FURNITURE_DIR, "bookcaseClosedDoors.glb", 0.42)
	if vault == null:
		vault = try_instance_dir(FURNITURE_DIR, "bookcaseClosed.glb", 0.42)
	if vault:
		_freeze_yaw(vault)
		vault.position = Vector3(-0.55, 0.0, 0.2)
		root.add_child(vault)
	var desk := try_instance_dir(FURNITURE_DIR, "desk.glb", 0.4)
	if desk:
		_freeze_yaw(desk)
		desk.position = Vector3(0.58, 0.0, 0.4)
		root.add_child(desk)
	var drawers := try_instance_dir(FURNITURE_DIR, "sideTableDrawers.glb", 0.4)
	if drawers:
		_freeze_yaw(drawers)
		drawers.position = Vector3(0.55, 0.0, -0.25)
		root.add_child(drawers)
	_add_place_banner(root, Color(0.28, 0.48, 0.95), Vector3(0.0, 2.05, 0.4))
	if root.get_child_count() == 0:
		root.queue_free()
		return null
	root.rotation_degrees.y = float(absi(seed_key) % 360)
	return root


func ge_building(seed_key: int = 0) -> Node3D:
	## Open market pavilion — wide windows, trading tables, warm lamps.
	var root := Node3D.new()
	var base := try_instance_dir(CASTLE_DIR, "tower-square-base-color.glb", 0.58)
	if base == null:
		base = try_instance_dir(CASTLE_DIR, "tower-square-base.glb", 0.58)
	if base:
		_freeze_yaw(base)
		root.add_child(base)
	var mid := try_instance_dir(CASTLE_DIR, "tower-square-mid-windows.glb", 0.58, 0.58)
	if mid == null:
		mid = try_instance_dir(CASTLE_DIR, "tower-square-mid.glb", 0.58, 0.58)
	if mid:
		_freeze_yaw(mid)
		root.add_child(mid)
	var roof := try_instance_dir(CASTLE_DIR, "tower-square-roof.glb", 0.58, 1.16)
	if roof == null:
		roof = try_instance_dir(CASTLE_DIR, "tower-square-top-roof.glb", 0.58, 1.16)
	if roof:
		_freeze_yaw(roof)
		root.add_child(roof)
	var wing := try_instance_dir(CASTLE_DIR, "wall-half.glb", 0.5)
	if wing:
		_freeze_yaw(wing)
		wing.position = Vector3(0.85, 0.0, 0.1)
		wing.rotation_degrees.y = 90.0
		root.add_child(wing)
	var table := try_instance_dir(FURNITURE_DIR, "tableRound.glb", 0.48)
	if table:
		_freeze_yaw(table)
		table.position = Vector3(0.7, 0.0, 0.45)
		root.add_child(table)
	var stall := try_instance_dir(FURNITURE_DIR, "deskCorner.glb", 0.42)
	if stall == null:
		stall = try_instance_dir(FURNITURE_DIR, "table.glb", 0.45)
	if stall:
		_freeze_yaw(stall)
		stall.position = Vector3(-0.65, 0.0, 0.4)
		root.add_child(stall)
	var lamp := try_instance_dir(FURNITURE_DIR, "lampRoundFloor.glb", 0.48)
	if lamp:
		_freeze_yaw(lamp)
		lamp.position = Vector3(-0.35, 0.0, 0.7)
		root.add_child(lamp)
	var lamp2 := try_instance_dir(FURNITURE_DIR, "lampSquareFloor.glb", 0.45)
	if lamp2:
		_freeze_yaw(lamp2)
		lamp2.position = Vector3(0.45, 0.0, 0.7)
		root.add_child(lamp2)
	_add_place_banner(root, Color(0.95, 0.78, 0.22), Vector3(0.0, 1.55, 0.45))
	if root.get_child_count() == 0:
		root.queue_free()
		return null
	root.rotation_degrees.y = float(absi(seed_key) % 360)
	return root


func workshop_building(seed_key: int = 0) -> Node3D:
	## Low craft shed — doorway wall, cabinets, workbench + chair.
	var root := Node3D.new()
	var wall := try_instance_dir(CASTLE_DIR, "wall-doorway.glb", 0.68)
	if wall:
		_freeze_yaw(wall)
		root.add_child(wall)
	var side := try_instance_dir(CASTLE_DIR, "wall.glb", 0.55)
	if side == null:
		side = try_instance_dir(CASTLE_DIR, "wall-half.glb", 0.55)
	if side:
		_freeze_yaw(side)
		side.position = Vector3(-0.7, 0.0, 0.0)
		side.rotation_degrees.y = 90.0
		root.add_child(side)
	var corner := try_instance_dir(CASTLE_DIR, "wall-corner.glb", 0.5)
	if corner:
		_freeze_yaw(corner)
		corner.position = Vector3(0.55, 0.0, -0.35)
		root.add_child(corner)
	var cabinet := try_instance_dir(FURNITURE_DIR, "kitchenCabinetDrawer.glb", 0.5)
	if cabinet == null:
		cabinet = try_instance_dir(FURNITURE_DIR, "kitchenCabinet.glb", 0.5)
	if cabinet:
		_freeze_yaw(cabinet)
		cabinet.position = Vector3(0.45, 0.0, 0.15)
		root.add_child(cabinet)
	var bench := try_instance_dir(FURNITURE_DIR, "desk.glb", 0.45)
	if bench:
		_freeze_yaw(bench)
		bench.position = Vector3(0.15, 0.0, 0.55)
		root.add_child(bench)
	var chair := try_instance_dir(FURNITURE_DIR, "chairDesk.glb", 0.45)
	if chair:
		_freeze_yaw(chair)
		chair.position = Vector3(0.15, 0.0, 0.85)
		root.add_child(chair)
	var books := try_instance_dir(FURNITURE_DIR, "bookcaseOpen.glb", 0.45)
	if books == null:
		books = try_instance_dir(FURNITURE_DIR, "books.glb", 0.5)
	if books:
		_freeze_yaw(books)
		books.position = Vector3(-0.4, 0.0, 0.1)
		root.add_child(books)
	_add_place_banner(root, Color(0.72, 0.48, 0.24), Vector3(0.0, 1.25, 0.35))
	if root.get_child_count() == 0:
		root.queue_free()
		return null
	root.rotation_degrees.y = float(absi(seed_key) % 360)
	return root


func npc_stall(seed_key: int = 0) -> Node3D:
	var root := Node3D.new()
	var shelter := try_instance_dir(NATURE_DIR, "tent_detailedOpen.glb", 0.75)
	if shelter == null:
		shelter = try_instance_dir(NATURE_DIR, "tent_smallOpen.glb", 0.75)
	if shelter:
		_freeze_yaw(shelter)
		root.add_child(shelter)
	var table := try_instance_dir(FURNITURE_DIR, "table.glb", 0.45)
	if table:
		_freeze_yaw(table)
		table.position = Vector3(0.35, 0.0, 0.4)
		root.add_child(table)
	var goods := try_instance_dir(FURNITURE_DIR, "books.glb", 0.4)
	if goods:
		_freeze_yaw(goods)
		goods.position = Vector3(0.35, 0.35, 0.4)
		root.add_child(goods)
	if root.get_child_count() == 0:
		root.queue_free()
		return null
	root.rotation_degrees.y = float(absi(seed_key) % 360)
	return root


func _freeze_yaw(node: Node3D) -> void:
	node.rotation_degrees.y = 0.0


func _add_place_banner(root: Node3D, color: Color, pos: Vector3) -> void:
	var pole := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.025
	cyl.bottom_radius = 0.03
	cyl.height = 0.55
	pole.mesh = cyl
	pole.position = pos
	var pole_mat := StandardMaterial3D.new()
	pole_mat.albedo_color = Color(0.25, 0.18, 0.12)
	pole.material_override = pole_mat
	root.add_child(pole)
	var flag := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.28, 0.18, 0.02)
	flag.mesh = box
	flag.position = pos + Vector3(0.14, 0.18, 0.0)
	var flag_mat := StandardMaterial3D.new()
	flag_mat.albedo_color = color
	flag_mat.emission_enabled = true
	flag_mat.emission = color
	flag_mat.emission_energy_multiplier = 0.55
	flag.material_override = flag_mat
	root.add_child(flag)


func _pick(paths: Array, seed_key: int) -> String:
	if paths.is_empty():
		return ""
	var count: int = paths.size()
	var idx: int = absi(seed_key) % count
	return str(paths[idx])


func _frac(seed_key: int) -> float:
	return float(absi(seed_key) % 1000) / 1000.0


func _load_scene(file_name: String) -> PackedScene:
	return _load_scene_path(NATURE_DIR + file_name)


func _load_scene_path(path: String) -> PackedScene:
	if path.is_empty():
		return null
	if _failed.has(path):
		return null
	if _scenes.has(path):
		return _scenes[path]
	if not ResourceLoader.exists(path):
		_failed[path] = true
		return null
	var packed: Resource = load(path)
	if packed is PackedScene:
		_scenes[path] = packed
		return packed as PackedScene
	_failed[path] = true
	return null
