@tool
extends Node

@export var coin_scene: PackedScene
@export var powerup_scene: PackedScene
@export var cactus_scene: PackedScene
@export var playtime := 30

var level := 1
var score := 0
var time_left := 0
var screensize:= Vector2.ZERO
var playing := false

func _ready() -> void:
	screensize = get_viewport().get_visible_rect().size
	var player_node = get_node("Player")  # Use get_node for safety
	if player_node:
		player_node.screensize = screensize
		player_node.hide()
		print("Player found",$Player)
	else:
		print("Player node not found!")
	
func _process(_delta: float) -> void:
	if playing and get_tree().get_nodes_in_group("coins").size() == 0:
		level += 1
		time_left += 5
		spawn_coins()
		spawn_obstacles()
		$PowerupTimer.wait_time = randi_range(0, 5)
		$PowerupTimer.start()

func _get_configuration_warnings() -> PackedStringArray:
	var warning: PackedStringArray = []
	
	if not coin_scene:
		warning.append("Coin Scene is not initialized.")
		
	if not powerup_scene:
		warning.append("Powerup Scene is not initialized.")
		
	if not cactus_scene:
		warning.append("Cactus Scene is not initialized.")
	
	return warning
	
func new_game():
	playing = true
	level = 1
	score = 0
	time_left = playtime
	$Player.start()
	$Player.show()
	$GameTimer.start()
	spawn_coins()
	$HUD.update_score(score)
	$HUD.update_timer(time_left)
	

	
func spawn_coins():
	var player_pos = $Player.position
	var min_distance = 50 
	for i in range(level + 4):
		var c := coin_scene.instantiate()
		add_child(c)
		c.screensize = screensize
		var valid_position = false
		while not valid_position:
			c.position = Vector2(randf_range(0, screensize.x), randf_range(0, screensize.y))
			if c.position.distance_to(player_pos) > min_distance:
				valid_position = true
	$LevelSound.play()

	
	
var min_safe_distance = 100
func spawn_obstacles():
	get_tree().call_group("obstacles", "queue_free")
	for i in range(level - 1):
		var c := cactus_scene.instantiate()
		add_child(c)
		var spawn_pos : Vector2
		while true:
			# Randomly generate cactus position
			spawn_pos = Vector2(
				randf_range(0, screensize.x),
				randf_range(0, screensize.y)
			)
			if spawn_pos.distance_to($Player.position) > min_safe_distance:
				break  
		c.position = spawn_pos

func game_over() -> void:
	playing = false
	$GameTimer.stop()
	get_tree().call_group("coins", "queue_free")
	get_tree().call_group("powerups", "queue_free")
	get_tree().call_group("obstacles", "queue_free")
	$HUD.show_game_over()
	$Player.die()
	$EndSound.play()

func _on_game_timer_timeout() -> void:
	time_left -= 1
	$HUD.update_timer(time_left)
	if time_left <= 0:
		game_over()


func _on_player_hurt() -> void:
	game_over()

func _on_player_pickup(type: String) -> void:
	match type:
		"coin":
			score += 1
			$HUD.update_score(score)
			$CoinSound.play()
		"powerup":
			time_left += 8
			$HUD.update_timer(time_left)
			$PowerupSound.play()

func _on_hud_start_game() -> void:
	new_game()

func _on_powerup_timer_timeout() -> void:
	var p := powerup_scene.instantiate()
	add_child(p)
	p.screensize = screensize
	p.position = Vector2(randf_range(0, screensize.x), randf_range(0, screensize.y))
