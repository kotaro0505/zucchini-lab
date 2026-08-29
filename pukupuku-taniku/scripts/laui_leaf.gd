class_name LauiGrowthLeaf
extends Node3D

const LEAF_SCENE: PackedScene = preload("res://assets/models/laui_leaf_final_candidate.glb")

var birth_time := 0.0
var age := 0.0
var order := 0
var azimuth := 0.0
var mesh_instance: MeshInstance3D
var seed_pair := false
var ring := 0
var radial_index := 0.0

func setup(created_at: float, leaf_order: int, is_seed_pair := false) -> void:
	birth_time = created_at
	order = leaf_order
	seed_pair = is_seed_pair
	azimuth = float(order) * PI if seed_pair else deg_to_rad(137.507764 * float(order))
	set_meta("birth_time", birth_time)
	set_meta("age", age)
	var imported := LEAF_SCENE.instantiate()
	add_child(imported)
	if imported is MeshInstance3D:
		mesh_instance = imported as MeshInstance3D
	else:
		mesh_instance = imported.find_child("LauiLeaf", true, false) as MeshInstance3D
	if mesh_instance == null:
		mesh_instance = _find_mesh(imported)
	if mesh_instance != null:
		var powder := StandardMaterial3D.new()
		powder.albedo_color = Color("#789ba5")
		powder.roughness = .90
		powder.metallic = 0.0
		mesh_instance.material_override = powder
	# The imported leaf grows from its broad local base toward its pointed tip.
	# Face the tip away from the crown so every generation overlaps at the base.
	rotation.y = azimuth + PI

func _find_mesh(node: Node) -> MeshInstance3D:
	for child in node.get_children():
		if child is MeshInstance3D: return child as MeshInstance3D
		var nested := _find_mesh(child)
		if nested != null: return nested
	return null

func grow(delta: float, plant_age: float, total_leaves: int) -> void:
	age = plant_age - birth_time
	set_meta("age", age)
	if mesh_instance == null: return
	# A leaf's visual generation is its rank from the living crown, not age alone.
	# This keeps a packed young center even after a rare plant has lived for minutes.
	var generation_rank := maxi(0, total_leaves - 1 - order)
	var giant_factor := 1.0 + maxf(0.0, plant_age - 10.0) * .032
	var radial := 0.0
	var lift := 0.0
	var target_open := 0.0
	var target_scale := Vector3.ONE
	if generation_rank < 7:
		ring = 0
		radial_index = float(generation_rank) / 6.0
		radial = lerp(.012, .11, radial_index) * giant_factor
		lift = lerp(.52, .34, radial_index) * sqrt(giant_factor)
		target_open = lerp(.46, .72, radial_index)
		target_scale = Vector3(lerp(.46, .92, radial_index), lerp(.42, .84, radial_index), lerp(.58, 1.02, radial_index))
	elif generation_rank < 16:
		ring = 1
		radial_index = float(generation_rank - 7) / 8.0
		radial = lerp(.24, .62, radial_index) * giant_factor
		lift = lerp(.085, .025, radial_index) * sqrt(giant_factor)
		target_open = lerp(.94, 1.24, radial_index)
		target_scale = Vector3(lerp(.82, 1.18, radial_index), lerp(.76, 1.08, radial_index), lerp(.92, 1.26, radial_index))
	else:
		ring = 2
		radial_index = float(generation_rank - 16) / maxf(1.0, float(total_leaves - 17))
		radial = lerp(.34, .82, radial_index) * giant_factor
		lift = lerp(.024, .002, radial_index)
		target_open = lerp(1.04, 1.37, radial_index)
		target_scale = Vector3(lerp(1.36, 1.88, radial_index), lerp(1.24, 1.68, radial_index), lerp(1.46, 1.92, radial_index)) * pow(giant_factor, .82)
	var shape_age := age if ring == 2 else (3.0 if ring == 1 else 1.4)
	_apply_growth_shape(shape_age)
	var birth_open := smoothstep(0.0, 1.35, maxf(age, 0.0))
	target_scale *= lerp(.26, 1.0, birth_open)
	set_meta("ring", ring)
	set_meta("radial_index", radial_index)
	position = position.lerp(Vector3(sin(azimuth) * radial, lift, cos(azimuth) * radial), min(delta * 2.2, 1.0))
	if seed_pair and age < 1.8:
		target_open = lerp(.84, target_open, smoothstep(0.75, 1.8, age))
	rotation.x = lerp(rotation.x, target_open, min(delta * 2.0, 1.0))
	rotation.z = sin(age * 1.15 + float(order) * .71) * .008 if ring == 0 else 0.0
	scale = scale.lerp(target_scale, min(delta * 1.8, 1.0))

func _apply_growth_shape(shape_age: float) -> void:
	var young := 0.0
	var mid := 0.0
	var mature := 0.0
	if shape_age < 1.6:
		young = smoothstep(0.0, 1.6, shape_age)
	elif shape_age < 3.8:
		var t := smoothstep(1.6, 3.8, shape_age)
		young = 1.0 - t
		mid = t
	else:
		var t := smoothstep(3.8, 7.0, shape_age)
		mid = 1.0 - t
		mature = t
	mesh_instance.set_blend_shape_value(0, young)
	mesh_instance.set_blend_shape_value(1, mid)
	mesh_instance.set_blend_shape_value(2, mature)
