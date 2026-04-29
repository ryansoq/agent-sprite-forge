extends Node

# Types: normal | electric | fire | water | grass
const MONSTERS := {
	"pikachu": {
		"display_name": "Pikachu",
		"type": "electric",
		"max_hp": 35,
		"moves": ["thunderbolt", "quick_attack", "thunder_wave", "recover"],
		"learnset": {},
		"sprite": "res://assets/pikachu_down.png",
		"evolves_at": 8,
		"evolves_to": "raichu",
	},
	"raichu": {
		"display_name": "Raichu",
		"type": "electric",
		"max_hp": 50,
		"moves": ["thunderbolt", "quick_attack", "thunder_wave", "recover"],
		"learnset": {},
		"sprite": "res://assets/raichu.png",
	},
	"volty": {
		"display_name": "Volty",
		"type": "electric",
		"max_hp": 28,
		"moves": ["spark", "tackle"],
		"learnset": {7: "thunder_wave"},
		"sprite": "res://assets/enemy_volty.png",
	},
	"twigling": {
		"display_name": "Twigling",
		"type": "grass",
		"max_hp": 32,
		"moves": ["vine_lash", "tackle", "sleep_powder"],
		"learnset": {9: "pound"},
		"sprite": "res://assets/enemy_twigling.png",
	},
	"embertail": {
		"display_name": "Embertail",
		"type": "fire",
		"max_hp": 30,
		"moves": ["ember", "scratch", "flame_touch"],
		"learnset": {10: "quick_attack"},
		"sprite": "res://assets/enemy_embertail.png",
	},
	"aquillo": {
		"display_name": "Aquillo",
		"type": "water",
		"max_hp": 30,
		"moves": ["water_pulse", "tackle"],
		"learnset": {7: "pound", 10: "vine_lash"},
		"sprite": "res://assets/enemy_aquillo.png",
	},
	"bunten": {
		"display_name": "Bunten",
		"type": "normal",
		"max_hp": 32,
		"moves": ["pound", "tackle"],
		"learnset": {7: "quick_attack"},
		"sprite": "res://assets/enemy_bunten.png",
	},
	"mindling": {
		"display_name": "Mindling",
		"type": "psychic",
		"max_hp": 26,
		"moves": ["confusion", "scratch"],
		"learnset": {8: "tackle", 12: "thunder_wave"},
		"sprite": "res://assets/enemy_mindling.png",
	},
	"pebbleon": {
		"display_name": "Pebbleon",
		"type": "ground",
		"max_hp": 38,
		"moves": ["pound", "tackle", "rock_throw"],
		"learnset": {},
		"sprite": "res://assets/enemy_pebbleon.png",
	},
}

const WILD_POOL := ["volty", "twigling", "embertail", "aquillo", "bunten", "mindling", "pebbleon"]
