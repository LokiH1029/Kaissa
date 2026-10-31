class_name PieceTypes
extends RefCounted
## Figurentypen von Kaissa und ihre Zugmuster.
##
## Alle Zugmuster stehen zentral in [constant DEFINITIONS], sodass Regeln
## angepasst werden können, ohne Regel- oder Anzeigecode zu ändern.

enum Type { UBAR, UBARA, TARNSMAN, SCRIBE, BUILDER, INITIATE, SPEARMAN, RIDER, PHYSICIAN, HOMESTONE }
enum Side { YELLOW, RED }

const ORTHO: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
const DIAG: Array[Vector2i] = [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]
const ALL_DIRS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1),
]
## Sprünge des Tarnsman: drei Felder in eine Richtung, zwei quer dazu.
const TARN_LEAPS: Array[Vector2i] = [
	Vector2i(2, 3), Vector2i(-2, 3), Vector2i(2, -3), Vector2i(-2, -3),
	Vector2i(3, 2), Vector2i(-3, 2), Vector2i(3, -2), Vector2i(-3, -2),
]

## Jede Figur hat eine Liste von Zugarten:
##   "slide": gleitet in [dirs] bis [range] Felder (0 = unbegrenzt) und darf
##            nicht über Figuren ziehen.
##   "leap":  springt direkt auf die Felder in [offsets], auch über Figuren.
##   "spear": Sonderregel des Spearman (siehe KaissaRules).
## [capture] = false heißt: Diese Zugart darf nur auf leere Felder führen.
const DEFINITIONS := {
	Type.UBAR:      {"name": "Ubar",                         "short": "UB", "moves": [{"kind": "slide", "dirs": ALL_DIRS, "range": 0}]},
	Type.UBARA:     {"name": "Ubara",                        "short": "UA", "moves": [{"kind": "slide", "dirs": ALL_DIRS, "range": 3}]},
	Type.TARNSMAN:  {"name": "Tarnsman",                     "short": "TN", "moves": [
		{"kind": "leap", "offsets": TARN_LEAPS},
		{"kind": "slide", "dirs": ALL_DIRS, "range": 1, "capture": false},
	]},
	Type.SCRIBE:    {"name": "Scribe",                       "short": "SC", "moves": [{"kind": "slide", "dirs": DIAG, "range": 5}]},
	Type.BUILDER:   {"name": "Builder",                      "short": "BD", "moves": [{"kind": "slide", "dirs": ORTHO, "range": 0}]},
	Type.INITIATE:  {"name": "Initiate",                     "short": "IN", "moves": [{"kind": "slide", "dirs": DIAG, "range": 0}]},
	Type.SPEARMAN:  {"name": "Spearman",                     "short": "SP", "moves": [{"kind": "spear"}]},
	Type.RIDER:     {"name": "Rider of the High Tharlarion", "short": "HT", "moves": [{"kind": "slide", "dirs": ALL_DIRS, "range": 1}]},
	Type.PHYSICIAN: {"name": "Physician",                    "short": "PH", "moves": [{"kind": "slide", "dirs": ALL_DIRS, "range": 2}]},
	Type.HOMESTONE: {"name": "Homestone",                    "short": "HS", "moves": [{"kind": "slide", "dirs": ALL_DIRS, "range": 1, "capture": false}]},
}

## Startaufstellung von links nach rechts (Linie a bis j), für beide Seiten gleich,
## sodass Ubar und Ubar sich gegenüberstehen. Die Ubara steht auf f, für beide
## Seiten ein Feld der eigenen Farbe.
const BACK_ROW: Array[Type] = [
	Type.INITIATE, Type.BUILDER, Type.SCRIBE, Type.TARNSMAN, Type.UBAR,
	Type.UBARA, Type.TARNSMAN, Type.SCRIBE, Type.BUILDER, Type.INITIATE,
]
const SECOND_ROW: Array[Type] = [
	Type.PHYSICIAN, Type.RIDER, Type.SPEARMAN, Type.SPEARMAN, Type.SPEARMAN,
	Type.SPEARMAN, Type.SPEARMAN, Type.SPEARMAN, Type.RIDER, Type.PHYSICIAN,
]
## Linien der zusätzlichen Spearmen in der dritten Reihe (a und j).
const THIRD_ROW_SPEARMEN: Array[int] = [0, 9]

## Figuren, in die sich ein Spearman auf der gegnerischen ersten Reihe verwandeln kann.
const PROMOTIONS: Array[Type] = [Type.RIDER, Type.TARNSMAN]

## Bis zu diesem eigenen Zug muss der Homestone gesetzt sein.
const HOMESTONE_DEADLINE := 10
