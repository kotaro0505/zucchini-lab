class_name Succulent
extends Node3D

signal harvested(plant: Succulent)
signal jellied(plant: Succulent)

const GrowthLeaf = preload("res://scripts/laui_leaf.gd")
const MAX_LEAVES := 52
const LEAF_INTERVAL := 0.66

var data: Dictionary
var age := 0.0
var diameter_cm := 1.6
var growth_rate := 1.0
var state := "growing"
var original_pos := Vector3.ZERO
var target_offset := Vector3.ZERO
var rng := RandomNumberGenerator.new()
var label: Label
var visual_scale := 0.38
var leaves: Array[LauiGrowthLeaf] = []
var next_leaf_time := 0.0

func setup(species: Dictionary, seed_value: int, screen_label: Label, _danger: Label) -> void:
	data = species
	rng.seed = seed_value
	label = screen_label
	growth_rate = float(data.base_growth_rate)
	for i in range(2): _add_leaf(-.72, true)
	next_leaf_time = .64

func _add_leaf(created_at: float = age, is_seed_pair := false) -> void:
	if leaves.size() >= MAX_LEAVES: return
	var leaf := GrowthLeaf.new() as LauiGrowthLeaf
	add_child(leaf)
	leaf.setup(created_at, leaves.size(), is_seed_pair)
	leaves.append(leaf)

func simulate(delta: float) -> void:
	if state != "growing": return
	age += delta
	while age >= next_leaf_time and leaves.size() < MAX_LEAVES:
		_add_leaf(next_leaf_time)
		next_leaf_time += .46 if age >= 7.0 else LEAF_INTERVAL
	for leaf in leaves: leaf.grow(delta, age, leaves.size())
	var spread: float = age / 16.0
	diameter_cm = 1.6 + spread * 19.0 + max(0, leaves.size() - 20) * .235
	visual_scale = .42 + spread * 2.35
	position += (original_pos + target_offset - position) * min(delta * 1.8, 1.0)

func get_risk_percent() -> float: return 0.0

func harvest() -> void:
	if state != "growing": return
	state = "harvested"
	harvested.emit(self)

func jelly() -> void:
	if state != "growing": return
	state = "jelly"
	jellied.emit(self)

func hit_radius() -> float: return max(.45, visual_scale)
