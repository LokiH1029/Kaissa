extends Node2D
## Hauptszene: verbindet Spielregeln, Brett und Seitenleiste.

const HINT := "Figur anklicken, um ihre Züge zu sehen.\nRechtsklick hebt die Auswahl auf."

@onready var board: BoardView = $Board
@onready var status_label: Label = %StatusLabel
@onready var homestone_label: Label = %HomestoneLabel
@onready var info_label: Label = %InfoLabel
@onready var captured_label: Label = %CapturedLabel
@onready var homestone_button: Button = %HomestoneButton
@onready var promotion_box: VBoxContainer = %PromotionBox
@onready var promote_rider_button: Button = %PromoteRiderButton
@onready var promote_tarnsman_button: Button = %PromoteTarnsmanButton
@onready var resign_button: Button = %ResignButton
@onready var draw_button: Button = %DrawButton
@onready var restart_button: Button = %RestartButton

var rules := KaissaRules.new()
var _pending_promotion: Array[Vector2i] = []

func _ready() -> void:
	board.setup(rules)
	rules.changed.connect(_update_ui)
	board.hovered_piece.connect(_on_hovered_piece)
	board.promotion_requested.connect(_on_promotion_requested)
	homestone_button.pressed.connect(board.start_homestone_placement)
	promote_rider_button.pressed.connect(_promote.bind(PieceTypes.Type.RIDER))
	promote_tarnsman_button.pressed.connect(_promote.bind(PieceTypes.Type.TARNSMAN))
	resign_button.pressed.connect(rules.resign)
	draw_button.pressed.connect(rules.agree_draw)
	restart_button.pressed.connect(_restart)
	get_viewport().size_changed.connect(_layout)
	_layout()
	_restart()

func _restart() -> void:
	_hide_promotion()
	board.last_move.clear()
	board.clear_selection()
	rules.reset()

func _layout() -> void:
	var viewport := get_viewport_rect().size
	var margin := (viewport.y - board.board_pixel_size()) * 0.5
	board.position = Vector2(maxf(margin, 24.0), maxf(margin, 24.0))

func _update_ui() -> void:
	var side := rules.turn
	if rules.is_over():
		status_label.text = rules.result_text
		board.clear_selection()
	elif rules.must_place_homestone(side):
		status_label.text = "%s muss jetzt den Homestone setzen" % KaissaRules.side_name(side)
		board.start_homestone_placement()
	else:
		status_label.text = "%s ist am Zug (Zug %d)" % [KaissaRules.side_name(side), rules.moves_made[side] + 1]

	var stone_lines: Array[String] = []
	for s in [PieceTypes.Side.YELLOW, PieceTypes.Side.RED]:
		if rules.homestone_placed[s]:
			stone_lines.append("Homestone %s: gesetzt" % KaissaRules.side_name(s))
		else:
			var left: int = PieceTypes.HOMESTONE_DEADLINE - rules.moves_made[s]
			stone_lines.append("Homestone %s: noch nicht gesetzt (spätestens in %d Zügen)" % [KaissaRules.side_name(s), left])
	homestone_label.text = "\n".join(stone_lines)

	var running := not rules.is_over()
	homestone_button.visible = running and not rules.homestone_placed[side]
	homestone_button.disabled = rules.homestone_placements(side).is_empty()
	homestone_button.text = "Homestone setzen" if not homestone_button.disabled \
		else "Homestone setzen (erste Reihe ist voll)"
	resign_button.disabled = not running
	draw_button.disabled = not running

	var lines: Array[String] = []
	for s in [PieceTypes.Side.YELLOW, PieceTypes.Side.RED]:
		var names: Array[String] = []
		for piece in rules.captured:
			if piece.side == s:
				names.append(PieceTypes.DEFINITIONS[piece.type].name)
		lines.append("%s verloren: %s" % [KaissaRules.side_name(s), ", ".join(names) if names else "–"])
	captured_label.text = "\n".join(lines)

func _on_promotion_requested(from: Vector2i, to: Vector2i) -> void:
	_pending_promotion = [from, to]
	promotion_box.visible = true
	board.set_process_unhandled_input(false)

func _promote(type: PieceTypes.Type) -> void:
	var move := _pending_promotion
	_hide_promotion()
	if move.size() == 2:
		board.complete_move(move[0], move[1], type)

func _hide_promotion() -> void:
	_pending_promotion = []
	promotion_box.visible = false
	board.set_process_unhandled_input(true)

func _on_hovered_piece(piece: Dictionary) -> void:
	if piece.is_empty():
		info_label.text = HINT
	else:
		info_label.text = "%s (%s)" % [PieceTypes.DEFINITIONS[piece.type].name, KaissaRules.side_name(piece.side)]
