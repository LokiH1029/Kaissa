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
	"": {"g10-i7": 14, "f9-f6": 10, "g9-g6": 8, "d9-d8": 5, "f9-f7": 3},
	"d9-d8": {"g1-e4": 10, "b2-b3": 8, "g2-g5": 8},
	"e9-e6": {"g1-i4": 10, "g1-e4": 18, "d1-b4": 8},
	"f9-f6": {"g2-g5": 10, "d2-d5": 8, "g1-e4": 9},
	"f9-f7": {"f2-f5": 10, "g1-i4": 9, "g1-e4": 9},
	"g10-e7": {"f2-f3": 10, "h2-h3": 10},
	"g10-i7": {"f2-f3": 10, "h2-h3": 6},
	"g9-g6": {"g2-g5": 10, "g1-i4": 9, "g1-e4": 14},
	"d9-d8 b2-b3": {"g10-e7": 10, "g10-i7": 9},
	"d9-d8 g1-e4": {"d10-d9": 10, "i9-i8": 6, "e10-b7": 4},
	"e9-e6 g1-e4": {"e10-e9": 10, "e10-e7": 6, "f10-e9": 2},
	"e9-e6 g1-i4": {"e10-e9": 10, "e10-e7": 8, "h9-h8": 5},
	"f9-f6 d2-d5": {"d10-f7": 10, "j8-j5": 9, "d10-b7": 9},
	"f9-f6 g1-d3": {"e10-f9": 10, "f10-f9": 10, "g10-i7": 7},
	"f9-f6 g2-g5": {"f6xg5": 10, "g10-i7": 4, "e10-f9": 3},
	"f9-f7 f2-f5": {"e10-h7": 10, "g10-i7": 10, "d10-g8": 8},
	"f9-f7 g1-i4": {"f10-f8": 10, "e10-g8": 10, "e10-h7": 10},
	"g10-e7 f2-f3": {"HS@g10": 10, "d9-d6": 4},
	"g10-e7 h2-h3": {"HS@g10": 10, "d9-d6": 9, "j8-j5": 8},
	"g10-i7 f2-f3": {"HS@g10": 10},
	"g10-i7 h2-h3": {"HS@g10": 10, "d9-d6": 7, "e9-e7": 5},
	"g9-g6 g1-i4": {"h10-f8": 10, "f10-i7": 9, "h9-h8": 2},
	"g9-g6 g2-g5": {"a8-a5": 10, "d10-f7": 9, "h10-e7": 8},
	"d9-d8 b2-b3 g10-e7": {"i2-h3": 10, "i2-i3": 10},
	"d9-d8 b2-b3 g10-i7": {"i2-i3": 10},
	"d9-d8 g1-e4 d10-d9": {"HS@g1": 10, "a3-a6": 10, "j3-j6": 10},
	"d9-d8 g1-e4 i9-i8": {"d2-d5": 10, "HS@g1": 9, "i2-i3": 7},
	"e9-e6 g1-e4 e10-e7": {"j3-j6": 10, "HS@g1": 10, "b2-b3": 4},
	"e9-e6 g1-e4 e10-e9": {"HS@g1": 10, "a3-a6": 10, "j3-j6": 10},
	"e9-e6 g1-i4 e10-e7": {"HS@g1": 10, "i4-h5": 8, "a3-a6": 5},
	"e9-e6 g1-i4 e10-e9": {"b2-b3": 10, "d1-g3": 10, "i4-h4": 10},
	"f9-f6 d2-d5 d10-f7": {"e1-d2": 10, "c1-e3": 2},
	"f9-f6 d2-d5 j8-j5": {"a3-a6": 10, "g1-d3": 10, "d1-d2": 9},
	"f9-f6 g1-d3 e10-f9": {"HS@g1": 10, "j3-j6": 6, "a3-a6": 4},
	"f9-f6 g1-d3 f10-f9": {"HS@g1": 10, "j3-j6": 10, "e2-e5": 6},
	"f9-f6 g2-g5 f6xg5": {"f1-g2": 10, "h1-c6": 8, "d2-d5": 2},
	"f9-f6 g2-g5 g10-i7": {"i2-h3": 10, "f1-i4": 6, "h1-f3": 4},
	"f9-f7 f2-f5 e10-h7": {"f1-f4": 10, "f1-f3": 10, "f1-f2": 4},
	"f9-f7 f2-f5 g10-i7": {"f1-f4": 10, "f1-f3": 9, "i2-h3": 1},
	"f9-f7 g1-i4 e10-g8": {"HS@g1": 10, "f2-f5": 3, "d1-b4": 3},
	"f9-f7 g1-i4 f10-f8": {"HS@g1": 10, "a3-a6": 8, "b2-b3": 7},
	"g10-e7 f2-f3 HS@g10": {"g1-e4": 10, "d1-f4": 10, "d1-g3": 7},
	"g10-e7 f2-f3 d9-d6": {"g1-i4": 10, "g1-e4": 10, "d1-g3": 9},
	"g10-e7 h2-h3 HS@g10": {"d1-f4": 10, "g1-e4": 7, "g1-i4": 4},
	"g10-e7 h2-h3 d9-d6": {"g1-e4": 10, "g1-i4": 10, "g1-h2": 8},
	"g10-i7 f2-f3 HS@g10": {"f1-f2": 10, "g1-e4": 9, "g1-i4": 9},
	"g10-i7 h2-h3 HS@g10": {"g1-e4": 10, "d1-g3": 9, "g1-i4": 9},
	"g10-i7 h2-h3 d9-d6": {"j3-j6": 10, "g1-i4": 6},
	"g9-g6 g1-i4 f10-i7": {"HS@g1": 10, "b2-b3": 7, "i4-h3": 4},
	"g9-g6 g1-i4 h10-f8": {"HS@g1": 10, "j3-j6": 6},
	"g9-g6 g2-g5 a8-a5": {"d2-d5": 10, "d2-d3": 7, "g1-g2": 5},
	"g9-g6 g2-g5 d10-f7": {"g1-g2": 10, "g1-e4": 4},
	"d9-d8 b2-b3 g10-e7 i2-h3": {"HS@g10": 10},
	"d9-d8 b2-b3 g10-e7 i2-i3": {"HS@g10": 10, "a8-a5": 10, "j8-j5": 10},
	"d9-d8 b2-b3 g10-i7 i2-i3": {"HS@g10": 10, "a8-a5": 10, "j8-j5": 9},
	"d9-d8 g1-e4 d10-d9 HS@g1": {"HS@d10": 10, "f9-f6": 7, "j8-j5": 2},
	"d9-d8 g1-e4 d10-d9 a3-a6": {"g10-e7": 10, "g10-i7": 9, "f9-f6": 9},
	"d9-d8 g1-e4 i9-i8 HS@g1": {"c10-f7": 10, "g10-e7": 9, "e10-b7": 7},
	"d9-d8 g1-e4 i9-i8 d2-d5": {"e9-e6": 10, "c10-f7": 8, "g10-e7": 5},
	"e9-e6 g1-e4 e10-e7 HS@g1": {"HS@e10": 10, "g10-i7": 7, "i9-i8": 5},
	"e9-e6 g1-e4 e10-e7 j3-j6": {"HS@e10": 10, "d9-d6": 6, "a8-a5": 6},
	"e9-e6 g1-e4 e10-e9 HS@g1": {"HS@e10": 10},
	"e9-e6 g1-e4 e10-e9 a3-a6": {"HS@e10": 10, "g10-e7": 10, "g10-i7": 6},
	"e9-e6 g1-i4 e10-e7 HS@g1": {"HS@e10": 10},
	"e9-e6 g1-i4 e10-e7 i4-h5": {"e7-h7": 10, "e7-e8": 6, "e7-c5": 5},
	"e9-e6 g1-i4 e10-e9 b2-b3": {"e6-e5": 10, "i9-i8": 5},
	"e9-e6 g1-i4 e10-e9 d1-g3": {"HS@e10": 10, "g9-g6": 5, "h9-h6": 5},
	"f9-f6 d2-d5 d10-f7 c1-e3": {"HS@d10": 10, "j8-j5": 10, "j8-j6": 4},
	"f9-f6 d2-d5 d10-f7 e1-d2": {"HS@d10": 10, "j8-j5": 10, "g9-g6": 4},
	"f9-f6 d2-d5 j8-j5 a3-a6": {"d9-d6": 10, "f10-f9": 10, "f10-f7": 10},
	"f9-f6 d2-d5 j8-j5 g1-d3": {"e10-f9": 10, "f10-f9": 10, "f10-f7": 6},
	"f9-f6 g1-d3 e10-f9 HS@g1": {"HS@e10": 10, "f6-f5": 4},
	"f9-f6 g1-d3 e10-f9 j3-j6": {"HS@e10": 10, "a8-a6": 10, "f6-f5": 10},
	"f9-f6 g1-d3 f10-f9 HS@g1": {"HS@f10": 10, "d9-d6": 1},
	"f9-f6 g1-d3 f10-f9 j3-j6": {"HS@f10": 10, "d10-g8": 10, "d9-d6": 10},
	"f9-f6 g2-g5 f6xg5 f1-g2": {"d10-f7": 10, "d10-g8": 9, "d10-b7": 9},
	"f9-f6 g2-g5 f6xg5 h1-c6": {"f10-f7": 10, "a9-c7": 10, "d9-d7": 7},
	"f9-f6 g2-g5 g10-i7 f1-i4": {"f6-f5": 10, "b9-b8": 9, "i7-i8": 6},
	"f9-f6 g2-g5 g10-i7 i2-h3": {"f6xg5": 10, "e10-f9": 8, "e10-h7": 3},
	"f9-f7 f2-f5 e10-h7 f1-f3": {"j8-j5": 10, "HS@e10": 10, "a8-a5": 8},
	"f9-f7 f2-f5 e10-h7 f1-f4": {"a8-a5": 10, "j8-j5": 10, "HS@e10": 10},
	"f9-f7 f2-f5 g10-i7 f1-f3": {"HS@g10": 10, "j8-j5": 6, "e10-g8": 4},
	"f9-f7 f2-f5 g10-i7 f1-f4": {"i7-h7": 10, "HS@g10": 7, "a8-a5": 6},
	"f9-f7 g1-i4 e10-g8 HS@g1": {"HS@e10": 10, "i9-h8": 10},
	"f9-f7 g1-i4 e10-g8 f2-f5": {"HS@e10": 10, "i9-h8": 2},
	"f9-f7 g1-i4 f10-f8 HS@g1": {"j8-j5": 10, "HS@f10": 3},
	"f9-f7 g1-i4 f10-f8 a3-a6": {"j8-j5": 10, "g10-e7": 5},
	"g10-e7 f2-f3 HS@g10 d1-f4": {"c9-c8": 10, "e9-e8": 10, "a9-c7": 10},
	"g10-e7 f2-f3 HS@g10 g1-e4": {"h9-h8": 10, "i9-i8": 9, "i9-h8": 9},
	"g10-e7 f2-f3 d9-d6 g1-e4": {"h9-h8": 10, "j9-h7": 9, "d10-d9": 8},
	"g10-e7 f2-f3 d9-d6 g1-i4": {"i9-h8": 10, "d10-d9": 8, "i9-i8": 7},
	"g10-e7 h2-h3 HS@g10 d1-f4": {"c9-c8": 10, "e9-e8": 10, "a8-a5": 8},
	"g10-e7 h2-h3 HS@g10 g1-e4": {"h9-h8": 10, "j9-h7": 10, "i9-i8": 6},
	"g10-e7 h2-h3 d9-d6 g1-e4": {"d10-d9": 10, "j9-h7": 8, "f9-f8": 5},
	"g10-e7 h2-h3 d9-d6 g1-i4": {"HS@g10": 10, "i9-h8": 10, "j9-h7": 10},
	"g10-i7 f2-f3 HS@g10 f1-f2": {"j8-j5": 10},
	"g10-i7 f2-f3 HS@g10 g1-e4": {"i9-h8": 10, "j9-h7": 10, "f9-f6": 10},
	"g10-i7 f2-f3 HS@g10 g1-f2": {"j8-j5": 10, "d10-f7": 8, "d10-b7": 8},
	"g10-i7 h2-h3 HS@g10 d1-g3": {"a8-a5": 10, "i7-f5": 5, "i7-h7": 4},
	"g10-i7 h2-h3 HS@g10 g1-e4": {"i9-i8": 10, "j9-h7": 10, "i9-h8": 10},
	"g10-i7 h2-h3 d9-d6 g1-i4": {"HS@g10": 10, "i9-h8": 3, "j9-h7": 3},
	"g10-i7 h2-h3 d9-d6 j3-j6": {"i7-h8": 10, "i7-j7": 10, "i7-i8": 10},
	"g9-g6 g1-i4 f10-i7 HS@g1": {"HS@f10": 10, "d10-f7": 3, "h10-e7": 3},
	"g9-g6 g1-i4 f10-i7 b2-b3": {"HS@f10": 10},
	"g9-g6 g1-i4 h10-f8 HS@g1": {"j8-j5": 10, "HS@h10": 7},
	"g9-g6 g1-i4 h10-f8 j3-j6": {"g10-e7": 10},
	"g9-g6 g2-g5 a8-a5 d2-d3": {"b9-a8": 10, "d10-b7": 4},
	"g9-g6 g2-g5 a8-a5 d2-d5": {"d10-f7": 10, "d10-b7": 10, "i9-i8": 7},
	"g9-g6 g2-g5 d10-f7 g1-e4": {"h10-f8": 10, "f9-f8": 10, "h9-h8": 10},
	"g9-g6 g2-g5 d10-f7 g1-g2": {"g10-i7": 10, "g10-e7": 10, "f7-e7": 9},
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
