# Eröffnungen aus Bot-gegen-Bot-Partien

Erzeugt mit `tools/bot_match.gd` und `tools/analyze_openings.py`.

## Ergebnis in Kürze

- **Gelb hat keinen großen Anzugsvorteil.** Über alle Partien holt Gelb gut die Hälfte der Punkte.
- **Die besten ersten Züge** sind laut Engine der Sprung des rechten Tarnsman **g10-i7** (oder
  g10-e7) und der Vorstoß eines mittleren Spearman um drei Felder, **f9-f6** oder **g9-g6**. Lange
  Spearman-Züge am Rand (a8-a7, j8-j7), frühe Physician- und Rider-Züge sowie c9-c7 schneiden
  schlecht ab.
- **g10-i7 ist eine Falle für schwächere Bots:** Die Stufe schwer antwortet fast immer mit
  **j3-j6** (greift den Tarnsman an) und verliert dann 85 % der Partien. Die Engine bewertet j3-j6
  als klaren Fehler (rund 4 Spearmen schlechter als die beste Antwort f2-f3 oder h2-h3).
- **Gegen den Meister hält der Vorteil nicht:** In je sechs Partien Meister gegen Meister holte
  g10-i7 50 % und f9-f6 58 %. Das sind zu wenige Partien für eine sichere Aussage, die beiden
  Eröffnungen sind aber spielbar und etwa gleichwertig.
- **Nach g10-i7 oder g10-e7 und ruhiger Antwort von Rot** setzt Gelb am besten gleich den
  Homestone auf das frei gewordene Feld **g10**, direkt neben der Ubara.
- **g10-e7** sieht für die Engine genauso gut aus wie g10-i7, holte in den Bot-Partien aber nur
  43 % und steht deshalb nicht im Buch.

Die Stufe schwer spielte in den Bot-Partien nur 200 ms je Zug, damit genug Partien
zusammenkommen (rund eine Minute je Partie). Die Engine-Werte stammen von der Stufe Meister mit
3 s je Zug (4 bis 5 Halbzüge tief). Rohdaten: `docs/daten/`.

## Überblick

- Partien: 323 (davon 281 entschieden, 36 nach Materialvorsprung gewertet)
- Gelb (Anzugsseite) holt 52 % der Punkte
- Durchschnittliche Länge: 100 Halbzüge
- Bots: hard 200 ms, master 1000 ms

## Erster Zug von Gelb

Engine-Wert: Bewertung der Stufe Meister nach dem Zug, aus Sicht der ziehenden Seite, in Hundertstel Spearman (100 = ein Spearman). Partien: Bot-Partien, in denen der Zug gespielt wurde; Punkte aus Sicht der ziehenden Seite. Buch: Gewicht im Eröffnungsbuch.

### Startstellung

| Zug | Engine-Wert | Partien | S / R / N | Punkte | Buch |
|---|---:|---:|---|---:|---:|
| g10-i7 | +0 | 40 | 30 / 4 / 6 | 80 % | 16 |
| g10-e7 | +0 | 35 | 13 / 4 / 18 | 43 % |  |
| f9-f6 | -13 | 41 | 21 / 8 / 12 | 61 % | 10 |
| g9-g6 | -13 | 36 | 17 / 2 / 17 | 50 % | 8 |
| d9-d8 | -29 | 30 | 14 / 5 / 11 | 55 % |  |
| e9-e6 | -30 | 32 | 11 / 7 / 14 | 45 % |  |
| g9-g7 | -33 | 4 | 1 / 0 / 3 | 25 % |  |
| f9-f7 | -33 | 0 | 0 / 0 / 0 | – |  |
| e9-e8 | -42 | 3 | 2 / 0 / 1 | 67 % |  |
| d10-b7 | -43 | 3 | 1 / 0 / 2 | 33 % |  |
| g9-g8 | -43 | 1 | 1 / 0 / 0 | 100 % |  |
| h9-h8 | -45 | 4 | 2 / 0 / 2 | 50 % |  |
| i9-h8 | -45 | 3 | 1 / 1 / 1 | 50 % |  |
| f9-f8 | -45 | 3 | 2 / 0 / 1 | 67 % |  |
| j9-h7 | -46 | 9 | 1 / 1 / 7 | 17 % |  |
| g10-d8 | -48 | 5 | 2 / 0 / 3 | 40 % |  |
| e9-e7 | -50 | 3 | 1 / 1 / 1 | 50 % |  |
| d9-d6 | -65 | 3 | 2 / 0 / 1 | 67 % |  |
| d10-f7 | -67 | 5 | 2 / 0 / 3 | 40 % |  |
| j8-j5 | -70 | 0 | 0 / 0 / 0 | – |  |
| a8-a5 | -72 | 2 | 1 / 1 / 0 | 75 % |  |
| d9-d7 | -87 | 3 | 1 / 0 / 2 | 33 % |  |
| i9-i8 | -89 | 1 | 0 / 0 / 1 | 0 % |  |
| a8-a6 | -100 | 2 | 0 / 1 / 1 | 25 % |  |
| j8-j6 | -104 | 5 | 1 / 2 / 2 | 40 % |  |
| h9-h7 | -118 | 8 | 2 / 2 / 4 | 38 % |  |
| d10-g8 | -119 | 2 | 0 / 1 / 1 | 25 % |  |
| j8-j7 | -124 | 5 | 4 / 0 / 1 | 80 % |  |
| b9-c8 | -124 | 0 | 0 / 0 / 0 | – |  |
| b9-b8 | -130 | 5 | 2 / 1 / 2 | 50 % |  |
| h9-h6 | -132 | 4 | 2 / 0 / 2 | 50 % |  |
| c9-c8 | -136 | 4 | 2 / 0 / 2 | 50 % |  |
| c9-c6 | -139 | 5 | 3 / 0 / 2 | 60 % |  |
| j9-i8 | -142 | 2 | 0 / 0 / 2 | 0 % |  |
| a9-c7 | -144 | 1 | 0 / 0 / 1 | 0 % |  |
| c9-c7 | -150 | 3 | 1 / 0 / 2 | 33 % |  |
| a9-b8 | -156 | 5 | 3 / 0 / 2 | 60 % |  |
| a8-a7 | -163 | 6 | 2 / 1 / 3 | 42 % |  |

## Antworten und Fortsetzungen

### Nach f9-f6

| Zug | Engine-Wert | Partien | S / R / N | Punkte | Buch |
|---|---:|---:|---|---:|---:|
| g2-g5 | -4 | 0 | 0 / 0 / 0 | – | 10 |
| g1-d3 | -13 | 3 | 0 / 1 / 2 | 17 % | 8 |
| d1-g3 | -14 | 3 | 0 / 1 / 2 | 17 % | 8 |
| d2-d5 | -17 | 0 | 0 / 0 / 0 | – |  |
| d1-f4 | -21 | 8 | 1 / 3 / 4 | 31 % |  |
| g1-e4 | -21 | 7 | 4 / 1 / 2 | 64 % |  |
| g1-i4 | -21 | 6 | 2 / 0 / 4 | 33 % |  |
| f2-f5 | -34 | 0 | 0 / 0 / 0 | – |  |
| e2-e3 | -36 | 0 | 0 / 0 / 0 | – |  |
| i2-i3 | -40 | 0 | 0 / 0 / 0 | – |  |
| d2-d3 | -49 | 0 | 0 / 0 / 0 | – |  |
| b2-b3 | -50 | 0 | 0 / 0 / 0 | – |  |

### Nach g10-e7

| Zug | Engine-Wert | Partien | S / R / N | Punkte | Buch |
|---|---:|---:|---|---:|---:|
| f2-f3 | -56 | 0 | 0 / 0 / 0 | – | 10 |
| h2-h3 | -58 | 0 | 0 / 0 / 0 | – | 10 |
| i2-h3 | -102 | 0 | 0 / 0 / 0 | – |  |
| f2-f5 | -108 | 0 | 0 / 0 / 0 | – |  |
| g1-e4 | -110 | 7 | 5 / 1 / 1 | 79 % |  |
| g1-i4 | -110 | 6 | 4 / 1 / 1 | 75 % |  |
| e2-e5 | -149 | 0 | 0 / 0 / 0 | – |  |
| d2-d5 | -155 | 0 | 0 / 0 / 0 | – |  |
| i2-i3 | -164 | 0 | 0 / 0 / 0 | – |  |
| e2-e4 | -173 | 0 | 0 / 0 / 0 | – |  |
| f2-f4 | -173 | 0 | 0 / 0 / 0 | – |  |
| e2-e3 | -185 | 0 | 0 / 0 / 0 | – |  |

### Nach g10-i7

| Zug | Engine-Wert | Partien | S / R / N | Punkte | Buch |
|---|---:|---:|---|---:|---:|
| f2-f3 | -54 | 0 | 0 / 0 / 0 | – | 10 |
| h2-h3 | -75 | 0 | 0 / 0 / 0 | – | 6 |
| g1-e4 | -110 | 4 | 2 / 1 / 1 | 62 % |  |
| g1-i4 | -110 | 1 | 0 / 1 / 0 | 50 % |  |
| f2-f5 | -142 | 0 | 0 / 0 / 0 | – |  |
| i2-h3 | -145 | 0 | 0 / 0 / 0 | – |  |
| e2-e5 | -149 | 0 | 0 / 0 / 0 | – |  |
| d2-d5 | -155 | 1 | 0 / 0 / 1 | 0 % |  |
| i2-i3 | -158 | 0 | 0 / 0 / 0 | – |  |
| j2-h4 | -158 | 0 | 0 / 0 / 0 | – |  |
| e2-e4 | -173 | 0 | 0 / 0 / 0 | – |  |
| f2-f4 | -173 | 0 | 0 / 0 / 0 | – |  |

### Nach g9-g6

| Zug | Engine-Wert | Partien | S / R / N | Punkte | Buch |
|---|---:|---:|---|---:|---:|
| g2-g5 | -13 | 0 | 0 / 0 / 0 | – | 10 |
| g1-e4 | -21 | 10 | 6 / 0 / 4 | 60 % | 11 |
| g1-i4 | -21 | 6 | 4 / 0 / 2 | 67 % | 12 |
| e2-e5 | -27 | 0 | 0 / 0 / 0 | – |  |
| b2-b3 | -34 | 0 | 0 / 0 / 0 | – |  |
| b2-c3 | -40 | 0 | 0 / 0 / 0 | – |  |
| e2-e4 | -45 | 0 | 0 / 0 / 0 | – |  |
| g2-g4 | -52 | 0 | 0 / 0 / 0 | – |  |
| g2-g3 | -64 | 0 | 0 / 0 / 0 | – |  |
| d1-g3 | -67 | 5 | 1 / 0 / 4 | 20 % |  |
| d2-d5 | -86 | 0 | 0 / 0 / 0 | – |  |
| d1-f4 | -88 | 7 | 3 / 2 / 2 | 57 % |  |

### Nach f9-f6 g1-d3

| Zug | Engine-Wert | Partien | S / R / N | Punkte | Buch |
|---|---:|---:|---|---:|---:|
| e10-f9 | +10 | 0 | 0 / 0 / 0 | – | 10 |
| f10-f9 | +10 | 0 | 0 / 0 / 0 | – | 10 |
| g10-i7 | -7 | 0 | 0 / 0 / 0 | – | 7 |
| f10-f7 | -11 | 0 | 0 / 0 / 0 | – |  |
| f10-f8 | -13 | 0 | 0 / 0 / 0 | – |  |
| d10-b7 | -32 | 1 | 1 / 0 / 0 | 100 % |  |
| d10-g8 | -46 | 0 | 0 / 0 / 0 | – |  |
| b9-b8 | -50 | 0 | 0 / 0 / 0 | – |  |
| d10-f7 | -52 | 0 | 0 / 0 / 0 | – |  |
| i9-h8 | -53 | 0 | 0 / 0 / 0 | – |  |
| e10-g8 | -62 | 1 | 1 / 0 / 0 | 100 % |  |
| g10-f9 | -72 | 0 | 0 / 0 / 0 | – |  |

### Nach f9-f6 g2-g5

| Zug | Engine-Wert | Partien | S / R / N | Punkte | Buch |
|---|---:|---:|---|---:|---:|
| f6xg5 | +77 | 0 | 0 / 0 / 0 | – | 10 |
| g10-i7 | +47 | 0 | 0 / 0 / 0 | – | 4 |
| e10-f9 | +43 | 0 | 0 / 0 / 0 | – | 3 |
| d10-f7 | +28 | 0 | 0 / 0 / 0 | – |  |
| g10-d8 | +2 | 0 | 0 / 0 / 0 | – |  |
| g10-e7 | -5 | 0 | 0 / 0 / 0 | – |  |
| g10-f9 | -7 | 0 | 0 / 0 / 0 | – |  |
| b9-b8 | -8 | 0 | 0 / 0 / 0 | – |  |
| d10-b7 | -10 | 0 | 0 / 0 / 0 | – |  |
| f10-f7 | -11 | 0 | 0 / 0 / 0 | – |  |
| f10-f8 | -11 | 0 | 0 / 0 / 0 | – |  |
| f10-f9 | -19 | 0 | 0 / 0 / 0 | – |  |

### Nach g10-e7 f2-f3

| Zug | Engine-Wert | Partien | S / R / N | Punkte | Buch |
|---|---:|---:|---|---:|---:|
| HS@g10 | +107 | 0 | 0 / 0 / 0 | – | 10 |
| d9-d6 | +79 | 0 | 0 / 0 / 0 | – | 4 |
| j8-j5 | +59 | 0 | 0 / 0 / 0 | – |  |
| d10-f7 | +53 | 0 | 0 / 0 / 0 | – |  |
| d9-d8 | +51 | 0 | 0 / 0 / 0 | – |  |
| f9-f6 | +49 | 0 | 0 / 0 / 0 | – |  |
| a8-a5 | +37 | 0 | 0 / 0 / 0 | – |  |
| f9-f8 | +35 | 0 | 0 / 0 / 0 | – |  |
| e9-e8 | +31 | 0 | 0 / 0 / 0 | – |  |
| f9-f7 | +29 | 0 | 0 / 0 / 0 | – |  |
| b9-b8 | +19 | 0 | 0 / 0 / 0 | – |  |
| j8-j7 | +11 | 0 | 0 / 0 / 0 | – |  |

### Nach g10-e7 h2-h3

| Zug | Engine-Wert | Partien | S / R / N | Punkte | Buch |
|---|---:|---:|---|---:|---:|
| HS@g10 | +88 | 0 | 0 / 0 / 0 | – | 10 |
| d9-d6 | +83 | 0 | 0 / 0 / 0 | – | 9 |
| j8-j5 | +75 | 0 | 0 / 0 / 0 | – | 8 |
| d10-g8 | +60 | 0 | 0 / 0 / 0 | – |  |
| e9-e8 | +60 | 0 | 0 / 0 / 0 | – |  |
| i9-i8 | +60 | 0 | 0 / 0 / 0 | – |  |
| j9-h7 | +55 | 0 | 0 / 0 / 0 | – |  |
| d9-d8 | +51 | 0 | 0 / 0 / 0 | – |  |
| i9-h8 | +51 | 0 | 0 / 0 / 0 | – |  |
| j8-j6 | +41 | 0 | 0 / 0 / 0 | – |  |
| a8-a5 | +37 | 0 | 0 / 0 / 0 | – |  |
| f9-f8 | +35 | 0 | 0 / 0 / 0 | – |  |

### Nach g10-i7 f2-f3

| Zug | Engine-Wert | Partien | S / R / N | Punkte | Buch |
|---|---:|---:|---|---:|---:|
| HS@g10 | +120 | 0 | 0 / 0 / 0 | – | 10 |
| i9-i8 | +54 | 0 | 0 / 0 / 0 | – |  |
| e9-e6 | +45 | 0 | 0 / 0 / 0 | – |  |
| a8-a5 | +25 | 0 | 0 / 0 / 0 | – |  |
| c9-c6 | +21 | 0 | 0 / 0 / 0 | – |  |
| d9-d6 | +21 | 0 | 0 / 0 / 0 | – |  |
| j8-j5 | +6 | 0 | 0 / 0 / 0 | – |  |
| c9-c7 | +1 | 0 | 0 / 0 / 0 | – |  |
| d10-f7 | +0 | 0 | 0 / 0 / 0 | – |  |
| a8-a7 | -3 | 0 | 0 / 0 / 0 | – |  |
| f9-f6 | -4 | 0 | 0 / 0 / 0 | – |  |
| i7-h7 | -4 | 0 | 0 / 0 / 0 | – |  |

### Nach g10-i7 h2-h3

| Zug | Engine-Wert | Partien | S / R / N | Punkte | Buch |
|---|---:|---:|---|---:|---:|
| HS@g10 | +91 | 0 | 0 / 0 / 0 | – | 10 |
| d9-d6 | +77 | 0 | 0 / 0 / 0 | – | 7 |
| e9-e7 | +66 | 0 | 0 / 0 / 0 | – | 5 |
| d10-g8 | +54 | 0 | 0 / 0 / 0 | – |  |
| i9-i8 | +54 | 0 | 0 / 0 / 0 | – |  |
| d9-d8 | +45 | 0 | 0 / 0 / 0 | – |  |
| e9-e6 | +45 | 0 | 0 / 0 / 0 | – |  |
| i9-h8 | +45 | 0 | 0 / 0 / 0 | – |  |
| f9-f6 | +32 | 0 | 0 / 0 / 0 | – |  |
| c9-c6 | +25 | 0 | 0 / 0 / 0 | – |  |
| a8-a5 | +25 | 0 | 0 / 0 / 0 | – |  |
| g9-g6 | +20 | 0 | 0 / 0 / 0 | – |  |

### Nach g9-g6 g1-i4

| Zug | Engine-Wert | Partien | S / R / N | Punkte | Buch |
|---|---:|---:|---|---:|---:|
| h10-f8 | +17 | 0 | 0 / 0 / 0 | – | 10 |
| f10-i7 | +9 | 1 | 1 / 0 / 0 | 100 % | 9 |
| i9-h8 | -22 | 0 | 0 / 0 / 0 | – |  |
| h9-h8 | -22 | 0 | 0 / 0 / 0 | – | 2 |
| f10-g9 | -50 | 0 | 0 / 0 / 0 | – |  |
| g10-e7 | -89 | 1 | 0 / 0 / 1 | 0 % |  |
| g10-i7 | -89 | 0 | 0 / 0 / 0 | – |  |
| i9-i8 | -101 | 0 | 0 / 0 / 0 | – |  |
| f9-f8 | -101 | 0 | 0 / 0 / 0 | – |  |
| f9-f6 | -121 | 0 | 0 / 0 / 0 | – |  |
| j9-h7 | -139 | 0 | 0 / 0 / 0 | – |  |
| e9-e6 | -141 | 0 | 0 / 0 / 0 | – |  |

### Nach g9-g6 g2-g5

| Zug | Engine-Wert | Partien | S / R / N | Punkte | Buch |
|---|---:|---:|---|---:|---:|
| a8-a5 | +15 | 0 | 0 / 0 / 0 | – | 10 |
| d10-f7 | +8 | 0 | 0 / 0 / 0 | – | 9 |
| h10-e7 | +6 | 0 | 0 / 0 / 0 | – | 8 |
| d9-d6 | +4 | 0 | 0 / 0 / 0 | – |  |
| h10-f8 | +2 | 0 | 0 / 0 / 0 | – |  |
| h10-c5 | +0 | 0 | 0 / 0 / 0 | – |  |
| g10-e7 | +0 | 0 | 0 / 0 / 0 | – |  |
| d10-g8 | -4 | 0 | 0 / 0 / 0 | – |  |
| a8-a6 | -6 | 0 | 0 / 0 / 0 | – |  |
| f10-i7 | -11 | 0 | 0 / 0 / 0 | – |  |
| i9-i8 | -13 | 0 | 0 / 0 / 0 | – |  |
| b9-b8 | -13 | 0 | 0 / 0 / 0 | – |  |

## Häufigste Zugfolgen (erste vier Halbzüge, ab 3 Partien)

| Zugfolge | Partien | Punkte Gelb |
|---|---:|---:|
| g10-i7 j3-j6 i7-g4 a3-a6 | 20 | 90 % |
| e9-e6 d1-f4 f10-c7 f4-e4 | 8 | 44 % |
| g10-e7 g1-d3 e7-g4 HS@g1 | 7 | 79 % |
| g10-e7 g1-i4 e7-g4 i4-g7 | 6 | 25 % |
| g10-e7 g1-e4 e7-g4 e4-g7 | 6 | 17 % |
| g10-e7 d1-g3 e7-g4 e1-d1 | 5 | 30 % |
| g10-i7 j3-j6 i7-g4 d2-d5 | 4 | 88 % |
| c9-c6 d1-f4 b9-c9 h2-h3 | 4 | 75 % |
| g9-g6 d1-f4 h10-d6 f4-d7 | 4 | 50 % |
| f9-f6 g1-e4 e10-h7 e4-f4 | 4 | 50 % |
| g10-i7 g1-e4 i7-g4 e4-g7 | 4 | 38 % |
| g10-e7 d1-f4 e7-g4 e1-d1 | 4 | 0 % |
| g10-e7 d1-b4 e7-g4 b4-d7 | 3 | 100 % |
| d9-d8 g1-i4 c10-h5 i4-g7 | 3 | 50 % |
| d9-d8 g1-d3 c10-g6 HS@g1 | 3 | 50 % |
