extends SceneTree
## Prüft das Eröffnungstraining ohne Fenster:
##   godot --headless --script res://tools/test_opening_trainer.gd
##
## 1. Jede Buchstellung lässt sich mit KaissaRules.apply_name nachspielen und jeder Buchzug ist erlaubt.
## 2. Die Eröffnungsliste ist gefüllt.
## 3. Eine Übung in der Hauptszene läuft für beide Seiten bis zum Ende des Buchs,
##    falsche Züge werden zurückgenommen.

var _failures := 0

func _initialize() -> void:
	_check_book()
	_check_catalog()
	await _check_scene()
	print("FEHLER: %d" % _failures if _failures else "Alles in Ordnung.")
	quit(1 if _failures else 0)

func _fail(text: String) -> void:
	_failures += 1
	printerr(text)

func _check_book() -> void:
	var positions := 0
	for key: String in OpeningBook.LINES:
		var rules := KaissaRules.new()
		rules.reset()
		for name in key.split(" ", false):
			if not rules.apply_name(name):
				_fail("Zug %s in %s nicht spielbar" % [name, key])
				break
		for move: String in OpeningBook.LINES[key]:
			if rules.find_action(move).is_empty():
				_fail("Buchzug %s nach '%s' nicht erlaubt" % [move, key])
		positions += 1
	print("Buchstellungen geprüft: %d" % positions)

func _check_catalog() -> void:
	var catalog := OpeningTrainer.catalog()
	var variations := 0
	for opening: Dictionary in catalog:
		variations += opening.variations.size()
		print("  %s (%s): %d Varianten" % [opening.name, opening.moves[0], opening.variations.size()])
	if catalog.size() < 5:
		_fail("Zu wenige Eröffnungen: %d" % catalog.size())
	print("Eröffnungen: %d, Varianten: %d" % [catalog.size(), variations])

func _check_scene() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main._open_training()
	var panel: TrainingPanel = main.training_panel
	var rules: KaissaRules = main.rules
	for side in [PieceTypes.Side.YELLOW, PieceTypes.Side.RED]:
		for opening: Dictionary in OpeningTrainer.catalog():
			panel.start(opening.moves, side)
			var wrong_tried := false
			var guard := 0
			while not panel.trainer.is_finished(rules.history) and guard < 40:
				guard += 1
				if rules.turn != side:
					await create_timer(TrainingPanel.OPPONENT_DELAY + 0.1).timeout
					continue
				var expected := panel.trainer.expected(rules.history)
				if not wrong_tried:
					wrong_tried = true
					var before := rules.history.size()
					var wrong := _some_wrong_move(rules, expected)
					main.board.apply_action(rules.find_action(wrong))
					await process_frame
					await process_frame
					if rules.history.size() != before:
						_fail("Falscher Zug %s wurde nicht zurückgenommen" % wrong)
				main.board.apply_action(rules.find_action(expected[expected.size() - 1]))
				await process_frame
				await process_frame
			if not panel.trainer.is_finished(rules.history):
				_fail("Übung %s für %s endet nicht" % [opening.moves, KaissaRules.side_name(side)])
			elif side == PieceTypes.Side.YELLOW:
				print("  %s: %s" % [opening.name, " ".join(rules.history)])
	panel.stop()
	print("Übungen in der Szene durchgespielt.")

## Ein erlaubter Zug, der nicht im Buch steht.
func _some_wrong_move(rules: KaissaRules, expected: Array[String]) -> String:
	for cell: Vector2i in rules.pieces:
		if not rules.can_select(cell):
			continue
		for to in rules.legal_moves(cell):
			var name := KaissaRules.action_name(cell, to, not rules.piece_at(to).is_empty())
			if not expected.has(name):
				return name
	return ""
