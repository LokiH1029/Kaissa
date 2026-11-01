class_name TrainingPanel
extends PanelContainer
## Seitenleiste des Eröffnungstrainings: Liste der Eröffnungen und Übungsablauf.
##
## Der Spieler wählt eine Eröffnung oder Variante und eine Seite. Danach muss er auf
## seiner Seite Buchzüge finden, der Trainer antwortet für die Gegenseite aus dem Buch.
## Falsche Züge werden zurückgenommen.

## Der Spieler verlässt das Training.
signal closed
## Der Spieler will die Stellung gegen den Bot weiterspielen.
signal continue_against_bot(side: PieceTypes.Side)

const OPPONENT_DELAY := 0.7
const PROGRESS_FILE := "user://eroeffnungstraining.cfg"
const COLOR_GOOD := Color("8fd18b")
const COLOR_BAD := Color("ff8a7a")
const COLOR_NEUTRAL := Color("f4ead5")

var rules: KaissaRules
var board: BoardView
var trainer := OpeningTrainer.new()
## true, solange eine Übung läuft (auch wenn sie gerade zu Ende ist und auf eine Wahl wartet).
var active := false

var _tree: Tree
var _side_select: OptionButton
var _description: Label
var _start_button: Button
var _status: Label
var _feedback: Label
var _line_label: Label
var _hint_button: Button
var _solution_button: Button
var _again_button: Button
var _bot_button: Button

var _busy := false
## Länge der Zugfolge, die schon geprüft ist.
var _checked := 0
var _mistakes := 0
var _hints := 0
## Wird bei jedem Neustart erhöht; ältere Gegnerzüge verfallen dann.
var _token := 0
var _current_moves: Array[String] = []
var _progress := ConfigFile.new()

func setup(game_rules: KaissaRules, board_view: BoardView) -> void:
	rules = game_rules
	board = board_view
	rules.changed.connect(_on_rules_changed)
	_progress.load(PROGRESS_FILE)
	_build_ui()
	_fill_tree()

func _build_ui() -> void:
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	var title := Label.new()
	title.text = "Eröffnungen üben"
	title.add_theme_font_size_override("font_size", 32)
	box.add_child(title)

	var side_row := HBoxContainer.new()
	var side_label := Label.new()
	side_label.text = "Du spielst:"
	side_row.add_child(side_label)
	_side_select = OptionButton.new()
	_side_select.add_item("Gelb (Anzug)", PieceTypes.Side.YELLOW)
	_side_select.add_item("Rot (Antwort)", PieceTypes.Side.RED)
	_side_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side_row.add_child(_side_select)
	box.add_child(side_row)

	_tree = Tree.new()
	_tree.hide_root = true
	_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tree.custom_minimum_size = Vector2(0, 200)
	_tree.columns = 2
	_tree.set_column_expand(1, false)
	_tree.set_column_custom_minimum_width(1, 70)
	_tree.item_selected.connect(_on_item_selected)
	_tree.item_activated.connect(_start_selected)
	box.add_child(_tree)

	_description = _label(box)
	_description.custom_minimum_size = Vector2(0, 60)

	_start_button = Button.new()
	_start_button.text = "Üben starten"
	_start_button.pressed.connect(_start_selected)
	box.add_child(_start_button)

	_status = _label(box)
	_status.add_theme_font_size_override("font_size", 20)
	_feedback = _label(box)
	_line_label = _label(box)

	var row := HBoxContainer.new()
	_hint_button = _button(row, "Tipp", _show_hint)
	_solution_button = _button(row, "Lösung zeigen", _show_solution)
	box.add_child(row)
	var row2 := HBoxContainer.new()
	_again_button = _button(row2, "Nochmal", _restart_current)
	_bot_button = _button(row2, "Gegen Bot weiterspielen", _continue_against_bot)
	box.add_child(row2)

	var back := Button.new()
	back.text = "Zurück zum Spiel"
	back.pressed.connect(stop)
	box.add_child(back)
	_update_buttons()

func _label(parent: Control) -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label

func _button(parent: Control, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _fill_tree() -> void:
	_tree.clear()
	var root := _tree.create_item()
	var all: Array[String] = []
	var mixed := _add_item(root, "Alle Eröffnungen gemischt", all,
		"Der Trainer wählt die Eröffnung zufällig aus dem ganzen Buch.")
	for opening: Dictionary in OpeningTrainer.catalog():
		var item := _add_item(root, "%s · %s" % [opening.name, opening.moves[0]], opening.moves, opening.text)
		for variation: Dictionary in opening.variations:
			_add_item(item, variation.name, variation.moves, opening.text)
		item.collapsed = true
	mixed.select(0)

func _add_item(parent: TreeItem, text: String, moves: Array[String], description: String) -> TreeItem:
	var item := _tree.create_item(parent)
	item.set_text(0, text)
	item.set_metadata(0, {"moves": moves, "text": description})
	item.set_tooltip_text(0, " ".join(moves) if moves else "zufällig")
	_update_item_progress(item)
	return item

func _update_item_progress(item: TreeItem) -> void:
	var moves: Array[String] = item.get_metadata(0).moves
	var done := int(_progress.get_value("geschafft", _progress_key(moves), 0))
	item.set_text(1, "✓ %d" % done if done > 0 else "")
	item.set_tooltip_text(1, "%d-mal fehlerfrei geschafft" % done)

func _progress_key(moves: Array[String]) -> String:
	return "_".join(moves) if moves else "alle"

func _selected_moves() -> Array[String]:
	var item := _tree.get_selected()
	if item == null:
		return []
	return item.get_metadata(0).moves

func _on_item_selected() -> void:
	var item := _tree.get_selected()
	var data: Dictionary = item.get_metadata(0)
	var text: String = data.text
	if data.moves:
		text = "Zugfolge: %s\n%s" % [" ".join(data.moves), text]
	_description.text = text

func _start_selected() -> void:
	start(_selected_moves(), _side_select.get_selected_id())

## Startet eine Übung mit der Zugfolge [param moves] für die Seite [param side].
func start(moves: Array[String], side: PieceTypes.Side) -> void:
	active = true
	_current_moves = moves.duplicate()
	trainer.start(moves, side)
	_token += 1
	_mistakes = 0
	_hints = 0
	_feedback.text = ""
	_busy = true
	board.last_move.clear()
	board.clear_selection()
	rules.reset()
	_busy = false
	_checked = 0
	_advance()

func stop() -> void:
	active = false
	_token += 1
	closed.emit()

func _restart_current() -> void:
	start(_current_moves, trainer.player_side)

func _continue_against_bot() -> void:
	active = false
	_token += 1
	continue_against_bot.emit(trainer.player_side)

func _advance() -> void:
	_update_line()
	var history := rules.history
	if trainer.is_finished(history) or rules.is_over():
		_finish()
		return
	if rules.turn != trainer.player_side:
		board.accepts_moves = false
		_status.text = "Der Gegner antwortet …"
		var token := _token
		await get_tree().create_timer(OPPONENT_DELAY).timeout
		if token == _token and active:
			_play_opponent()
	else:
		board.accepts_moves = true
		_status.text = "Dein Zug als %s: Finde einen Buchzug." % KaissaRules.side_name(trainer.player_side)
	_update_buttons()

func _play_opponent() -> void:
	var name := trainer.opponent_move(rules.history)
	var action := rules.find_action(name)
	if action.is_empty():
		_finish()
		return
	_busy = true
	board.apply_action(action)
	_busy = false
	_checked = rules.history.size()
	_advance()

func _on_rules_changed() -> void:
	if active and not _busy and rules.history.size() > _checked:
		# Erst nach dem Zug prüfen, damit BoardView ihn vollständig abschließt.
		_check_last_move.call_deferred()

func _check_last_move() -> void:
	var history := rules.history
	if not active or history.size() <= _checked:
		return
	var move := history[history.size() - 1]
	var before: Array[String] = []
	for i in history.size() - 1:
		before.append(history[i])
	var expected := trainer.expected(before)
	match trainer.check_move(before, move):
		OpeningTrainer.Verdict.MAIN:
			var others := expected.slice(1)
			_say("Richtig, %s ist der Hauptzug." % move \
				+ (" Ebenfalls im Buch: %s." % ", ".join(others) if others else ""), COLOR_GOOD)
		OpeningTrainer.Verdict.BOOK:
			_say("Gut, %s steht im Buch. Der Hauptzug wäre %s." % [move, expected[0]], COLOR_GOOD)
		OpeningTrainer.Verdict.WRONG:
			_mistakes += 1
			_say("%s steht nicht im Buch. Versuch es noch einmal (Tipp hilft)." % move, COLOR_BAD)
			_replay(before)
	_checked = rules.history.size()
	_advance()

## Stellt die Stellung nach der Zugfolge [param moves] wieder her.
func _replay(moves: Array[String]) -> void:
	_busy = true
	board.clear_selection()
	rules.reset()
	board.last_move.clear()
	for name in moves:
		var action := rules.find_action(name)
		if action.is_empty():
			break
		rules.apply_name(name)
		var cells: Array[Vector2i] = [action.to]
		if action.from.x >= 0:
			cells.push_front(action.from)
		board.last_move = cells
	board.queue_redraw()
	_busy = false

func _finish() -> void:
	board.accepts_moves = false
	board.clear_selection()
	var plies := rules.history.size()
	if _mistakes == 0 and _hints == 0:
		_status.text = "Linie geschafft, fehlerfrei!"
		var key := _progress_key(_current_moves)
		_progress.set_value("geschafft", key, int(_progress.get_value("geschafft", key, 0)) + 1)
		_progress.save(PROGRESS_FILE)
		_refresh_progress(_tree.get_root())
	else:
		_status.text = "Linie geschafft."
	var extra := "Fehler: %d, Tipps: %d." % [_mistakes, _hints]
	_say("Ende des Buchs nach %d Halbzügen. %s Mit „Nochmal“ kommt eine andere Variante." % [plies, extra], COLOR_NEUTRAL)
	_update_buttons()

func _refresh_progress(item: TreeItem) -> void:
	for child in item.get_children():
		_update_item_progress(child)
		_refresh_progress(child)

func _show_hint() -> void:
	var move := _expected_move()
	if move.is_empty():
		return
	_hints += 1
	var action := rules.find_action(move)
	if action.from.x < 0:
		board.start_homestone_placement()
		_say("Tipp: Setze jetzt den Homestone.", COLOR_NEUTRAL)
		return
	board.clear_selection()
	board.selected = action.from
	board.targets = rules.legal_moves(action.from)
	board.queue_redraw()
	var piece := rules.piece_at(action.from)
	_say("Tipp: Ziehe mit dem %s auf %s." % [PieceTypes.DEFINITIONS[piece.type].name,
		KaissaRules.cell_name(action.from)], COLOR_NEUTRAL)

func _show_solution() -> void:
	var move := _expected_move()
	if move.is_empty():
		return
	_hints += 1
	var action := rules.find_action(move)
	board.clear_selection()
	if action.from.x < 0:
		board.placing_homestone = true
	else:
		board.selected = action.from
	var target: Array[Vector2i] = [action.to]
	board.targets = target
	board.queue_redraw()
	_say("Lösung: %s. Klicke das markierte Feld an." % move, COLOR_NEUTRAL)

func _expected_move() -> String:
	if not active or rules.turn != trainer.player_side:
		return ""
	var moves := trainer.expected(rules.history)
	return moves[0] if moves else ""

func _say(text: String, color: Color) -> void:
	_feedback.text = text
	_feedback.add_theme_color_override("font_color", color)

func _update_line() -> void:
	var parts: Array[String] = []
	var history := rules.history
	for i in history.size():
		if i % 2 == 0:
			parts.append("%d. %s" % [i / 2 + 1, history[i]])
		else:
			parts[parts.size() - 1] += " " + history[i]
	_line_label.text = "Zugfolge: " + (" ".join(parts) if parts else "–")

func _update_buttons() -> void:
	var waiting := active and not rules.is_over() and rules.turn == trainer.player_side \
		and not trainer.is_finished(rules.history)
	_hint_button.disabled = not waiting
	_solution_button.disabled = not waiting
	var finished := active and trainer.is_finished(rules.history)
	_again_button.disabled = not active
	_bot_button.disabled = not finished or rules.is_over()
