class_name KaissaRules
extends RefCounted
## Spielzustand und Zuglogik von Kaissa, unabhängig von der Darstellung.

signal changed
signal game_over(message: String)

const SIZE := 10
const DRAW := 2

## Feld -> {"type": PieceTypes.Type, "side": PieceTypes.Side, "moved": bool}
var pieces: Dictionary = {}
var turn: PieceTypes.Side = PieceTypes.Side.YELLOW
## -1 = Spiel läuft, sonst PieceTypes.Side des Siegers oder DRAW.
var winner: int = -1
var result_text := ""
var captured: Array[Dictionary] = []
## Anzahl der bereits ausgeführten Züge je Seite (Index = PieceTypes.Side).
var moves_made: Array[int] = [0, 0]
var homestone_placed: Array[bool] = [false, false]

func reset() -> void:
	pieces.clear()
	captured.clear()
	winner = -1
	result_text = ""
	turn = PieceTypes.Side.YELLOW
	moves_made = [0, 0]
	homestone_placed = [false, false]
	# Gelb unten, Rot oben; Ubar steht Ubar gegenüber.
	for side in [PieceTypes.Side.YELLOW, PieceTypes.Side.RED]:
		var back := home_row(side)
		var dy := forward(side)
		for x in SIZE:
			_place(Vector2i(x, back), PieceTypes.BACK_ROW[x], side)
			_place(Vector2i(x, back + dy), PieceTypes.SECOND_ROW[x], side)
		for x in PieceTypes.THIRD_ROW_SPEARMEN:
			_place(Vector2i(x, back + 2 * dy), PieceTypes.Type.SPEARMAN, side)
	changed.emit()

func _place(cell: Vector2i, type: PieceTypes.Type, side: PieceTypes.Side) -> void:
	pieces[cell] = {"type": type, "side": side, "moved": false}

static func side_name(side: PieceTypes.Side) -> String:
	return "Gelb" if side == PieceTypes.Side.YELLOW else "Rot"

static func other(side: PieceTypes.Side) -> PieceTypes.Side:
	return PieceTypes.Side.RED if side == PieceTypes.Side.YELLOW else PieceTypes.Side.YELLOW

static func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < SIZE and cell.y < SIZE

## Erste Reihe (Grundreihe) einer Seite.
static func home_row(side: PieceTypes.Side) -> int:
	return SIZE - 1 if side == PieceTypes.Side.YELLOW else 0

## Richtung "nach vorn" in Bildschirmkoordinaten.
static func forward(side: PieceTypes.Side) -> int:
	return -1 if side == PieceTypes.Side.YELLOW else 1

func piece_at(cell: Vector2i) -> Dictionary:
	return pieces.get(cell, {})

func is_over() -> bool:
	return winner != -1

func legal_moves(from: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var piece := piece_at(from)
	if piece.is_empty() or is_over():
		return result
	var side: PieceTypes.Side = piece.side
	for pattern: Dictionary in PieceTypes.DEFINITIONS[piece.type].moves:
		var can_capture: bool = pattern.get("capture", true)
		match pattern.kind:
			"slide":
				var max_range: int = pattern.range if pattern.range > 0 else SIZE
				for dir: Vector2i in pattern.dirs:
					var cell := from
					for i in max_range:
						cell += dir
						if not in_bounds(cell):
							break
						var other_piece := piece_at(cell)
						if other_piece.is_empty():
							_add(result, cell)
							continue
						if can_capture and other_piece.side != side:
							_add(result, cell)
						break
			"leap":
				for offset: Vector2i in pattern.offsets:
					var cell := from + offset
					if not in_bounds(cell):
						continue
					var other_piece := piece_at(cell)
					if other_piece.is_empty() or (can_capture and other_piece.side != side):
						_add(result, cell)
			"spear":
				_spear_moves(from, piece, result)
	return result

func _spear_moves(from: Vector2i, piece: Dictionary, result: Array[Vector2i]) -> void:
	var side: PieceTypes.Side = piece.side
	var dy := forward(side)
	# Beim ersten Zug ein, zwei oder drei Felder, danach nur eines; nur auf freie Felder.
	var steps := 1 if piece.moved else 3
	for i in range(1, steps + 1):
		var cell := from + Vector2i(0, dy * i)
		if not in_bounds(cell) or not piece_at(cell).is_empty():
			break
		_add(result, cell)
	# Geschlagen wird nur schräg vorwärts.
	for dx in [-1, 1]:
		var cell := from + Vector2i(dx, dy)
		if in_bounds(cell):
			var other_piece := piece_at(cell)
			if not other_piece.is_empty() and other_piece.side != side:
				_add(result, cell)

func _add(list: Array[Vector2i], cell: Vector2i) -> void:
	if not list.has(cell):
		list.append(cell)

## Muss die Seite in diesem Zug ihren Homestone setzen, weil die Frist abläuft?
func must_place_homestone(side: PieceTypes.Side) -> bool:
	return not homestone_placed[side] and moves_made[side] >= PieceTypes.HOMESTONE_DEADLINE - 1

## Freie Felder der eigenen ersten Reihe, auf die der Homestone gesetzt werden kann.
func homestone_placements(side: PieceTypes.Side) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if is_over() or homestone_placed[side]:
		return result
	for x in SIZE:
		var cell := Vector2i(x, home_row(side))
		if piece_at(cell).is_empty():
			result.append(cell)
	return result

func can_select(cell: Vector2i) -> bool:
	var piece := piece_at(cell)
	return not is_over() and not piece.is_empty() and piece.side == turn and not must_place_homestone(turn)

## Muss der Spieler für diesen Zug eine Umwandlungsfigur wählen?
func needs_promotion(from: Vector2i, to: Vector2i) -> bool:
	var piece := piece_at(from)
	return not piece.is_empty() and piece.type == PieceTypes.Type.SPEARMAN \
		and to.y == home_row(other(piece.side))

## Führt einen Zug aus. Gibt false zurück, wenn er nicht erlaubt ist.
## [param promotion] ist nötig, wenn [method needs_promotion] true liefert.
func move(from: Vector2i, to: Vector2i, promotion: int = -1) -> bool:
	if not can_select(from) or not legal_moves(from).has(to):
		return false
	if needs_promotion(from, to) and not PieceTypes.PROMOTIONS.has(promotion):
		return false
	var promote := needs_promotion(from, to)
	var piece: Dictionary = pieces[from]
	var target := piece_at(to)
	if not target.is_empty():
		captured.append(target)
	pieces.erase(from)
	piece.moved = true
	if promote:
		piece.type = promotion
	pieces[to] = piece
	if not target.is_empty() and target.type == PieceTypes.Type.HOMESTONE:
		_finish(piece.side, "%s erobert den Homestone und gewinnt!" % side_name(piece.side))
	_end_turn()
	return true

func place_homestone(cell: Vector2i) -> bool:
	if not homestone_placements(turn).has(cell):
		return false
	_place(cell, PieceTypes.Type.HOMESTONE, turn)
	homestone_placed[turn] = true
	_end_turn()
	return true

func resign() -> void:
	if is_over():
		return
	_finish(other(turn), "%s gibt auf. %s gewinnt!" % [side_name(turn), side_name(other(turn))])
	changed.emit()

func agree_draw() -> void:
	if is_over():
		return
	_finish(DRAW, "Remis vereinbart.")
	changed.emit()

func _end_turn() -> void:
	moves_made[turn] += 1
	if not is_over():
		turn = other(turn)
		if must_place_homestone(turn) and homestone_placements(turn).is_empty():
			_finish(other(turn), "%s kann den Homestone nicht rechtzeitig setzen. %s gewinnt!" % [side_name(turn), side_name(other(turn))])
		elif not _has_any_action(turn):
			_finish(other(turn), "%s kann nicht mehr ziehen. %s gewinnt!" % [side_name(turn), side_name(other(turn))])
	changed.emit()

func _has_any_action(side: PieceTypes.Side) -> bool:
	if not homestone_placements(side).is_empty():
		return true
	if must_place_homestone(side):
		return false
	for cell: Vector2i in pieces:
		if pieces[cell].side == side and not legal_moves(cell).is_empty():
			return true
	return false

func _finish(new_winner: int, message: String) -> void:
	winner = new_winner
	result_text = message
	game_over.emit(message)
