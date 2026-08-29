extends Node
func _ready()->void:
	var scene:PackedScene=load("res://main.tscn");var game:Node=scene.instantiate();add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	assert(game.plants.size()>=8 and game.plants.size()<=12)
	var initial_count:int=game.plants.size()
	var harvest_target:Succulent=game.plants[0]
	var initial_sprite_scale:float=harvest_target.plant_sprite.scale.x
	for i in range(120): harvest_target.simulate(.1)
	assert(harvest_target.plant_sprite.scale.x>initial_sprite_scale)
	assert(harvest_target.scale.is_equal_approx(Vector3.ONE))
	assert(harvest_target.plant_sprite.texture!=null)
	var grown_scale:float=harvest_target.plant_sprite.scale.x
	var species_id:String=harvest_target.data.species_id;harvest_target.diameter_cm=21.7;harvest_target.harvest()
	await get_tree().create_timer(1.2).timeout
	assert(float(game.bests.get(species_id,0.0))>=21.7)
	assert(game.plants.size()==initial_count)
	var jelly_target:Succulent=game.plants[0];jelly_target.jelly()
	await get_tree().create_timer(1.2).timeout
	assert(game.plants.size()==initial_count)
	print("SMOKE_OK one_out_one_in plants=",game.plants.size()," sprite_scale=",grown_scale," root_scale=1 species=",species_id)
	get_tree().quit()
