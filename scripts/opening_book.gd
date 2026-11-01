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
const LINES := {}
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
