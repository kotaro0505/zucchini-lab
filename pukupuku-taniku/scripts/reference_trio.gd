extends Node3D
const SucculentClass=preload("res://scripts/succulent.gd")
func _ready()->void:
	var world:=WorldEnvironment.new();var env:=Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=Color("#17151b");env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("#9ba0a5");env.ambient_light_energy=.24;env.tonemap_mode=Environment.TONE_MAPPER_FILMIC;world.environment=env;add_child(world)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-42,-28,-8);sun.light_color=Color("#fff0d0");sun.light_energy=.54;sun.shadow_enabled=true;add_child(sun)
	var data:Array=JSON.parse_string(FileAccess.get_file_as_string("res://data/species-v2.json"));var ids:=["laui","golden_laui","affinis"]
	for i in range(ids.size()):
		var entry:Dictionary
		for candidate in data:
			if candidate.species_id==ids[i]:entry=candidate;break
		var plant:=SucculentClass.new() as Succulent;plant.position=Vector3((i-1)*3.1,0,0);plant.original_pos=plant.position;add_child(plant);plant.setup(entry,7100+i,null,null);plant.age=7;plant.diameter_cm=16;plant.max_life_hint=100000
	var camera:=Camera3D.new();camera.position=Vector3(0,7.0,14.0);camera.look_at_from_position(camera.position,Vector3(0,.25,0));camera.fov=43;camera.current=true;add_child(camera)
func _process(delta:float)->void:
	for child in get_children():
		if child is Succulent:child.simulate(delta*.025)
