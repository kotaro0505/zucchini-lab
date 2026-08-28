extends Node
func _ready()->void:
	var scene:PackedScene=load("res://main.tscn");var game:Node=scene.instantiate();add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	assert(game.plants.size()>=8)
	var harvest_target:Succulent=game.plants[0];var species_id:String=harvest_target.data.species_id;harvest_target.diameter_cm=21.7;harvest_target.harvest()
	await get_tree().create_timer(.15).timeout
	assert(float(game.bests.get(species_id,0.0))>=21.7)
	var jelly_target:Succulent=game.plants[0];jelly_target.jelly()
	await get_tree().create_timer(.15).timeout
	print("SMOKE_OK plants=",game.plants.size()," best=",game.bests.get(species_id)," species=",species_id)
	get_tree().quit()
