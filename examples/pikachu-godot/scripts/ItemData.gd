extends Node

# Item registry: heals and capture balls organised by tier.
const ITEMS := {
	"potion":       {"name": "Potion",       "price": 30,  "kind": "heal", "heal": 20},
	"super_potion": {"name": "Super Potion", "price": 80,  "kind": "heal", "heal": 50},
	"hyper_potion": {"name": "Hyper Potion", "price": 200, "kind": "heal", "heal": 100},
	"pokeball":     {"name": "Pokeball",     "price": 50,  "kind": "ball", "bonus": 0.0},
	"great_ball":   {"name": "Great Ball",   "price": 150, "kind": "ball", "bonus": 0.15},
	"ultra_ball":   {"name": "Ultra Ball",   "price": 350, "kind": "ball", "bonus": 0.30},
}

const POTION_TIERS := ["potion", "super_potion", "hyper_potion"]
const BALL_TIERS := ["pokeball", "great_ball", "ultra_ball"]

static func name_of(id: String) -> String:
	return String(ITEMS[id]["name"]) if ITEMS.has(id) else id
