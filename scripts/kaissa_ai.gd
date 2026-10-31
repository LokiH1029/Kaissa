class_name KaissaAI
extends RefCounted
## Computergegner für Kaissa.
##
## Der Bot sucht mit Alpha-Beta-Suche (Negamax) nach dem besten Zug und
## bewertet Stellungen nach Material, Fortschritt der Spearmen und der
## Sicherheit des Homestone. Die Suche läuft auf einer Kopie des Spielstands
## (siehe [method KaissaRules.clone]), damit sie in einem eigenen Thread
## laufen kann, ohne das Spiel zu verändern.

enum Level { EASY, MEDIUM, HARD }

const LEVEL_NAMES := {
	Level.EASY: "leicht",
	Level.MEDIUM: "mittel",
	Level.HARD: "schwer",
}

## Suchtiefe, Zeitlimit (ms), Zufallsrauschen auf die Bewertung der eigenen
## Züge (Hundertstel Spearman) und ob Schlagabfolgen zu Ende gerechnet werden.
const SETTINGS := {
	Level.EASY:   {"depth": 1, "time_ms": 1000, "noise": 250, "quiescence": false},
	Level.MEDIUM: {"depth": 2, "time_ms": 2000, "noise": 30, "quiescence": false},
	Level.HARD:   {"depth": 4, "time_ms": 4000, "noise": 0, "quiescence": true},
}

## Ungefährer Wert der Figuren in Hundertstel Spearman.
const VALUES := {
	PieceTypes.Type.UBAR: 900,
	PieceTypes.Type.UBARA: 600,
	PieceTypes.Type.TARNSMAN: 400,
	PieceTypes.Type.SCRIBE: 330,
	PieceTypes.Type.BUILDER: 500,
	PieceTypes.Type.INITIATE: 350,
	PieceTypes.Type.SPEARMAN: 100,
	PieceTypes.Type.RIDER: 250,
	PieceTypes.Type.PHYSICIAN: 350,
	PieceTypes.Type.HOMESTONE: 0,
}

const WIN := 1000000
const NO_CELL := Vector2i(-1, -1)
const MAX_QUIESCENCE := 3
const MAX_PLY := 32

## Wird von außen gesetzt, um eine laufende Suche abzubrechen.
var cancelled := false
var level: Level = Level.MEDIUM
## Anzahl der untersuchten Stellungen der letzten Suche (für Tests).
var nodes := 0
## Erreichte Suchtiefe der letzten Suche.
var reached_depth := 0

var _r: KaissaRules
var _deadline := 0
var _aborted := false
var _rng := RandomNumberGenerator.new()
## Je Suchtiefe zwei ruhige Züge, die zuletzt einen Schnitt bewirkt haben.
var _killers: Array = []

func _init(new_level: Level = Level.MEDIUM) -> void:
	level = new_level
	_rng.randomize()

## Liefert die beste Aktion für die Seite am Zug, oder ein leeres Dictionary.
## Ergebnis: {"from": Vector2i, "to": Vector2i, "promotion": int}; beim Setzen
## des Homestone ist "from" = (-1, -1) und "to" das Zielfeld.
func choose_action(rules: KaissaRules) -> Dictionary:
	_r = rules.clone()
	nodes = 0
	reached_depth = 0
	_aborted = false
	_killers.clear()
	for i in MAX_PLY:
		_killers.append([[], []])
	var settings: Dictionary = SETTINGS[level]
	_deadline = Time.get_ticks_msec() + settings.time_ms

	var actions := _actions(_r.turn, false)
	if actions.is_empty():
		return {}
	actions.shuffle()
	_order(actions)
	var best: Array = actions[0]
	# Iterative Vertiefung: Wird die Zeit knapp, gilt das Ergebnis der letzten
	# vollständig gerechneten Tiefe.
	for depth in range(1, settings.depth + 1):
		var scored := _search_root(actions, depth, settings.noise, settings.quiescence)
		if _aborted or cancelled:
			break
		reached_depth = depth
		scored.sort_custom(func(a, b): return a[0] > b[0])
		actions.clear()
		for entry in scored:
			actions.append(entry[1])
		best = actions[0]
		if scored[0][0] >= WIN - 1000:
			break
	return {"from": best[0], "to": best[1], "promotion": best[2]}

## Bewertet die Stellung aus Sicht von [param side] (positiv = gut für [param side]).
func evaluate_for(rules: KaissaRules, side: PieceTypes.Side) -> int:
	_r = rules
	var score := _evaluate()
	return score if rules.turn == side else -score

func _search_root(actions: Array, depth: int, noise: int, quiescence: bool) -> Array:
	var scored: Array = []
	var alpha := -WIN * 2
	for action: Array in actions:
		var undo := _do(action)
		var score: int
		if undo.captured_homestone:
			score = WIN
		else:
			# Mit Rauschen wird jeder Zug genau bewertet, sonst reicht ein Nullfenster.
			var bound := -WIN * 2 if noise > 0 else alpha
			score = -_negamax(depth - 1, -WIN * 2, -bound, 1, quiescence)
			# Im Nullfenster ist ein Wert <= alpha nur eine Obergrenze: Dieser Zug
			# ist höchstens so gut wie der bisher beste und muss hinter ihm bleiben.
			if noise == 0 and not scored.is_empty() and score <= alpha:
				score = alpha - 1
		_undo(undo)
		if _aborted:
			break
		if noise > 0:
			score += _rng.randi_range(-noise, noise)
		scored.append([score, action])
		alpha = maxi(alpha, score)
	return scored

func _negamax(depth: int, alpha: int, beta: int, ply: int, quiescence: bool) -> int:
	nodes += 1
	if (nodes & 255) == 0 and (cancelled or Time.get_ticks_msec() > _deadline):
		_aborted = true
	if _aborted:
		return 0
	var side := _r.turn
	if depth <= 0:
		if quiescence:
			return _quiesce(alpha, beta, ply, 0)
		return _evaluate()
	var actions := _actions(side, false)
	if actions.is_empty():
		return -WIN + ply
	_order(actions, ply)
	var best := -WIN * 2
	for action: Array in actions:
		var undo := _do(action)
		var score: int
		if undo.captured_homestone:
			score = WIN - ply
		else:
			score = -_negamax(depth - 1, -beta, -alpha, ply + 1, quiescence)
		_undo(undo)
		if _aborted:
			return 0
		if score > best:
			best = score
		if score > alpha:
			alpha = score
		if alpha >= beta:
			if undo.captured.is_empty() and ply < MAX_PLY:
				var slots: Array = _killers[ply]
				if slots[0] != action:
					slots[1] = slots[0]
					slots[0] = action
			break
	return best

## Rechnet nur Schlagzüge weiter, damit der Bot nicht mitten in einem
## Abtausch aufhört zu rechnen.
func _quiesce(alpha: int, beta: int, ply: int, qdepth: int) -> int:
	nodes += 1
	var stand := _evaluate()
	if stand >= beta or qdepth >= MAX_QUIESCENCE:
		return stand
	alpha = maxi(alpha, stand)
	var captures := _actions(_r.turn, true)
	_order(captures)
	for action: Array in captures:
		var undo := _do(action)
		var score: int
		if undo.captured_homestone:
			score = WIN - ply
		else:
			score = -_quiesce(-beta, -alpha, ply + 1, qdepth + 1)
		_undo(undo)
		if score >= beta:
			return score
		alpha = maxi(alpha, score)
	return alpha

## Alle Aktionen einer Seite als [from, to, promotion].
func _actions(side: PieceTypes.Side, captures_only: bool) -> Array:
	var result: Array = []
	if _r.must_place_homestone(side):
		if not captures_only:
			for cell in _r.homestone_placements(side):
				result.append([NO_CELL, cell, -1])
		return result
	if not captures_only:
		for cell in _r.homestone_placements(side):
			result.append([NO_CELL, cell, -1])
	var enemy_home := KaissaRules.home_row(KaissaRules.other(side))
	for from: Vector2i in _r.pieces.keys():
		var piece: Dictionary = _r.pieces[from]
		if piece.side != side:
			continue
		for to: Vector2i in _targets(from, piece, captures_only):
			if piece.type == PieceTypes.Type.SPEARMAN and to.y == enemy_home:
				for promotion in PieceTypes.PROMOTIONS:
					result.append([from, to, promotion])
			else:
				result.append([from, to, -1])
	return result

## Zielfelder einer Figur, wie [method KaissaRules.legal_moves], aber schneller
## und auf Wunsch nur Schlagzüge. Die Zugmuster kommen aus PieceTypes.DEFINITIONS.
func _targets(from: Vector2i, piece: Dictionary, captures_only: bool) -> Array:
	var result: Array = []
	var side: int = piece.side
	var pieces := _r.pieces
	for pattern: Dictionary in PieceTypes.DEFINITIONS[piece.type].moves:
		var can_capture: bool = pattern.get("capture", true)
		if captures_only and not can_capture:
			continue
		match pattern.kind:
			"slide":
				var max_range: int = pattern.range if pattern.range > 0 else KaissaRules.SIZE
				for dir: Vector2i in pattern.dirs:
					var cell := from
					for i in max_range:
						cell += dir
						if cell.x < 0 or cell.y < 0 or cell.x >= KaissaRules.SIZE or cell.y >= KaissaRules.SIZE:
							break
						var other: Dictionary = pieces.get(cell, {})
						if other.is_empty():
							if not captures_only:
								result.append(cell)
							continue
						if can_capture and other.side != side:
							result.append(cell)
						break
			"leap":
				for offset: Vector2i in pattern.offsets:
					var cell := from + offset
					if cell.x < 0 or cell.y < 0 or cell.x >= KaissaRules.SIZE or cell.y >= KaissaRules.SIZE:
						continue
					var other: Dictionary = pieces.get(cell, {})
					if other.is_empty():
						if not captures_only:
							result.append(cell)
					elif can_capture and other.side != side:
						result.append(cell)
			"spear":
				# Muss zu KaissaRules._spear_moves passen.
				var dy := KaissaRules.forward(side)
				if not captures_only:
					var steps := 1 if piece.moved else 3
					for i in range(1, steps + 1):
						var cell := from + Vector2i(0, dy * i)
						if not KaissaRules.in_bounds(cell) or pieces.has(cell):
							break
						result.append(cell)
				for dx in [-1, 1]:
					var cell := from + Vector2i(dx, dy)
					var other: Dictionary = pieces.get(cell, {})
					if not other.is_empty() and other.side != side:
						result.append(cell)
	return result

## Sortiert Aktionen: zuerst Schläge mit großem Gewinn, dann Einlösungen, dann der Rest.
func _order(actions: Array, ply: int = -1) -> void:
	var keyed: Array = []
	var killers: Array = _killers[ply] if ply >= 0 and ply < MAX_PLY else [[], []]
	for action: Array in actions:
		var key := 0
		if action == killers[0]:
			key = 900
		elif action == killers[1]:
			key = 800
		if action[0] != NO_CELL:
			var target: Dictionary = _r.pieces.get(action[1], {})
			if not target.is_empty():
				if target.type == PieceTypes.Type.HOMESTONE:
					key = WIN
				else:
					key = 10 * VALUES[target.type] - VALUES[_r.pieces[action[0]].type] / 10 + 1000
			if action[2] >= 0:
				key += VALUES[action[2]]
		keyed.append([key, action])
	keyed.sort_custom(func(a, b): return a[0] > b[0])
	for i in keyed.size():
		actions[i] = keyed[i][1]

func _do(action: Array) -> Dictionary:
	var side := _r.turn
	var undo := {"action": action, "side": side, "captured": {}, "captured_homestone": false}
	if action[0] == NO_CELL:
		_r.pieces[action[1]] = {"type": PieceTypes.Type.HOMESTONE, "side": side, "moved": false}
		_r.homestone_placed[side] = true
	else:
		var piece: Dictionary = _r.pieces[action[0]]
		var target: Dictionary = _r.pieces.get(action[1], {})
		undo.captured = target
		undo.type = piece.type
		undo.moved = piece.moved
		undo.captured_homestone = not target.is_empty() and target.type == PieceTypes.Type.HOMESTONE
		_r.pieces.erase(action[0])
		piece.moved = true
		if action[2] >= 0:
			piece.type = action[2]
		_r.pieces[action[1]] = piece
	_r.moves_made[side] += 1
	_r.turn = KaissaRules.other(side)
	return undo

func _undo(undo: Dictionary) -> void:
	var action: Array = undo.action
	var side: PieceTypes.Side = undo.side
	_r.turn = side
	_r.moves_made[side] -= 1
	if action[0] == NO_CELL:
		_r.pieces.erase(action[1])
		_r.homestone_placed[side] = false
	else:
		var piece: Dictionary = _r.pieces[action[1]]
		piece.type = undo.type
		piece.moved = undo.moved
		_r.pieces[action[0]] = piece
		if undo.captured.is_empty():
			_r.pieces.erase(action[1])
		else:
			_r.pieces[action[1]] = undo.captured

## Statische Bewertung aus Sicht der Seite am Zug.
func _evaluate() -> int:
	var score := [0, 0]
	var homestones := [NO_CELL, NO_CELL]
	for cell: Vector2i in _r.pieces:
		var piece: Dictionary = _r.pieces[cell]
		var side: int = piece.side
		score[side] += VALUES[piece.type]
		match piece.type:
			PieceTypes.Type.HOMESTONE:
				homestones[side] = cell
			PieceTypes.Type.SPEARMAN:
				# Vorrücken lohnt sich, je näher an der Einlösung, desto mehr.
				var advanced := absi(cell.y - KaissaRules.home_row(side)) - 1
				score[side] += advanced * advanced * 4
			_:
				# Leichte Vorliebe für die Brettmitte.
				var center := absf(cell.x - 4.5) + absf(cell.y - 4.5)
				score[side] += int((9.0 - center) * 2.0)
	for side in [PieceTypes.Side.YELLOW, PieceTypes.Side.RED]:
		score[side] += _homestone_safety(side, homestones[side])
	var me := _r.turn
	return score[me] - score[KaissaRules.other(me)]

func _homestone_safety(side: PieceTypes.Side, stone: Vector2i) -> int:
	var enemy := KaissaRules.other(side)
	if stone == NO_CELL:
		# Noch nicht gesetzt: Je länger er wartet, desto enger wird es. Die erste
		# Reihe braucht ein freies Feld, das der Gegner nicht sofort angreift.
		var penalty := -15 * _r.moves_made[side]
		var free := _r.homestone_placements(side)
		if free.is_empty():
			return penalty - 60 * (_r.moves_made[side] + 1)
		for cell in free:
			if _attackers(cell, enemy) == 0:
				return penalty
		return penalty - 40 * (_r.moves_made[side] + 1)
	var bonus := 0
	var attackers := _attackers(stone, enemy)
	if attackers > 0:
		# Ist der Gegner am Zug, ist das Spiel praktisch verloren.
		bonus -= 5000 if _r.turn == enemy else 300 * attackers
	for cell: Vector2i in _r.pieces:
		var piece: Dictionary = _r.pieces[cell]
		var dist := maxi(absi(cell.x - stone.x), absi(cell.y - stone.y))
		if piece.side == side:
			if dist == 1:
				bonus += 25
		elif dist <= 3:
			bonus -= (4 - dist) * 30
	return bonus

## Wie viele Figuren von [param by_side] könnten auf [param cell] schlagen?
func _attackers(cell: Vector2i, by_side: PieceTypes.Side) -> int:
	var count := 0
	for dir: Vector2i in PieceTypes.ALL_DIRS:
		var pos := cell
		for dist in range(1, KaissaRules.SIZE):
			pos += dir
			if not KaissaRules.in_bounds(pos):
				break
			var piece: Dictionary = _r.pieces.get(pos, {})
			if piece.is_empty():
				continue
			if piece.side == by_side and _can_hit(piece, -dir, dist):
				count += 1
			break
	for offset: Vector2i in PieceTypes.TARN_LEAPS:
		var piece: Dictionary = _r.pieces.get(cell - offset, {})
		if not piece.is_empty() and piece.side == by_side and piece.type == PieceTypes.Type.TARNSMAN:
			count += 1
	return count

## Kann [param piece] in Richtung [param dir] über [param dist] Felder schlagen?
func _can_hit(piece: Dictionary, dir: Vector2i, dist: int) -> bool:
	for pattern: Dictionary in PieceTypes.DEFINITIONS[piece.type].moves:
		match pattern.kind:
			"slide":
				if pattern.get("capture", true) and (pattern.range == 0 or dist <= pattern.range) \
						and pattern.dirs.has(dir):
					return true
			"spear":
				if dist == 1 and dir.y == KaissaRules.forward(piece.side) and dir.x != 0:
					return true
	return false
