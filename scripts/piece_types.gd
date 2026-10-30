class_name PieceTypes
extends RefCounted
## Figurentypen von Kaissa und ihre Zugmuster.
##
## Die Romane beschreiben die Zugregeln nur bruchstückhaft. Die Muster hier
## sind ein eigener Vorschlag und lassen sich zentral in [constant DEFINITIONS]
## anpassen, ohne dass Regel- oder Anzeigecode geändert werden muss.

enum Type { UBAR, UBARA, RIDER, TARNSMAN, INITIATE, SCRIBE, BUILDER, SPEARMAN }
enum Side { YELLOW, RED }

const ORTHO: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
const DIAG: Array[Vector2i] = [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]
const ALL_DIRS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1),
]

## Sprungfelder des Tarnkämpfers: (1,2), (2,1), (1,3), (3,1) in alle Richtungen.
static func tarn_leaps() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for base in [Vector2i(1, 2), Vector2i(2, 1), Vector2i(1, 3), Vector2i(3, 1)]:
		for sx in [1, -1]:
			for sy in [1, -1]:
				result.append(Vector2i(base.x * sx, base.y * sy))
	return result

## kind: "slide" = gleitet in [dirs] bis [range] Felder (0 = unbegrenzt),
##       "leap"  = springt direkt auf die Zielfelder in [leaps],
##       "spear" = Sonderregel des Speerträgers (siehe KaissaRules).
const DEFINITIONS := {
	Type.UBAR:     {"name": "Ubar",                         "short": "U", "kind": "slide", "dirs": ALL_DIRS, "range": 1},
	Type.UBARA:    {"name": "Ubara",                        "short": "A", "kind": "slide", "dirs": ALL_DIRS, "range": 0},
	Type.RIDER:    {"name": "Reiter des Hohen Tharlarion",  "short": "R", "kind": "slide", "dirs": ORTHO,    "range": 0},
	Type.TARNSMAN: {"name": "Tarnkämpfer",                  "short": "T", "kind": "leap"},
	Type.INITIATE: {"name": "Eingeweihter",                 "short": "E", "kind": "slide", "dirs": DIAG,     "range": 0},
	Type.SCRIBE:   {"name": "Schreiber",                    "short": "S", "kind": "slide", "dirs": ALL_DIRS, "range": 2},
	Type.BUILDER:  {"name": "Baumeister",                   "short": "B", "kind": "slide", "dirs": ORTHO,    "range": 2},
	Type.SPEARMAN: {"name": "Speerträger",                  "short": "",  "kind": "spear"},
}

## Grundaufstellung von links nach rechts, aus Sicht der jeweiligen Seite.
const BACK_ROW: Array[Type] = [
	Type.RIDER, Type.TARNSMAN, Type.INITIATE, Type.SCRIBE, Type.UBAR,
	Type.UBARA, Type.SCRIBE, Type.INITIATE, Type.TARNSMAN, Type.RIDER,
]
const FRONT_ROW: Array[Type] = [
	Type.BUILDER, Type.SPEARMAN, Type.SPEARMAN, Type.SPEARMAN, Type.SPEARMAN,
	Type.SPEARMAN, Type.SPEARMAN, Type.SPEARMAN, Type.SPEARMAN, Type.BUILDER,
]
