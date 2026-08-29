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
		powder.albedo_color = Color("#9fbec5")
		powder.roughness = .96
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

func grow(delta: float, plant_age: float) -> void:
	age = plant_age - birth_time
	set_meta("age", age)
	if mesh_instance == null: return
	_apply_growth_shape()
	var radial := 0.0
	var lift := 0.0
	var target_open := 0.0
	var target_scale := Vector3.ONE
	if age < 2.25:
		ring = 0
		radial_index = smoothstep(0.0, 2.25, age)
		radial = lerp(.012, .075, radial_index)
		lift = lerp(.28, .20, radial_index)
		target_open = lerp(.28, .56, radial_index)
		target_scale = Vector3(1.34, 1.26, 1.34)
	elif age < 5.5:
		ring = 1
		radial_index = smoothstep(2.25, 5.5, age)
		radial = lerp(.075, .20, radial_index)
		lift = lerp(.18, .085, radial_index)
		target_open = lerp(.56, .98, radial_index)
		target_scale = Vector3(1.62, 1.54, 1.58)
	else:
		ring = 2
		radial_index = smoothstep(5.5, 13.5, age)
		radial = lerp(.20, .46, radial_index)
		lift = lerp(.024, .002, radial_index)
		target_open = lerp(.98, 1.34, radial_index)
		target_scale = Vector3(1.92, 1.82, 1.88)
	set_meta("ring", ring)
	set_meta("radial_index", radial_index)
	position = position.lerp(Vector3(sin(azimuth) * radial, lift, cos(azimuth) * radial), min(delta * 2.2, 1.0))
	if seed_pair and age < 1.8:
		target_open = lerp(.58, target_open, smoothstep(0.75, 1.8, age))
	rotation.x = lerp(rotation.x, target_open, min(delta * 2.0, 1.0))
	rotation.z = sin(age * 1.15 + float(order) * .71) * .008 if ring == 0 else 0.0
	scale = scale.lerp(target_scale, min(delta * 1.8, 1.0))

func _apply_growth_shape() -> void:
	var young := 0.0
	var mid := 0.0
	var mature := 0.0
	if age < 1.6:
		young = smoothstep(0.0, 1.6, age)
	elif age < 3.8:
		var t := smoothstep(1.6, 3.8, age)
		young = 1.0 - t
		mid = t
	else:
		var t := smoothstep(3.8, 7.0, age)
		mid = 1.0 - t
		mature = t
	mesh_instance.set_blend_shape_value(0, young)
	mesh_instance.set_blend_shape_value(1, mid)
	mesh_instance.set_blend_shape_value(2, mature)
