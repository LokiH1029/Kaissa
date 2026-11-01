class_name OpeningTrainer
extends RefCounted
## Logik des Eröffnungstrainings, unabhängig von der Darstellung.
##
## Grundlage ist das Eröffnungsbuch der Bots ([OpeningBook]). Eine Übung beginnt mit
## einer festen Zugfolge ([member prefix], die gewählte Eröffnung oder Variante) und folgt
## danach dem Buch. Der Spieler muss auf seiner Seite einen Buchzug finden, der Trainer
## antwortet für die Gegenseite mit einem Buchzug, bis das Buch endet.

## Namen und Erklärungen der ersten Züge von Gelb. Erste Züge, die hier fehlen, aber im
## Buch stehen, erscheinen mit ihrer Kurzschreibweise in der Liste.
const OPENINGS := [
	{"move": "g10-i7", "name": "Tarnsman-Sprung rechts",
		"text": "Der rechte Tarnsman springt nach i7. Laut Engine der beste erste Zug. Nach einer ruhigen Antwort setzt Gelb den Homestone gleich auf das frei gewordene Feld g10. Für Rot ist j3-j6 ein Fehler, besser sind f2-f3 oder h2-h3."},
	{"move": "f9-f6", "name": "f-Spearman-Vorstoß",
		"text": "Der f-Spearman zieht drei Felder vor. Holte gegen den Meister die meisten Punkte und ist etwa so gut wie der Tarnsman-Sprung."},
	{"move": "g9-g6", "name": "g-Spearman-Vorstoß",
		"text": "Der g-Spearman zieht drei Felder vor und öffnet die Diagonale für den Initiate. Etwa gleichwertig mit dem f-Vorstoß."},
	{"move": "d9-d8", "name": "Ruhiger d-Spearman",
		"text": "Ein kleiner Schritt des d-Spearman, der den Initiate auf d10 freilässt. Solide, aber etwas passiver."},
	{"move": "f9-f7", "name": "Kurzer f-Vorstoß",
		"text": "Der f-Spearman zieht nur zwei Felder. Noch wenig erprobt."},
	{"move": "g10-e7", "name": "Tarnsman-Sprung links",
		"text": "Spiegelbild des Sprungs nach i7. Für die Engine gleich gut, in Bot-Partien aber schwächer (43 %). Nicht im Buch der Bots, nur zum Üben."},
	{"move": "e9-e6", "name": "e-Spearman-Vorstoß",
		"text": "Der e-Spearman zieht drei Felder vor. Schnitt in Bot-Partien schwach ab (41 %) und steht nicht im Buch der Bots, nur zum Üben."},
]

## Ergebnis von [method check_move].
enum Verdict { MAIN, BOOK, WRONG }

## Zugfolge, mit der die Übung beginnt (Kurzschreibweise).
var prefix: Array[String] = []
## Seite des Spielers.
var player_side: PieceTypes.Side = PieceTypes.Side.YELLOW
var rng := RandomNumberGenerator.new()

## Alle Eröffnungen für die Liste: Array von {"name", "text", "moves": Array[String],
## "variations": Array von {"name", "moves"}}. Nur Züge, nach denen das Buch weitergeht.
static func catalog() -> Array:
	var result: Array = []
	var firsts: Array[String] = []
	for entry: Dictionary in OPENINGS:
		firsts.append(entry.move)
	var start_position: Array[String] = []
	for move: String in book_moves(start_position):
		if not firsts.has(move):
			firsts.append(move)
	for first in firsts:
		if not OpeningBook.LINES.has(first):
			continue
		var name := first
		var text := ""
		for entry: Dictionary in OPENINGS:
			if entry.move == first:
				name = entry.name
				text = entry.text
		var variations: Array = []
		var first_only: Array[String] = [first]
		var replies := book_moves(first_only)
		for reply in replies:
			var moves: Array[String] = [first, reply]
			if not OpeningBook.LINES.has(" ".join(moves)):
				continue
			var label := "gegen %s" % reply
			if reply == replies[0]:
				label += " (Hauptvariante)"
			variations.append({"name": label, "moves": moves})
		var opening_moves: Array[String] = [first]
		result.append({"name": name, "text": text, "moves": opening_moves, "variations": variations})
	return result

## Buchzüge nach der Zugfolge [param history], nach Gewicht absteigend.
static func book_moves(history: Array[String]) -> Array[String]:
	var result: Array[String] = []
	var key := " ".join(history)
	if not OpeningBook.LINES.has(key):
		return result
	var moves: Dictionary = OpeningBook.LINES[key]
	for move: String in moves:
		result.append(move)
	result.sort_custom(func(a, b): return int(moves[a]) > int(moves[b]))
	return result

## Anzahl der Buchstellungen unterhalb von [param moves] (inklusive), als Maß für die Größe.
static func line_count(moves: Array[String]) -> int:
	var key := " ".join(moves)
	var count := 0
	for other: String in OpeningBook.LINES:
		if other == key or other.begins_with(key + " ") or key.is_empty():
			count += 1
	return count

func start(start_moves: Array[String], side: PieceTypes.Side) -> void:
	prefix = start_moves.duplicate()
	player_side = side

## Züge, die in der Stellung nach [param history] erwartet werden (bester zuerst).
## Leer heißt: Die Übung ist zu Ende.
func expected(history: Array[String]) -> Array[String]:
	var ply := history.size()
	if ply < prefix.size():
		var forced: Array[String] = [prefix[ply]]
		return forced
	return book_moves(history)

func is_finished(history: Array[String]) -> bool:
	return expected(history).is_empty()

## Bewertet den Zug [param move] des Spielers nach [param history].
func check_move(history: Array[String], move: String) -> Verdict:
	var moves := expected(history)
	if moves.is_empty() or not moves.has(move):
		return Verdict.WRONG
	return Verdict.MAIN if move == moves[0] else Verdict.BOOK

## Wählt den Zug der Gegenseite nach Buchgewicht. Züge, nach denen das Buch weitergeht,
## werden bevorzugt, damit die Übung nicht gleich endet.
func opponent_move(history: Array[String]) -> String:
	var moves := expected(history)
	if moves.size() <= 1:
		return moves[0] if moves else ""
	var weights: Dictionary = OpeningBook.LINES[" ".join(history)]
	var continuing: Array[String] = []
	for move in moves:
		var next := history.duplicate()
		next.append(move)
		if OpeningBook.LINES.has(" ".join(next)):
			continuing.append(move)
	var pool := continuing if continuing else moves
	var total := 0
	for move in pool:
		total += int(weights[move])
	var roll := rng.randi_range(1, maxi(total, 1))
	for move in pool:
		roll -= int(weights[move])
		if roll <= 0:
			return move
	return pool[0]
