class_name OpeningBook
extends RefCounted
## Eröffnungsbuch der Bots.
##
## Schlüssel ist die bisherige Zugfolge (Kurzschreibweise wie in
## KaissaRules.action_name, durch Leerzeichen getrennt, "" = Startstellung),
## Wert sind die Buchzüge mit Gewicht. Der Bot wählt zufällig nach Gewicht,
## damit die Partien abwechslungsreich bleiben.
##
## Die Einträge werden von tools/analyze_openings.py aus Bot-gegen-Bot-Partien
## erzeugt (siehe docs/eroeffnungen.md). Nicht von Hand zwischen den Markern ändern.

# BEGIN BOOK
const LINES := {
	"": {"g10-i7": 16, "f9-f6": 10, "g9-g6": 8},
	"f9-f6": {"g2-g5": 10, "g1-d3": 8, "d1-g3": 8},
	"g10-e7": {"f2-f3": 10, "h2-h3": 10},
	"g10-i7": {"f2-f3": 10, "h2-h3": 6},
	"g9-g6": {"g2-g5": 10, "g1-i4": 12, "g1-e4": 11},
	"f9-f6 g1-d3": {"e10-f9": 10, "f10-f9": 10, "g10-i7": 7},
	"f9-f6 g2-g5": {"f6xg5": 10, "g10-i7": 4, "e10-f9": 3},
	"g10-e7 f2-f3": {"HS@g10": 10, "d9-d6": 4},
	"g10-e7 h2-h3": {"HS@g10": 10, "d9-d6": 9, "j8-j5": 8},
	"g10-i7 f2-f3": {"HS@g10": 10},
	"g10-i7 h2-h3": {"HS@g10": 10, "d9-d6": 7, "e9-e7": 5},
	"g9-g6 g1-i4": {"h10-f8": 10, "f10-i7": 9, "h9-h8": 2},
	"g9-g6 g2-g5": {"a8-a5": 10, "d10-f7": 9, "h10-e7": 8},
}
# END BOOK

## Liefert einen Buchzug für [param history] oder "", wenn die Stellung nicht im Buch steht.
static func pick(history: Array[String], rng: RandomNumberGenerator) -> String:
	var key := " ".join(history)
	if not LINES.has(key):
		return ""
	var moves: Dictionary = LINES[key]
	var total := 0
	for move: String in moves:
		total += int(moves[move])
	if total <= 0:
		return ""
	var roll := rng.randi_range(1, total)
	for move: String in moves:
		roll -= int(moves[move])
		if roll <= 0:
			return move
	return ""
