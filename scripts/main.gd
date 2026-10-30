extends Node2D
## Hauptszene: verbindet Spielregeln, Brett und Seitenleiste.

@onready var board: BoardView = $Board
@onready var status_label: Label = %StatusLabel
@onready var info_label: Label = %InfoLabel
@onready var captured_label: Label = %CapturedLabel
@onready var restart_button: Button = %RestartButton

var rules := KaissaRules.new()

func _ready() -> void:
	board.setup(rules)
	rules.changed.connect(_update_ui)
	rules.game_over.connect(_on_game_over)
	board.hovered_piece.connect(_on_hovered_piece)
	restart_button.pressed.connect(_restart)
	get_viewport().size_changed.connect(_layout)
	_layout()
	_restart()

func _restart() -> void:
	board.last_move.clear()
	board.clear_selection()
	rules.reset()

func _layout() -> void:
	var viewport := get_viewport_rect().size
	var margin := (viewport.y - board.board_pixel_size()) * 0.5
	board.position = Vector2(maxf(margin, 24.0), maxf(margin, 24.0))

func _update_ui() -> void:
	if rules.winner == -1:
		status_label.text = "%s ist am Zug" % KaissaRules.side_name(rules.turn)
	var lines: Array[String] = []
	for side in [PieceTypes.Side.YELLOW, PieceTypes.Side.RED]:
		var names: Array[String] = []
		for piece in rules.captured:
			if piece.side == side:
				names.append(PieceTypes.DEFINITIONS[piece.type].name)
		lines.append("%s verloren: %s" % [KaissaRules.side_name(side), ", ".join(names) if names else "–"])
	captured_label.text = "\n".join(lines)

func _on_game_over(winner: PieceTypes.Side) -> void:
	status_label.text = "%s gewinnt!" % KaissaRules.side_name(winner)

func _on_hovered_piece(piece: Dictionary) -> void:
	if piece.is_empty():
		info_label.text = "Figur anklicken, um ihre Züge zu sehen.\nRechtsklick hebt die Auswahl auf."
	else:
		info_label.text = "%s (%s)" % [PieceTypes.DEFINITIONS[piece.type].name, KaissaRules.side_name(piece.side)]
