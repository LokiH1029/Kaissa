class_name KaissaRules
extends RefCounted
## Spielzustand und Zuglogik von Kaissa, unabhängig von der Darstellung.

signal changed
signal game_over(winner: PieceTypes.Side)

const SIZE := 10

## Feld -> {"type": PieceTypes.Type, "side": PieceTypes.Side, "moved": bool}
var pieces: Dictionary = {}
var turn: PieceTypes.Side = PieceTypes.Side.YELLOW
var winner: int = -1
var captured: Array[Dictionary] = []

func reset() -> void:
	pieces.clear()
	captured.clear()
	winner = -1
	turn = PieceTypes.Side.YELLOW
	# Gelb unten (Reihen 9 und 8), Rot oben (Reihen 0 und 1); Ubar steht Ubar gegenüber.
	for x in SIZE:
		_place(Vector2i(x, SIZE - 1), PieceTypes.BACK_ROW[x], PieceTypes.Side.YELLOW)
		_place(Vector2i(x, SIZE - 2), PieceTypes.FRONT_ROW[x], PieceTypes.Side.YELLOW)
		_place(Vector2i(x, 0), PieceTypes.BACK_ROW[x], PieceTypes.Side.RED)
		_place(Vector2i(x, 1), PieceTypes.FRONT_ROW[x], PieceTypes.Side.RED)
	changed.emit()

func _place(cell: Vector2i, type: PieceTypes.Type, side: PieceTypes.Side) -> void:
	pieces[cell] = {"type": type, "side": side, "moved": false}

static func side_name(side: PieceTypes.Side) -> String:
	return "Gelb" if side == PieceTypes.Side.YELLOW else "Rot"

static func other(side: PieceTypes.Side) -> PieceTypes.Side:
	return PieceTypes.Side.RED if side == PieceTypes.Side.YELLOW else PieceTypes.Side.YELLOW

static func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < SIZE and cell.y < SIZE

func piece_at(cell: Vector2i) -> Dictionary:
	return pieces.get(cell, {})

## Richtung "nach vorn" in Bildschirmkoordinaten.
static func forward(side: PieceTypes.Side) -> int:
	return -1 if side == PieceTypes.Side.YELLOW else 1

func legal_moves(from: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var piece := piece_at(from)
	if piece.is_empty() or winner != -1:
		return result
	var side: PieceTypes.Side = piece.side
	var def: Dictionary = PieceTypes.DEFINITIONS[piece.type]
	match def.kind:
		"slide":
			var max_range: int = def.range if def.range > 0 else SIZE
			for dir: Vector2i in def.dirs:
				var cell := from
				for i in max_range:
					cell += dir
					if not in_bounds(cell):
						break
					var other := piece_at(cell)
					if other.is_empty():
						result.append(cell)
						continue
					if other.side != side:
						result.append(cell)
					break
		"leap":
			for offset in PieceTypes.tarn_leaps():
				var cell := from + offset
				if in_bounds(cell):
					var other := piece_at(cell)
					if other.is_empty() or other.side != side:
						result.append(cell)
		"spear":
			var dy := forward(side)
			var one := from + Vector2i(0, dy)
			if in_bounds(one) and piece_at(one).is_empty():
				result.append(one)
				var two := from + Vector2i(0, 2 * dy)
				if not piece.moved and in_bounds(two) and piece_at(two).is_empty():
					result.append(two)
			for dx in [-1, 1]:
				var diag := from + Vector2i(dx, dy)
				if in_bounds(diag):
					var other := piece_at(diag)
					if not other.is_empty() and other.side != side:
						result.append(diag)
	return result

func can_select(cell: Vector2i) -> bool:
	var piece := piece_at(cell)
	return winner == -1 and not piece.is_empty() and piece.side == turn

## Führt einen Zug aus. Gibt false zurück, wenn er nicht erlaubt ist.
func move(from: Vector2i, to: Vector2i) -> bool:
	if not can_select(from) or not legal_moves(from).has(to):
		return false
	var piece: Dictionary = pieces[from]
	var target := piece_at(to)
	if not target.is_empty():
		captured.append(target)
	pieces.erase(from)
	piece.moved = true
	# Ein Speerträger auf der gegnerischen Grundreihe wird zum Reiter.
	if piece.type == PieceTypes.Type.SPEARMAN and (to.y == 0 or to.y == SIZE - 1):
		piece.type = PieceTypes.Type.RIDER
	pieces[to] = piece

	if not target.is_empty() and target.type == PieceTypes.Type.UBAR:
		_finish(piece.side)
	else:
		turn = other(turn)
		if not _has_any_move(turn):
			_finish(other(turn))
	changed.emit()
	return true

func _has_any_move(side: PieceTypes.Side) -> bool:
	for cell: Vector2i in pieces:
		if pieces[cell].side == side and not legal_moves(cell).is_empty():
			return true
	return false

func _finish(side: PieceTypes.Side) -> void:
	winner = side
	game_over.emit(side)
