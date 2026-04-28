extends Node

# kind: "damage" | "heal" | "status"
# status: "" | "paralyze" | "sleep" | "burn"  (only used when kind = "status")
# type:  normal | electric | fire | water | grass
const MOVES := {
	"thunderbolt":   {"name": "Thunderbolt",   "kind": "damage", "type": "electric", "min": 9,  "max": 14, "accuracy": 95,  "max_pp": 15},
	"quick_attack":  {"name": "Quick Attack",  "kind": "damage", "type": "normal",   "min": 4,  "max": 7,  "accuracy": 100, "max_pp": 30},
	"thunder_wave":  {"name": "Thunder Wave",  "kind": "status", "type": "electric", "status": "paralyze", "accuracy": 90, "max_pp": 20},
	"recover":       {"name": "Recover",       "kind": "heal",   "type": "normal",   "min": 12, "max": 18, "accuracy": 100, "max_pp": 10},
	"spark":         {"name": "Spark",         "kind": "damage", "type": "electric", "min": 5,  "max": 9,  "accuracy": 95,  "max_pp": 20},
	"tackle":        {"name": "Tackle",        "kind": "damage", "type": "normal",   "min": 4,  "max": 8,  "accuracy": 100, "max_pp": 35},
	"vine_lash":     {"name": "Vine Lash",     "kind": "damage", "type": "grass",    "min": 6,  "max": 10, "accuracy": 95,  "max_pp": 10},
	"sleep_powder":  {"name": "Sleep Powder",  "kind": "status", "type": "grass",    "status": "sleep",    "accuracy": 75, "max_pp": 15},
	"ember":         {"name": "Ember",         "kind": "damage", "type": "fire",     "min": 5,  "max": 11, "accuracy": 95,  "max_pp": 15},
	"flame_touch":   {"name": "Flame Touch",   "kind": "status", "type": "fire",     "status": "burn",     "accuracy": 85, "max_pp": 25},
	"scratch":       {"name": "Scratch",       "kind": "damage", "type": "normal",   "min": 4,  "max": 7,  "accuracy": 100, "max_pp": 35},
	"water_pulse":   {"name": "Water Pulse",   "kind": "damage", "type": "water",    "min": 6,  "max": 10, "accuracy": 95,  "max_pp": 20},
	"pound":         {"name": "Pound",         "kind": "damage", "type": "normal",   "min": 5,  "max": 9,  "accuracy": 100, "max_pp": 35},
	"confusion":     {"name": "Confusion",     "kind": "damage", "type": "psychic",  "min": 5,  "max": 9,  "accuracy": 100, "max_pp": 25},
}

# Only non-1.0 entries listed; missing pairs default to neutral (1.0).
const TYPE_CHART := {
	"electric": {"water": 2.0, "grass": 0.5},
	"fire":     {"grass": 2.0, "water": 0.5},
	"water":    {"fire":  2.0, "grass": 0.5},
	"grass":    {"water": 2.0, "fire":  0.5},
}

static func name_of(id: String) -> String:
	if MOVES.has(id):
		return MOVES[id]["name"]
	return id

static func effectiveness(move_type: String, defender_type: String) -> float:
	var row: Dictionary = TYPE_CHART.get(move_type, {})
	return float(row.get(defender_type, 1.0))
