class_name BoardView
extends Node2D
## Zeichnet das 10x10-Brett mit Figuren und nimmt Mausklicks entgegen.

signal hovered_piece(piece: Dictionary)
## Ein Spearman erreicht die gegnerische erste Reihe; main.gd fragt nach der Figur.
signal promotion_requested(from: Vector2i, to: Vector2i)

const COLOR_RED_SQUARE := Color("b8322a")
const COLOR_YELLOW_SQUARE := Color("e3b341")
const COLOR_FRAME := Color("2b1d14")
const COLOR_SELECT := Color(1, 1, 1, 0.45)
const COLOR_TARGET := Color(0.1, 0.1, 0.1, 0.35)
const COLOR_LAST_MOVE := Color(0.2, 0.6, 1.0, 0.35)
const PIECE_FILL := {
	PieceTypes.Side.YELLOW: Color("f6d86b"),
	PieceTypes.Side.RED: Color("5e0f0a"),
}
const PIECE_TEXT := {
	PieceTypes.Side.YELLOW: Color("2b1d14"),
	PieceTypes.Side.RED: Color("f4ead5"),
}

@export var cell_size := 68.0

var rules: KaissaRules
var selected := Vector2i(-1, -1)
var targets: Array[Vector2i] = []
var last_move: Array[Vector2i] = []
## true, solange der Spieler ein Feld für seinen Homestone wählt.
var placing_homestone := false
## false, solange der Bot am Zug ist: Klicks werden dann ignoriert.
var accepts_moves := true
var _font: Font

func _ready() -> void:
	_font = ThemeDB.fallback_font

func setup(game_rules: KaissaRules) -> void:
	rules = game_rules
	rules.changed.connect(queue_redraw)
	clear_selection()

func board_pixel_size() -> float:
	return cell_size * KaissaRules.SIZE

func clear_selection() -> void:
	selected = Vector2i(-1, -1)
	placing_homestone = false
	targets.clear()
	queue_redraw()

func start_homestone_placement() -> void:
	clear_selection()
	targets = rules.homestone_placements(rules.turn)
	placing_homestone = not targets.is_empty()
	queue_redraw()

func complete_move(from: Vector2i, to: Vector2i, promotion: int = -1) -> void:
	if rules.move(from, to, promotion):
		last_move = [from, to]
	queue_redraw()

## Führt eine Aktion des Bots aus (siehe [method KaissaAI.choose_action]).
func apply_action(action: Dictionary) -> void:
	clear_selection()
	if action.from == Vector2i(-1, -1):
		if rules.place_homestone(action.to):
			last_move = [action.to]
		queue_redraw()
	else:
		complete_move(action.from, action.to, action.promotion)

func cell_at(local_pos: Vector2) -> Vector2i:
	var cell := Vector2i(floori(local_pos.x / cell_size), floori(local_pos.y / cell_size))
	return cell if KaissaRules.in_bounds(cell) else Vector2i(-1, -1)

func _unhandled_input(event: InputEvent) -> void:
	if rules == null:
		return
	if event is InputEventMouseMotion:
		var cell := cell_at(to_local(event.position))
		hovered_piece.emit(rules.piece_at(cell) if cell.x >= 0 else {})
	elif event is InputEventMouseButton and event.pressed and accepts_moves:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			clear_selection()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			_on_click(cell_at(to_local(event.position)))

func _on_click(cell: Vector2i) -> void:
	if cell.x < 0:
		clear_selection()
		return
	if placing_homestone and targets.has(cell):
		clear_selection()
		if rules.place_homestone(cell):
			last_move = [cell]
		return
	if selected.x >= 0 and targets.has(cell):
		var from := selected
		clear_selection()
		if rules.needs_promotion(from, cell):
			promotion_requested.emit(from, cell)
		else:
			complete_move(from, cell)
		return
	if rules.can_select(cell):
		selected = cell
		targets = rules.legal_moves(cell)
	else:
		clear_selection()
	queue_redraw()

func _draw() -> void:
	var size := board_pixel_size()
	draw_rect(Rect2(-12, -12, size + 24, size + 24), COLOR_FRAME)
	for y in KaissaRules.SIZE:
		for x in KaissaRules.SIZE:
			var color := COLOR_YELLOW_SQUARE if (x + y) % 2 == 0 else COLOR_RED_SQUARE
			draw_rect(_rect(Vector2i(x, y)), color)
	for cell in last_move:
		draw_rect(_rect(cell), COLOR_LAST_MOVE)
	if selected.x >= 0:
		draw_rect(_rect(selected), COLOR_SELECT)
	_draw_coordinates()
	if rules == null:
		return
	for cell: Vector2i in rules.pieces:
		_draw_piece(cell, rules.pieces[cell])
	for cell in targets:
		var center := _center(cell)
		if rules.piece_at(cell).is_empty():
			draw_circle(center, cell_size * 0.14, COLOR_TARGET)
		else:
			draw_arc(center, cell_size * 0.44, 0, TAU, 32, COLOR_TARGET, 5.0)

func _draw_coordinates() -> void:
	var letters := "abcdefghij"
	var font_size := 12
	for i in KaissaRules.SIZE:
		var x := i * cell_size + cell_size * 0.5 - 3
		draw_string(_font, Vector2(x, board_pixel_size() + 10), letters[i], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
		var label := str(i + 1)
		draw_string(_font, Vector2(-11, i * cell_size + cell_size * 0.5 + 4), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, Color.WHITE)

func _draw_piece(cell: Vector2i, piece: Dictionary) -> void:
	var center := _center(cell)
	var side: PieceTypes.Side = piece.side
	var def: Dictionary = PieceTypes.DEFINITIONS[piece.type]
	var ink: Color = PIECE_TEXT[side]
	if piece.type == PieceTypes.Type.HOMESTONE:
		var half := cell_size * 0.3
		var stone := PackedVector2Array([
			center + Vector2(0, -half), center + Vector2(half, 0),
			center + Vector2(0, half), center + Vector2(-half, 0),
		])
		draw_colored_polygon(stone, PIECE_FILL[side])
		stone.append(stone[0])
		draw_polyline(stone, ink, 3.0)
	else:
		var radius := cell_size * (0.3 if piece.type == PieceTypes.Type.SPEARMAN else 0.38)
		draw_circle(center + Vector2(2, 3), radius, Color(0, 0, 0, 0.35))
		draw_circle(center, radius, PIECE_FILL[side])
		draw_arc(center, radius, 0, TAU, 32, ink, 2.5)
		if piece.type == PieceTypes.Type.UBAR or piece.type == PieceTypes.Type.UBARA:
			draw_arc(center, radius - 5, 0, TAU, 32, ink, 1.5)
	var text: String = def.short
	var font_size := int(cell_size * (0.22 if piece.type == PieceTypes.Type.SPEARMAN else 0.27))
	var text_size := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var pos := center + Vector2(-text_size.x * 0.5, font_size * 0.35)
	draw_string(_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, ink)

func _rect(cell: Vector2i) -> Rect2:
	return Rect2(Vector2(cell) * cell_size, Vector2(cell_size, cell_size))

func _center(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * cell_size
