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
  board_view.gd        Zeichnet Brett und Figuren, verarbeitet Mausklicks
  main.gd              Verbindet Regeln, Brett und Oberfläche
assets/                Platz für Grafiken, Schriften und Klänge
docs/regeln.md         Die Spielregeln dieses Projekts
```

## Ideen für die nächsten Schritte

- Eigene Grafiken für die Figuren
- Spielstand speichern und Zugliste in Notation
- Netzwerkspiel
