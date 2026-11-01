# Kaissa

Ein Brettspiel in **Godot 4**, inspiriert vom Spiel *Kaissa* aus der Gor-Saga von John Norman.
Zwei Parteien, **Rot** und **Gelb**, treten auf einem Brett mit 10 × 10 Feldern gegeneinander an.

![Startszene](docs/screenshot.png)

> Dies ist ein Fanprojekt. Code und Grafik sind eigenständig erstellt. Die Regeln stehen in
> [docs/regeln.md](docs/regeln.md).

## Stand

- 10 × 10-Brett mit roten und gelben Feldern, Koordinaten a–j / 1–10
- Je Seite 22 Figuren: Ubar, Ubara, Tarnsmen, Scribes, Builders, Initiates, Spearmen,
  Riders of the High Tharlarion und Physicians, dazu der Homestone
- Zwei Spieler an einem Rechner (Hot-Seat): Figur anklicken, erlaubte Zielfelder werden markiert
- Computergegner in vier Stufen (leicht, mittel, schwer, Meister), für jede Seite getrennt wählbar
- Homestone setzen (spätestens im zehnten Zug), Sieg durch Schlagen des gegnerischen Homestone
- Spearmen werden auf der gegnerischen ersten Reihe gegen Rider oder Tarnsman eingelöst
- Aufgeben und Remis
- Eröffnungstraining: Eröffnungen aus dem Buch auswählen und üben
- Die Figuren werden derzeit per Code gezeichnet (Kreise mit Kürzel, Homestone als Raute)

## Starten

1. [Godot 4.3](https://godotengine.org/download) oder neuer installieren (Standardversion, kein .NET nötig).
2. Godot öffnen, **Importieren** wählen und die Datei `project.godot` aus diesem Ordner auswählen.
3. Mit **F5** starten.

Bedienung: Linksklick wählt eine eigene Figur und zieht sie, Rechtsklick hebt die Auswahl auf.
Mit „Homestone setzen“ in der Seitenleiste werden die freien Felder der ersten Reihe markiert.

### Computergegner

Oben in der Seitenleiste wird für Gelb und Rot jeweils „Mensch“ oder ein Bot gewählt.
Voreingestellt spielt man selbst Gelb gegen „Bot (mittel)“ als Rot. Die Auswahl gilt sofort,
auch mitten im Spiel. Stehen beide Seiten auf Bot, spielt der Computer gegen sich selbst.

| Stufe | Spielweise |
|---|---|
| leicht | schaut nur einen Zug weit und entscheidet mit viel Zufall, übersieht also oft Drohungen |
| mittel | rechnet die Antwort des Gegners mit ein |
| schwer | rechnet bis zu vier Halbzüge voraus und Schlagabfolgen zu Ende, denkt bis zu vier Sekunden |
| Meister | Engine nach dem Vorbild von Schach-Engines wie Stockfish: Transpositionstabelle, Principal Variation Search, Null-Zug-Suche, Late Move Reductions und History-Heuristik. Rechnet in acht Sekunden meist fünf bis sechs Halbzüge tief |

Ein Remisangebot nimmt der Bot nur an, wenn er nicht klar vorn liegt. „Aufgeben“ gibt immer
für den menschlichen Spieler auf.

Ab Stufe mittel spielen die Bots die ersten Züge aus einem Eröffnungsbuch
(`scripts/opening_book.gd`), das aus Bot-gegen-Bot-Partien gewonnen wurde. Steht eine Stellung
nicht im Buch, rechnen sie wie gewohnt. Die Auswertung steht in
[docs/eroeffnungen.md](docs/eroeffnungen.md).

### Eröffnungen üben

Der Knopf **„Eröffnungen üben“** unten in der Seitenleiste öffnet die Liste der Eröffnungen aus
dem Eröffnungsbuch, jeweils mit Namen, Zugfolge und kurzer Erklärung. Unter jeder Eröffnung stehen
ihre Varianten (die Antworten von Rot), ganz oben „Alle Eröffnungen gemischt“.

![Eröffnungstraining](docs/training.png)

1. Seite wählen: Gelb übt die eigenen Eröffnungszüge, Rot die Antworten darauf.
2. Eröffnung oder Variante anklicken und **„Üben starten“** (oder doppelklicken).
3. Auf der eigenen Seite einen Buchzug spielen. Ein Zug, der nicht im Buch steht, wird
   zurückgenommen. **„Tipp“** markiert die richtige Figur, **„Lösung zeigen“** auch das Zielfeld.
   Den Homestone setzt man wie im Spiel über den Knopf „Homestone setzen“.
   Der Trainer antwortet für die Gegenseite mit Buchzügen, nach Gewicht zufällig gewählt.
4. Am Ende des Buchs gibt es eine Auswertung. **„Nochmal“** startet dieselbe Eröffnung mit einer
   anderen Variante, **„Gegen Bot weiterspielen“** spielt die Stellung gegen den Computer weiter.

Fehlerfrei geschaffte Linien werden mit ✓ und Anzahl in der Liste gezählt (gespeichert in
`user://eroeffnungstraining.cfg`). Namen und Erklärungen der Eröffnungen stehen in
`scripts/opening_trainer.gd`. Prüfen ohne Fenster:
`godot --headless --path . -s tools/test_opening_trainer.gd`.

### Eröffnungen mit Bot-Partien testen

`tools/bot_match.gd` lässt Bots ohne Fenster gegeneinander spielen, `tools/analyze_openings.py`
wertet die Partien aus und erzeugt Bericht und Eröffnungsbuch:

```sh
# 50 Partien schwer gegen schwer, 200 ms je Zug, erster Zug von Gelb zufällig
godot --headless --path . -s tools/bot_match.gd -- --games 50 --time 200 --random-plies 1 --out runs/partien.jsonl
# Partien ab einer festen Eröffnung, die ersten 10 Halbzüge mit etwas Zufall
godot --headless --path . -s tools/bot_match.gd -- --games 20 --opening "g10-i7 f2-f3" --random-plies 0 --noise-plies 10 --out runs/partien.jsonl
# Engine (Meister, 3 s) bewertet jeden möglichen Zug nach einer Zugfolge
godot --headless --path . -s tools/bot_match.gd -- --mode rank --yellow master --time 3000 --opening "g10-i7" --out runs/bewertung.jsonl
# Baum automatisch ausbauen: jede über Buchzüge erreichte Stellung bewerten, bis 5 Halbzüge tief
python3 tools/expand_book.py --godot godot --rank runs/bewertung.jsonl --games runs/partien.jsonl --depth 5 --jobs 4
# Auswerten, Bericht und Buch neu schreiben, Buch prüfen
python3 tools/analyze_openings.py --games runs/partien.jsonl --rank runs/bewertung.jsonl --report docs/eroeffnungen.md --book scripts/opening_book.gd
godot --headless --path . -s tools/bot_match.gd -- --mode checkbook
```

Züge werden als `e9-e7` (ziehen), `d10xg7` (schlagen), `c2-c1=TN` (einlösen) und `HS@c10`
(Homestone setzen) geschrieben. Jede Partie läuft in einem eigenen Prozess; mehrere Prozesse
parallel nutzen mehrere Prozessorkerne. Hat eine Seite über zehn Halbzüge mehr als 15 Spearmen
Vorsprung, wird die Partie für sie gewertet; nach 200 Halbzügen endet sie remis.

## Aufbau

```
project.godot          Projekteinstellungen (Hauptszene, Fenstergröße, Renderer)
scenes/
  main.tscn            Hauptszene mit Brett und Seitenleiste
  board.tscn           Das Spielbrett
scripts/
  piece_types.gd       Figurentypen, Zugmuster und Grundaufstellung (hier Regeln anpassen)
  kaissa_rules.gd      Spielzustand und Zuglogik, unabhängig von der Darstellung
  kaissa_ai.gd         Computergegner (Alpha-Beta- und Engine-Suche, Stellungsbewertung, Stufen)
  opening_book.gd      Eröffnungsbuch der Bots (erzeugt aus Bot-Partien)
  opening_trainer.gd   Eröffnungstraining: Liste der Eröffnungen, erwartete Züge
  training_panel.gd    Seitenleiste des Eröffnungstrainings
  board_view.gd        Zeichnet Brett und Figuren, verarbeitet Mausklicks
  main.gd              Verbindet Regeln, Brett und Oberfläche
assets/                Platz für Grafiken, Schriften und Klänge
docs/regeln.md         Die Spielregeln dieses Projekts
docs/eroeffnungen.md   Auswertung der Bot-gegen-Bot-Partien
tools/                 Bot-Turniere ohne Fenster und ihre Auswertung
```

## Ideen für die nächsten Schritte

- Eigene Grafiken für die Figuren
- Spielstand speichern und Zugliste in der Seitenleiste anzeigen
- Netzwerkspiel
