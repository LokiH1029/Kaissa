class_name AnalysisPanel
extends VBoxContainer
## Analysemodus wie bei Lichess: Die Engine (Meister-Suche) rechnet die Stellung
## auf dem Brett laufend durch und zeigt die besten Züge mit Bewertung,
## Hauptvariante und Pfeilen. Beide Seiten werden von Hand gezogen; mit der
## Zugliste (oder den Pfeiltasten) springt man zu jeder früheren Stellung, ein
## neuer Zug dort beginnt eine neue Variante.
##
## Die Oberfläche wird im Code gebaut; main.gd ruft [method setup] und
## [method set_active] auf.

## Wird ausgelöst, wenn die Stellung über die Zugliste gewechselt wurde.
signal position_jumped

## So viele beste Züge zeigt die Analyse.
const LINES := 3
## So lange rechnet die Engine höchstens an einer Stellung.
const TIME_MS := 60000
const ARROW_COLORS: Array[Color] = [Color(0.1, 0.55, 0.2, 0.85), Color(0.1, 0.35, 0.8, 0.6), Color(0.1, 0.35, 0.8, 0.4)]
const ARROW_WIDTHS: Array[float] = [12.0, 8.0, 6.0]
const BAR_YELLOW := Color("f6d86b")
const BAR_RED := Color("5e0f0a")

var active := false
var rules: KaissaRules
var board: BoardView

## Stellungen der Zugliste: Index 0 = Startstellung, Index i = nach dem i-ten Halbzug.
var _line: Array[KaissaRules] = []
var _index := 0
var _jumping := false
var _lines: Array = []

var _thread: Thread
var _ai: KaissaAI
var _request := 0
var _restart_pending := false

var _eval_bar: ProgressBar
var _eval_label: Label
var _depth_label: Label
var _engine_toggle: CheckButton
var _line_buttons: Array[Button] = []
var _moves_text: RichTextLabel
var _nav_buttons: Array[Button] = []

func _ready() -> void:
	add_theme_constant_override("separation", 8)
	_build_ui()
	visible = false

func setup(game_rules: KaissaRules, board_view: BoardView) -> void:
	rules = game_rules
	board = board_view
	rules.changed.connect(_on_rules_changed)

func _exit_tree() -> void:
	_request += 1
	if _ai != null:
		_ai.cancelled = true
	if _thread != null:
		_thread.wait_to_finish()
		_thread = null

## Schaltet den Analysemodus ein oder aus. Beim Einschalten wird die bisherige
## Partie als Zugliste übernommen.
func set_active(on: bool) -> void:
	active = on
	visible = on
	if on:
		_rebuild_line()
		_restart_engine()
	else:
		_stop_engine()
		board.set_arrows([])

# --- Oberfläche ---

func _build_ui() -> void:
	var title := Label.new()
	title.text = "Analyse"
	title.add_theme_font_size_override("font_size", 22)
	add_child(title)

	var eval_row := HBoxContainer.new()
	eval_row.add_theme_constant_override("separation", 10)
	_eval_label = Label.new()
	_eval_label.custom_minimum_size = Vector2(72, 0)
	_eval_label.add_theme_font_size_override("font_size", 24)
	_eval_label.text = "0.00"
	eval_row.add_child(_eval_label)
	_eval_bar = ProgressBar.new()
	_eval_bar.show_percentage = false
	_eval_bar.min_value = 0
	_eval_bar.max_value = 1000
	_eval_bar.value = 500
	_eval_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_eval_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_eval_bar.custom_minimum_size = Vector2(0, 22)
	_eval_bar.tooltip_text = "Gelb links, Rot rechts"
	var fill := StyleBoxFlat.new()
	fill.bg_color = BAR_YELLOW
	var back := StyleBoxFlat.new()
	back.bg_color = BAR_RED
	back.border_color = Color("2b1d14")
	back.set_border_width_all(1)
	_eval_bar.add_theme_stylebox_override("fill", fill)
	_eval_bar.add_theme_stylebox_override("background", back)
	eval_row.add_child(_eval_bar)
	add_child(eval_row)

	var engine_row := HBoxContainer.new()
	_engine_toggle = CheckButton.new()
	_engine_toggle.text = "Engine"
	_engine_toggle.button_pressed = true
	_engine_toggle.toggled.connect(func(_on: bool) -> void: _restart_engine())
	engine_row.add_child(_engine_toggle)
	_depth_label = Label.new()
	_depth_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_depth_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_depth_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.65))
	engine_row.add_child(_depth_label)
	add_child(engine_row)

	for i in LINES:
		var button := Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.clip_text = true
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button.custom_minimum_size = Vector2(0, 30)
		button.tooltip_text = "Klicken spielt diesen Zug"
		button.pressed.connect(_play_line.bind(i))
		_line_buttons.append(button)
		add_child(button)

	var nav := HBoxContainer.new()
	var nav_items := [["|◀", "Zur Startstellung (Pos1)"], ["◀", "Einen Zug zurück (Pfeil links)"],
		["▶", "Einen Zug vor (Pfeil rechts)"], ["▶|", "Zur letzten Stellung (Ende)"]]
	for i in nav_items.size():
		var button := Button.new()
		button.text = nav_items[i][0]
		button.tooltip_text = nav_items[i][1]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_nav.bind(i))
		_nav_buttons.append(button)
		nav.add_child(button)
	add_child(nav)

	_moves_text = RichTextLabel.new()
	_moves_text.bbcode_enabled = true
	_moves_text.custom_minimum_size = Vector2(0, 96)
	_moves_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_moves_text.scroll_following = false
	_moves_text.meta_clicked.connect(func(meta: Variant) -> void: jump_to(int(str(meta))))
	add_child(_moves_text)

func _unhandled_input(event: InputEvent) -> void:
	if not active or not event is InputEventKey or not event.pressed:
		return
	match event.keycode:
		KEY_LEFT:
			_on_nav(1)
		KEY_RIGHT:
			_on_nav(2)
		KEY_HOME:
			_on_nav(0)
		KEY_END:
			_on_nav(3)
		_:
			return
	get_viewport().set_input_as_handled()

func _on_nav(which: int) -> void:
	match which:
		0: jump_to(0)
		1: jump_to(_index - 1)
		2: jump_to(_index + 1)
		3: jump_to(_line.size() - 1)

func _update_moves() -> void:
	var parts: Array[String] = []
	for i in range(1, _line.size()):
		var name: String = _line[i].history[i - 1]
		var text := "[url=%d]%s[/url]" % [i, name]
		if i == _index:
			text = "[bgcolor=#e3b34166][b]%s[/b][/bgcolor]" % text
		if i % 2 == 1:
			text = "%d. %s" % [(i + 1) / 2, text]
		parts.append(text)
	if parts.is_empty():
		_moves_text.text = "[color=#ffffffa0]Noch keine Züge. Ziehe für beide Seiten oder klicke einen Engine-Zug an.[/color]"
	else:
		_moves_text.text = " ".join(parts)
	_nav_buttons[0].disabled = _index == 0
	_nav_buttons[1].disabled = _index == 0
	_nav_buttons[2].disabled = _index >= _line.size() - 1
	_nav_buttons[3].disabled = _index >= _line.size() - 1

func _show_lines() -> void:
	var running := _engine_toggle.button_pressed
	for i in LINES:
		var button := _line_buttons[i]
		if i < _lines.size():
			var line: Dictionary = _lines[i]
			button.text = "%s   %s" % [KaissaAI.score_text(line.score), " ".join(line.pv)]
			button.disabled = false
			button.visible = true
		else:
			button.text = ""
			button.disabled = true
			button.visible = running and not rules.is_over()
	var arrows: Array[Dictionary] = []
	for i in _lines.size():
		var action: Dictionary = _lines[i].action
		arrows.append({"from": action.from, "to": action.to, "color": ARROW_COLORS[i], "width": ARROW_WIDTHS[i]})
	arrows.reverse()
	board.set_arrows(arrows)
	if not _lines.is_empty():
		_set_eval(_lines[0].score)

func _set_eval(score: int) -> void:
	_eval_label.text = KaissaAI.score_text(score)
	var share: float
	if KaissaAI.is_win_score(score):
		share = 1.0 if score > 0 else 0.0
	else:
		# Ein Vorsprung von vier Spearmen füllt den Balken etwa zu drei Vierteln.
		share = 1.0 / (1.0 + exp(-score / 400.0))
	_eval_bar.value = share * 1000.0

func _play_line(i: int) -> void:
	if i >= _lines.size() or rules.is_over():
		return
	board.apply_action(_lines[i].action)

# --- Zugliste ---

## Übernimmt die bisherige Partie als Zugliste, indem sie aus der
## Startstellung nachgespielt wird.
func _rebuild_line() -> void:
	_line.clear()
	var replay := KaissaRules.new()
	replay.reset()
	_line.append(replay.clone())
	var helper := KaissaAI.new(KaissaAI.Level.EASY)
	for name in rules.history:
		var found := false
		for entry: Array in helper.named_actions(replay):
			if entry[0] == name:
				_apply(replay, entry[1])
				found = true
				break
		if not found:
			break
		_line.append(replay.clone())
	# Die letzte Stellung exakt übernehmen (z.B. nach Aufgabe ist die Partie beendet).
	_line[_line.size() - 1] = rules.clone()
	_index = _line.size() - 1
	_update_moves()

static func _apply(target: KaissaRules, action: Dictionary) -> void:
	if action.from.x < 0:
		target.place_homestone(action.to)
	else:
		target.move(action.from, action.to, action.promotion)

## Springt zur Stellung nach dem [param index]-ten Halbzug der Zugliste.
func jump_to(index: int) -> void:
	if not active or index < 0 or index >= _line.size() or index == _index:
		return
	_index = index
	_jumping = true
	board.clear_selection()
	rules.copy_from(_line[index])
	board.last_move.clear()
	if not rules.history.is_empty():
		board.last_move = _cells_of(rules.history[-1])
	board.queue_redraw()
	_jumping = false
	position_jumped.emit()
	_update_moves()
	_restart_engine()

## Felder eines Zugs in Kurzschreibweise (für die Markierung des letzten Zugs).
static func _cells_of(name: String) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var regex := RegEx.create_from_string("([a-j])(10|[1-9])")
	for m in regex.search_all(name):
		result.append(Vector2i(m.get_string(1).unicode_at(0) - 97, int(m.get_string(2)) - 1))
	return result

func _on_rules_changed() -> void:
	if not active or _jumping:
		return
	var current := _line[_index]
	var size := rules.history.size()
	if size == current.history.size() + 1 and rules.history.slice(0, size - 1) == current.history:
		# Neuer Zug: Folgt er der Zugliste, nur weitergehen, sonst neue Variante.
		if _index + 1 < _line.size() and _line[_index + 1].history == rules.history:
			_index += 1
		else:
			_line.resize(_index + 1)
			_line.append(rules.clone())
			_index += 1
	elif size == current.history.size() and rules.history == current.history:
		# Gleiche Stellung, z.B. Aufgabe oder Remis: Stand übernehmen.
		_line[_index] = rules.clone()
	else:
		# Neues Spiel oder anderer Stand: Zugliste neu aufbauen.
		_rebuild_line()
	_update_moves()
	_restart_engine()

# --- Engine im Hintergrund ---

func _restart_engine() -> void:
	_request += 1
	_lines = []
	if _ai != null:
		_ai.cancelled = true
	if not active:
		return
	var on := _engine_toggle.button_pressed
	if not on:
		_depth_label.text = "aus"
	elif rules.is_over():
		_depth_label.text = rules.result_text
	else:
		_depth_label.text = "rechnet …"
	_show_lines()
	if rules.is_over():
		if rules.winner == PieceTypes.Side.YELLOW:
			_set_eval(KaissaAI.WIN)
		elif rules.winner == PieceTypes.Side.RED:
			_set_eval(-KaissaAI.WIN)
		else:
			_set_eval(0)
	if not on or rules.is_over():
		return
	if _thread != null:
		_restart_pending = true
		return
	_launch()

func _stop_engine() -> void:
	_request += 1
	_lines = []
	if _ai != null:
		_ai.cancelled = true

func _launch() -> void:
	_restart_pending = false
	if not active or not _engine_toggle.button_pressed or rules.is_over():
		return
	_ai = KaissaAI.new(KaissaAI.Level.MASTER)
	_thread = Thread.new()
	_thread.start(_run.bind(_ai, rules.clone(), _request))

func _run(ai: KaissaAI, snapshot: KaissaRules, request: int) -> void:
	var report := func(info: Dictionary) -> void:
		_on_progress.call_deferred(request, info)
	ai.analyze(snapshot, LINES, TIME_MS, report)
	_on_finished.call_deferred(request)

func _on_progress(request: int, info: Dictionary) -> void:
	if request != _request or not active:
		return
	_lines = info.lines
	_depth_label.text = "Tiefe %d · %s Stellungen" % [info.depth, _thousands(info.nodes)]
	_show_lines()

func _on_finished(request: int) -> void:
	_thread.wait_to_finish()
	_thread = null
	_ai = null
	if request == _request and active and not _lines.is_empty():
		_depth_label.text += " · fertig"
	if _restart_pending:
		_launch()

static func _thousands(value: int) -> String:
	var text := str(value)
	var result := ""
	while text.length() > 3:
		result = "." + text.right(3) + result
		text = text.left(text.length() - 3)
	return text + result
