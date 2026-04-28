extends Node

# Types: normal | electric | fire | water | grass
const MONSTERS := {
	"pikachu": {
		"display_name": "Pikachu",
		"type": "electric",
		"max_hp": 35,
		"moves": ["thunderbolt", "quick_attack", "thunder_wave", "recover"],
		"sprite": "res://assets/pikachu_down.png",
	},
	"volty": {
		"display_name": "Volty",
		"type": "electric",
		"max_hp": 28,
		"moves": ["spark", "tackle"],
		"sprite": "res://assets/enemy_volty.png",
	},
	"twigling": {
		"display_name": "Twigling",
		"type": "grass",
		"max_hp": 32,
		"moves": ["vine_lash", "tackle", "sleep_powder"],
		"sprite": "res://assets/enemy_twigling.png",
	},
	"embertail": {
		"display_name": "Embertail",
		"type": "fire",
		"max_hp": 30,
		"moves": ["ember", "scratch", "flame_touch"],
		"sprite": "res://assets/enemy_embertail.png",
	},
}

const WILD_POOL := ["volty", "twigling", "embertail"]
