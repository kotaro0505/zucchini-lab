extends Node
func _ready()->void:
	var scene:PackedScene=load("res://main.tscn");var game:Node=scene.instantiate();add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	assert(game.plants.size()==5)
	for plant in game.plants:
		plant.jelly_threshold=1000000.0
	var initial_count:int=game.plants.size()
	var harvest_target=game.plants[0]
	harvest_target.jelly_threshold=1000000.0
	var rooted_position:Vector3=harvest_target.position
	var initial_sprite_scale:float=harvest_target.plant_sprite.scale.x
	for i in range(700): harvest_target.simulate(.1)
	assert(harvest_target.plant_sprite.scale.x>initial_sprite_scale)
	assert(harvest_target.diameter_cm>70.0)
	assert(harvest_target.position.is_equal_approx(rooted_position))
	assert(harvest_target.scale.is_equal_approx(Vector3.ONE))
	assert(harvest_target.plant_sprite.texture!=null)
	var grown_scale:float=harvest_target.plant_sprite.scale.x
	var grown_diameter:float=harvest_target.diameter_cm
	game.view_yaw=0.0;game._apply_view_rotation();var first_basis:Basis=game.camera.transform.basis
	game.view_yaw=360.0;game._apply_view_rotation();assert(game.camera.transform.basis.is_equal_approx(first_basis))
	var count_before_drag:int=game.plants.size();game._begin_pointer(Vector2(300,500));game._drag_pointer(Vector2(220,500),Vector2(-80,0));game._end_pointer(Vector2(220,500));assert(game.plants.size()==count_before_drag)
	var species_id:String=harvest_target.data.species_id;harvest_target.diameter_cm=21.7;harvest_target.harvest()
	await get_tree().create_timer(1.2).timeout
	assert(float(game.bests.get(species_id,0.0))>=21.7)
	assert(game.plants.size()==initial_count)
	var jelly_target=game.plants[0]
	jelly_target.jelly_threshold=0.0
	jelly_target.simulate(.1)
	assert(jelly_target.state=="jelly")
	await get_tree().create_timer(1.2).timeout
	assert(game.plants.size()==initial_count)
	print("SMOKE_OK panorama360 plants=",game.plants.size()," diameter=",grown_diameter," sprite_scale=",grown_scale," rooted=true species=",species_id)
	get_tree().quit()
