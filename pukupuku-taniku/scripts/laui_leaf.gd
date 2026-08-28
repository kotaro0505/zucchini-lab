class_name LauiGrowthLeaf
extends Node3D

const LEAF_SCENE: PackedScene = preload("res://assets/models/laui_leaf_final_candidate.glb")

var birth_time := 0.0
var age := 0.0
var order := 0
var azimuth := 0.0
var mesh_instance: MeshInstance3D

func setup(created_at: float, leaf_order: int) -> void:
	birth_time = created_at
	order = leaf_order
	azimuth = deg_to_rad(137.507764 * float(order))
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
	scale = Vector3.ONE * 1.65
	rotation.y = azimuth

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
	var maturity: float = clamp(age / 7.0, 0.0, 1.0)
	var radial: float = pow(maturity, 0.72) * .92
	var lift: float = lerp(0.10, 0.035, maturity)
	position = position.lerp(Vector3(sin(azimuth) * radial, lift, cos(azimuth) * radial), min(delta * 2.2, 1.0))
	var target_open: float = lerp(-0.72, -0.04, smoothstep(0.0, 1.0, maturity))
	rotation.x = lerp(rotation.x, target_open, min(delta * 2.0, 1.0))
	rotation.z = sin(age * 1.15 + float(order) * .71) * .012 * (1.0 - maturity)

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
