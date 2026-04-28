extends Node

# kind: "damage" | "heal" | "status"
# status: "" | "paralyze"  (only used when kind = "status")
const MOVES := {
	"thunderbolt":   {"name": "Thunderbolt",   "kind": "damage", "min": 9,  "max": 14, "accuracy": 95},
	"quick_attack":  {"name": "Quick Attack",  "kind": "damage", "min": 4,  "max": 7,  "accuracy": 100},
	"thunder_wave":  {"name": "Thunder Wave",  "kind": "status", "status": "paralyze", "accuracy": 90},
	"recover":       {"name": "Recover",       "kind": "heal",   "min": 12, "max": 18, "accuracy": 100},
	"spark":         {"name": "Spark",         "kind": "damage", "min": 5,  "max": 9,  "accuracy": 95},
	"tackle":        {"name": "Tackle",        "kind": "damage", "min": 4,  "max": 8,  "accuracy": 100},
	"vine_lash":     {"name": "Vine Lash",     "kind": "damage", "min": 6,  "max": 10, "accuracy": 95},
	"ember":         {"name": "Ember",         "kind": "damage", "min": 5,  "max": 11, "accuracy": 95},
	"scratch":       {"name": "Scratch",       "kind": "damage", "min": 4,  "max": 7,  "accuracy": 100},
}

static func name_of(id: String) -> String:
	if MOVES.has(id):
		return MOVES[id]["name"]
	return id
