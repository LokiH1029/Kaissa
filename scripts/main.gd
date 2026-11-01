extends Node2D
## Hauptszene: verbindet Spielregeln, Brett und Seitenleiste.

const HINT := "Figur anklicken, um ihre Züge zu sehen.\nRechtsklick hebt die Auswahl auf."
## Auswahl je Seite. Index 0 = Mensch, Index n = Bot mit KaissaAI.Level n - 1.
const PLAYER_OPTIONS: Array[String] = ["Mensch", "Bot (leicht)", "Bot (mittel)", "Bot (schwer)", "Bot (Meister)"]
const HUMAN := -1
## So lange zeigt der Bot mindestens "denkt nach", damit seine Züge sichtbar bleiben.
const BOT_MIN_DELAY_MS := 500
## Der Bot nimmt ein Remis an, solange er nicht mehr als so viel vorn liegt
## (Hundertstel Spearman).
const BOT_DRAW_MARGIN := 50

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
@onready var yellow_player: OptionButton = %YellowPlayer
@onready var red_player: OptionButton = %RedPlayer
@onready var training_button: Button = %TrainingButton
@onready var side_panel: PanelContainer = $UI/Panel

var rules := KaissaRules.new()
var _pending_promotion: Array[Vector2i] = []
## Je Seite HUMAN oder ein KaissaAI.Level. Standard: Mensch (Gelb) gegen Bot (Rot).
var players: Array[int] = [HUMAN, KaissaAI.Level.MEDIUM]
var _bot_thread: Thread
var _bot_ai: KaissaAI
## Wird bei Neustart oder Spielerwechsel erhöht; ältere Bot-Ergebnisse verfallen dann.
var _bot_request := 0
## Seitenleiste des Eröffnungstrainings; solange sie offen ist, ruht der Bot.
var training_panel: TrainingPanel
var _training := false

func _ready() -> void:
	board.setup(rules)
	rules.changed.connect(_update_ui)
	board.hovered_piece.connect(_on_hovered_piece)
	board.promotion_requested.connect(_on_promotion_requested)
	homestone_button.pressed.connect(board.start_homestone_placement)
	promote_rider_button.pressed.connect(_promote.bind(PieceTypes.Type.RIDER))
	promote_tarnsman_button.pressed.connect(_promote.bind(PieceTypes.Type.TARNSMAN))
	resign_button.pressed.connect(_resign)
	draw_button.pressed.connect(_offer_draw)
	_setup_player_select(yellow_player, PieceTypes.Side.YELLOW)
	_setup_player_select(red_player, PieceTypes.Side.RED)
	restart_button.pressed.connect(_restart)
	_setup_training()
	get_viewport().size_changed.connect(_layout)
	_layout()
	_restart()

func _exit_tree() -> void:
	_cancel_bot()
	if _bot_thread != null:
		_bot_thread.wait_to_finish()
		_bot_thread = null

func _restart() -> void:
	_cancel_bot()
	_hide_promotion()
	board.last_move.clear()
	board.clear_selection()
	rules.reset()

func _layout() -> void:
	var viewport := get_viewport_rect().size
	var margin := (viewport.y - board.board_pixel_size()) * 0.5
	board.position = Vector2(maxf(margin, 24.0), maxf(margin, 24.0))

func _update_ui() -> void:
	if _training:
		return
	var side := rules.turn
	var bot_turn := is_bot(side) and not rules.is_over()
	board.accepts_moves = not bot_turn
	if rules.is_over():
		status_label.text = rules.result_text
		board.clear_selection()
	elif bot_turn:
		status_label.text = "%s denkt nach …" % _player_name(side)
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
	homestone_button.visible = running and not bot_turn and not rules.homestone_placed[side]
	homestone_button.disabled = rules.homestone_placements(side).is_empty()
	homestone_button.text = "Homestone setzen" if not homestone_button.disabled \
		else "Homestone setzen (erste Reihe ist voll)"
	var any_human := not is_bot(PieceTypes.Side.YELLOW) or not is_bot(PieceTypes.Side.RED)
	resign_button.disabled = not running or not any_human
	draw_button.disabled = not running or not any_human

	var lines: Array[String] = []
	for s in [PieceTypes.Side.YELLOW, PieceTypes.Side.RED]:
		var names: Array[String] = []
		for piece in rules.captured:
			if piece.side == s:
				names.append(PieceTypes.DEFINITIONS[piece.type].name)
		lines.append("%s verloren: %s" % [KaissaRules.side_name(s), ", ".join(names) if names else "–"])
	captured_label.text = "\n".join(lines)
	_maybe_start_bot()

func is_bot(side: PieceTypes.Side) -> bool:
	return players[side] != HUMAN

func _player_name(side: PieceTypes.Side) -> String:
	if not is_bot(side):
		return KaissaRules.side_name(side)
	return "%s (Bot, %s)" % [KaissaRules.side_name(side), KaissaAI.LEVEL_NAMES[players[side]]]

func _setup_player_select(button: OptionButton, side: PieceTypes.Side) -> void:
	button.clear()
	for i in PLAYER_OPTIONS.size():
		button.add_item(PLAYER_OPTIONS[i], i)
	button.select(players[side] + 1)
	button.item_selected.connect(_on_player_selected.bind(side))

func _on_player_selected(index: int, side: PieceTypes.Side) -> void:
	players[side] = index - 1
	_cancel_bot()
	if is_bot(side) and rules.turn == side:
		_hide_promotion()
		board.clear_selection()
	_update_ui()

## Die Seite des einzigen menschlichen Spielers, sonst die Seite am Zug.
func _human_side() -> PieceTypes.Side:
	if is_bot(PieceTypes.Side.RED) and not is_bot(PieceTypes.Side.YELLOW):
		return PieceTypes.Side.YELLOW
	if is_bot(PieceTypes.Side.YELLOW) and not is_bot(PieceTypes.Side.RED):
		return PieceTypes.Side.RED
	return rules.turn

func _resign() -> void:
	_cancel_bot()
	rules.resign(_human_side())

func _offer_draw() -> void:
	var human := _human_side()
	var opponent := KaissaRules.other(human)
	if is_bot(opponent):
		var score := KaissaAI.new(players[opponent]).evaluate_for(rules, opponent)
		if score > BOT_DRAW_MARGIN:
			info_label.text = "%s lehnt das Remis ab." % _player_name(opponent)
			return
	_cancel_bot()
	rules.agree_draw()

## Startet den Bot in einem eigenen Thread, wenn er am Zug ist.
func _maybe_start_bot() -> void:
	if _training or rules.is_over() or not is_bot(rules.turn) or _bot_thread != null:
		return
	_bot_request += 1
	_bot_ai = KaissaAI.new(players[rules.turn])
	_bot_thread = Thread.new()
	_bot_thread.start(_bot_think.bind(_bot_ai, rules.clone(), _bot_request))

func _bot_think(ai: KaissaAI, snapshot: KaissaRules, request: int) -> void:
	var start := Time.get_ticks_msec()
	var action := ai.choose_action(snapshot)
	var wait := BOT_MIN_DELAY_MS - (Time.get_ticks_msec() - start)
	if wait > 0 and not ai.cancelled:
		OS.delay_msec(wait)
	_on_bot_done.call_deferred(request, action)

func _on_bot_done(request: int, action: Dictionary) -> void:
	_bot_thread.wait_to_finish()
	_bot_thread = null
	_bot_ai = null
	if request == _bot_request and not rules.is_over() and is_bot(rules.turn) and not action.is_empty():
		board.apply_action(action)
	else:
		# Veraltetes Ergebnis (Neustart oder Spielerwechsel): neu entscheiden.
		_update_ui()

func _cancel_bot() -> void:
	_bot_request += 1
	if _bot_ai != null:
		_bot_ai.cancelled = true

func _setup_training() -> void:
	training_panel = TrainingPanel.new()
	training_panel.visible = false
	$UI.add_child(training_panel)
	for property in ["anchor_left", "anchor_top", "anchor_right", "anchor_bottom",
			"offset_left", "offset_top", "offset_right", "offset_bottom", "grow_horizontal", "grow_vertical"]:
		training_panel.set(property, side_panel.get(property))
	training_panel.setup(rules, board)
	training_panel.closed.connect(_close_training)
	training_panel.continue_against_bot.connect(_continue_after_training)
	training_button.pressed.connect(_open_training)

func _open_training() -> void:
	_cancel_bot()
	_hide_promotion()
	_training = true
	board.accepts_moves = false
	board.clear_selection()
	side_panel.visible = false
	training_panel.visible = true

func _leave_training() -> void:
	_training = false
	training_panel.visible = false
	side_panel.visible = true

func _close_training() -> void:
	_leave_training()
	_restart()

## Nach einer Übung spielt der Bot die Gegenseite in derselben Stellung weiter.
func _continue_after_training(side: PieceTypes.Side) -> void:
	_leave_training()
	var opponent := KaissaRules.other(side)
	players[side] = HUMAN
	if not is_bot(opponent):
		players[opponent] = KaissaAI.Level.MEDIUM
	yellow_player.select(players[PieceTypes.Side.YELLOW] + 1)
	red_player.select(players[PieceTypes.Side.RED] + 1)
	board.clear_selection()
	_update_ui()

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
