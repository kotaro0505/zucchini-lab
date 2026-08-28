extends Node
func _ready()->void:
	var scene:PackedScene=load("res://main.tscn");var game:Node=scene.instantiate();add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	assert(game.plants.size()==10)
	for plant in game.plants:plant.max_life_hint=100000.0
	var initial_count:int=game.plants.size()
	var harvest_target:Succulent=game.plants[0];var species_id:String=harvest_target.data.species_id;harvest_target.diameter_cm=21.7;harvest_target.harvest()
	await get_tree().create_timer(1.2).timeout
	assert(float(game.bests.get(species_id,0.0))>=21.7)
	assert(game.plants.size()==initial_count)
	var jelly_target:Succulent=game.plants[0];jelly_target.jelly()
	await get_tree().create_timer(1.2).timeout
	assert(game.plants.size()==initial_count)
	print("SMOKE_OK one_out_one_in plants=",game.plants.size()," best=",game.bests.get(species_id)," species=",species_id)
	get_tree().quit()
