extends Node

# kind: "damage" | "heal" | "status"
# status: "" | "paralyze"  (only used when kind = "status")
# type:  normal | electric | fire | water | grass
const MOVES := {
	"thunderbolt":   {"name": "Thunderbolt",   "kind": "damage", "type": "electric", "min": 9,  "max": 14, "accuracy": 95},
	"quick_attack":  {"name": "Quick Attack",  "kind": "damage", "type": "normal",   "min": 4,  "max": 7,  "accuracy": 100},
	"thunder_wave":  {"name": "Thunder Wave",  "kind": "status", "type": "electric", "status": "paralyze", "accuracy": 90},
	"recover":       {"name": "Recover",       "kind": "heal",   "type": "normal",   "min": 12, "max": 18, "accuracy": 100},
	"spark":         {"name": "Spark",         "kind": "damage", "type": "electric", "min": 5,  "max": 9,  "accuracy": 95},
	"tackle":        {"name": "Tackle",        "kind": "damage", "type": "normal",   "min": 4,  "max": 8,  "accuracy": 100},
	"vine_lash":     {"name": "Vine Lash",     "kind": "damage", "type": "grass",    "min": 6,  "max": 10, "accuracy": 95},
	"ember":         {"name": "Ember",         "kind": "damage", "type": "fire",     "min": 5,  "max": 11, "accuracy": 95},
	"scratch":       {"name": "Scratch",       "kind": "damage", "type": "normal",   "min": 4,  "max": 7,  "accuracy": 100},
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
