extends SceneTree
## Bot-gegen-Bot-Partien ohne Fenster, um Eröffnungen zu untersuchen.
##
## Aufruf (vom Projektordner aus):
##   godot --headless --path . -s tools/bot_match.gd -- [Optionen]
##
## Modus "play" (Standard) spielt Partien und schreibt je Partie eine JSON-Zeile:
##   --games N          Anzahl Partien (Standard 10)
##   --yellow L --red L Stufe je Seite: easy, medium, hard, master (Standard hard)
##   --time MS          Denkzeit je Zug (Standard 300)
##   --random-plies K   die ersten K Halbzüge zufällig unter allen erlaubten Zügen (Standard 1)
##   --noise-plies K    danach K Halbzüge mit Zufallsrauschen --noise (Standard 8 / 40)
##   --opening "a b"    feste Zugfolge vor dem Zufall
##   --max-plies N      danach Abbruch und Wertung nach Stellung (Standard 200)
##   --book             Bots dürfen das Eröffnungsbuch nutzen (Standard aus)
##   --out DATEI        Ausgabedatei (Standard: Konsole), wird ergänzt
##   --seed S
## Modus "rank" bewertet jeden erlaubten Zug nach --opening mit einer Suche von --time ms.
## Modus "analyze" zeigt nach --opening die besten --lines Züge (Standard 3) wie im
##   Analysemodus, je gerechneter Tiefe eine Zeile, bis --time ms vergangen sind.
## Modus "checkbook" prüft, ob alle Züge in OpeningBook erlaubt sind.

const LEVELS := {"easy": KaissaAI.Level.EASY, "medium": KaissaAI.Level.MEDIUM,
	"hard": KaissaAI.Level.HARD, "master": KaissaAI.Level.MASTER}
## Ab diesem Vorsprung (Hundertstel Spearman) über ADJUDICATE_PLIES Halbzüge gilt die Partie als entschieden.
const ADJUDICATE_SCORE := 1500
const ADJUDICATE_PLIES := 10

var opts := {"mode": "play", "games": "10", "yellow": "hard", "red": "hard", "time": "300",
	"random-plies": "1", "noise-plies": "8", "noise": "40", "opening": "", "max-plies": "200",
	"out": "", "seed": "", "book": "false"}
var rng := RandomNumberGenerator.new()
var out_file: FileAccess

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var i := 0
	while i < args.size():
		var key := args[i].trim_prefix("--")
		if key == "book":
			opts.book = "true"
		elif i + 1 < args.size():
			opts[key] = args[i + 1]
			i += 1
		i += 1
	if opts.seed.is_empty():
		rng.randomize()
	else:
		rng.seed = int(opts.seed)
	if not opts.out.is_empty():
		out_file = FileAccess.open(opts.out, FileAccess.READ_WRITE if FileAccess.file_exists(opts.out) else FileAccess.WRITE)
		out_file.seek_end()
	if opts.mode == "rank":
		_rank()
	elif opts.mode == "analyze":
		_analyze()
	elif opts.mode == "checkbook":
		_check_book()
	else:
		for g in int(opts.games):
			_emit(_play_game())
	if out_file:
		out_file.close()
	quit()

func _emit(data: Dictionary) -> void:
	var line := JSON.stringify(data)
	if out_file:
		out_file.store_line(line)
		out_file.flush()
	print(line)

func _opening_moves() -> PackedStringArray:
	return opts.opening.split(" ", false)

## Spielt die feste Eröffnung; false, wenn ein Zug nicht erlaubt ist.
func _apply_opening(rules: KaissaRules, helper: KaissaAI) -> bool:
	for name in _opening_moves():
		var found := false
		for entry: Array in helper.named_actions(rules.clone()):
			if entry[0] == name:
				_apply(rules, entry[1])
				found = true
				break
		if not found:
			push_error("Zug %s ist nach %s nicht erlaubt" % [name, " ".join(rules.history)])
			return false
	return true

func _apply(rules: KaissaRules, action: Dictionary) -> void:
	if action.from == KaissaAI.NO_CELL:
		rules.place_homestone(action.to)
	else:
		rules.move(action.from, action.to, action.promotion)

func _make_ai(level_name: String) -> KaissaAI:
	var ai := KaissaAI.new(LEVELS[level_name])
	ai.time_limit_ms = int(opts.time)
	ai.use_book = opts.book == "true"
	return ai

func _play_game() -> Dictionary:
	var rules := KaissaRules.new()
	rules.reset()
	var helper := KaissaAI.new(KaissaAI.Level.HARD)
	var bots := [_make_ai(opts.yellow), _make_ai(opts.red)]
	if not _apply_opening(rules, helper):
		return {}
	var fixed := rules.history.size()
	var random_until := fixed + int(opts["random-plies"])
	var noise_until := random_until + int(opts["noise-plies"])
	var streak := 0
	var reason := ""
	var start := Time.get_ticks_msec()
	while not rules.is_over() and rules.history.size() < int(opts["max-plies"]):
		var ply := rules.history.size()
		var action: Dictionary
		if ply < random_until:
			var all := helper.named_actions(rules.clone())
			action = all[rng.randi_range(0, all.size() - 1)][1]
		else:
			var ai: KaissaAI = bots[rules.turn]
			ai.noise_override = int(opts.noise) if ply < noise_until else -1
			action = ai.choose_action(rules)
			if action.is_empty():
				break
		_apply(rules, action)
		if rules.is_over():
			break
		var score := helper.evaluate_for(rules, PieceTypes.Side.YELLOW)
		if score >= ADJUDICATE_SCORE:
			streak = maxi(streak, 0) + 1
		elif score <= -ADJUDICATE_SCORE:
			streak = mini(streak, 0) - 1
		else:
			streak = 0
		if absi(streak) >= ADJUDICATE_PLIES:
			reason = "Wertung nach Material"
			rules.winner = PieceTypes.Side.YELLOW if streak > 0 else PieceTypes.Side.RED
			break
	var result := "1/2"
	if rules.winner == PieceTypes.Side.YELLOW:
		result = "1-0"
	elif rules.winner == PieceTypes.Side.RED:
		result = "0-1"
	if reason.is_empty():
		reason = rules.result_text if rules.is_over() else "Zuglimit"
	return {"yellow": opts.yellow, "red": opts.red, "time_ms": int(opts.time),
		"result": result, "reason": reason, "plies": rules.history.size(),
		"final_eval": helper.evaluate_for(rules, PieceTypes.Side.YELLOW),
		"random_plies": random_until, "seconds": (Time.get_ticks_msec() - start) / 1000.0,
		"moves": rules.history}

## Bewertet jeden Zug nach der festen Eröffnung aus Sicht der ziehenden Seite.
func _rank() -> void:
	var rules := KaissaRules.new()
	rules.reset()
	var helper := KaissaAI.new(KaissaAI.Level.HARD)
	if not _apply_opening(rules, helper):
		return
	for entry: Array in helper.named_actions(rules.clone()):
		var copy := rules.clone()
		_apply(copy, entry[1])
		var score := KaissaAI.WIN
		var depth := 0
		if not copy.is_over():
			var ai := _make_ai(opts.yellow)
			ai.choose_action(copy)
			score = -ai.chosen_score
			depth = ai.reached_depth
		_emit({"opening": opts.opening, "move": entry[0], "score": score, "depth": depth,
			"level": opts.yellow, "time_ms": int(opts.time)})

func _analyze() -> void:
	var rules := KaissaRules.new()
	rules.reset()
	if not _apply_opening(rules, KaissaAI.new(KaissaAI.Level.HARD)):
		return
	var ai := KaissaAI.new(KaissaAI.Level.MASTER)
	var start := Time.get_ticks_msec()
	ai.analyze(rules, int(opts.get("lines", "3")), int(opts.time), func(info: Dictionary) -> void:
		var parts: Array[String] = []
		for line: Dictionary in info.lines:
			parts.append("%s %s" % [KaissaAI.score_text(line.score), " ".join(line.pv)])
		print("Tiefe %d, %d Stellungen, %d ms: %s" % [info.depth, info.nodes,
			Time.get_ticks_msec() - start, " | ".join(parts)]))

func _check_book() -> void:
	var helper := KaissaAI.new(KaissaAI.Level.HARD)
	var errors := 0
	for key: String in OpeningBook.LINES:
		opts.opening = key
		var rules := KaissaRules.new()
		rules.reset()
		if not _apply_opening(rules, helper):
			errors += 1
			continue
		var legal := {}
		for entry: Array in helper.named_actions(rules.clone()):
			legal[entry[0]] = true
		for name: String in OpeningBook.LINES[key]:
			if not legal.has(name):
				push_error("Buchzug %s nach \"%s\" ist nicht erlaubt" % [name, key])
				errors += 1
	print("Buchstellungen: %d, Fehler: %d" % [OpeningBook.LINES.size(), errors])
