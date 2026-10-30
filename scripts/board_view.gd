class_name BoardView
extends Node2D
## Zeichnet das 10x10-Brett mit Figuren und nimmt Mausklicks entgegen.

signal hovered_piece(piece: Dictionary)

const COLOR_RED_SQUARE := Color("b8322a")
const COLOR_YELLOW_SQUARE := Color("e3b341")
const COLOR_FRAME := Color("2b1d14")
const COLOR_SELECT := Color(1, 1, 1, 0.45)
const COLOR_TARGET := Color(0.1, 0.1, 0.1, 0.35)
const COLOR_LAST_MOVE := Color(0.2, 0.6, 1.0, 0.35)
const PIECE_FILL := {
	PieceTypes.Side.YELLOW: Color("f6d86b"),
	PieceTypes.Side.RED: Color("6e130d"),
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
	targets.clear()
	queue_redraw()

func cell_at(local_pos: Vector2) -> Vector2i:
	var cell := Vector2i(floori(local_pos.x / cell_size), floori(local_pos.y / cell_size))
	return cell if KaissaRules.in_bounds(cell) else Vector2i(-1, -1)

func _unhandled_input(event: InputEvent) -> void:
	if rules == null:
		return
	if event is InputEventMouseMotion:
		var cell := cell_at(to_local(event.position))
		hovered_piece.emit(rules.piece_at(cell) if cell.x >= 0 else {})
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			clear_selection()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			_on_click(cell_at(to_local(event.position)))

func _on_click(cell: Vector2i) -> void:
	if cell.x < 0:
		clear_selection()
		return
	if selected.x >= 0 and targets.has(cell):
		var from := selected
		clear_selection()
		if rules.move(from, cell):
			last_move = [from, cell]
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
			var color := COLOR_RED_SQUARE if (x + y) % 2 == 0 else COLOR_YELLOW_SQUARE
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
		var label := str(KaissaRules.SIZE - i)
		draw_string(_font, Vector2(-11, i * cell_size + cell_size * 0.5 + 4), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, Color.WHITE)

func _draw_piece(cell: Vector2i, piece: Dictionary) -> void:
	var center := _center(cell)
	var side: PieceTypes.Side = piece.side
	var def: Dictionary = PieceTypes.DEFINITIONS[piece.type]
	var radius := cell_size * (0.24 if piece.type == PieceTypes.Type.SPEARMAN else 0.36)
	draw_circle(center + Vector2(2, 3), radius, Color(0, 0, 0, 0.35))
	draw_circle(center, radius, PIECE_FILL[side])
	draw_arc(center, radius, 0, TAU, 32, PIECE_TEXT[side], 2.5)
	if piece.type == PieceTypes.Type.UBAR or piece.type == PieceTypes.Type.UBARA:
		draw_arc(center, radius - 5, 0, TAU, 32, PIECE_TEXT[side], 1.5)
	var text: String = def.short
	if text != "":
		var font_size := int(cell_size * 0.36)
		var text_size := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		var pos := center + Vector2(-text_size.x * 0.5, font_size * 0.35)
		draw_string(_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, PIECE_TEXT[side])

func _rect(cell: Vector2i) -> Rect2:
	return Rect2(Vector2(cell) * cell_size, Vector2(cell_size, cell_size))

func _center(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * cell_size
