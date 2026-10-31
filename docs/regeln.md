# Spielregeln

Kaissa ist in den Gor-Romanen das beliebteste Brettspiel der Goreaner. Die Regeln hier folgen
Dans Vorgaben. Alle Zugmuster stehen zentral in `scripts/piece_types.gd` und lassen sich dort
ändern.

## Brett und Aufstellung

Gespielt wird auf 10 × 10 roten und gelben Feldern. Die Reihen sind von oben (1) nach unten (10)
nummeriert, die Linien von links nach rechts a bis j. Gelb steht unten und beginnt, Rot steht oben.
Beide Seiten stellen gleich auf, sodass Ubar und Ubar einander gegenüberstehen.

| Gelb | a | b | c | d | e | f | g | h | i | j |
|---|---|---|---|---|---|---|---|---|---|---|
| Reihe 10 (erste Reihe) | IN | BD | SC | TN | UB | UA | TN | SC | BD | IN |
| Reihe 9 | PH | HT | SP | SP | SP | SP | SP | SP | HT | PH |
| Reihe 8 | SP | | | | | | | | | SP |

Rot steht spiegelbildlich auf den Reihen 1 bis 3. Die Ubara steht damit auf einem Feld ihrer
eigenen Farbe. Jede Seite hat 22 Figuren, dazu kommt der Homestone.

## Figuren

| Zeichen | Figur | Zug |
|---|---|---|
| UB | Ubar | beliebig weit in jede Richtung |
| UA | Ubara | bis zu drei Felder in jede Richtung |
| TN | Tarnsman | springt drei Felder in eine Richtung und zwei quer dazu, auch über Figuren, und darf dabei schlagen. Alternativ ein Feld in jede Richtung, dann aber ohne zu schlagen |
| SC | Scribe | bis zu fünf Felder schräg (bleibt so immer auf seiner Farbe) |
| BD | Builder | beliebig weit vorwärts, rückwärts und seitwärts |
| IN | Initiate | beliebig weit schräg |
| SP | Spearman | nur vorwärts, beim ersten Zug ein, zwei oder drei Felder, danach eines; schlägt nur schräg vorwärts |
| HT | Rider of the High Tharlarion | ein Feld in jede Richtung |
| PH | Physician | bis zu zwei Felder in jede Richtung |
| HS | Homestone | ein Feld in jede Richtung, darf nicht schlagen |

Außer dem Tarnsman beim Sprung kann keine Figur über andere hinwegziehen. Geschlagen wird, indem
man auf das Feld einer gegnerischen Figur zieht.

## Spearman einlösen

Erreicht ein Spearman die erste Reihe des Gegners, wird er gegen einen Rider of the High
Tharlarion oder einen Tarnsman eingelöst. Der Spieler wählt.

## Homestone

- Der Homestone steht zu Beginn nicht auf dem Brett.
- Jede Seite setzt ihn auf ein freies Feld ihrer eigenen ersten Reihe. Das Setzen zählt als Zug.
- Er muss spätestens im zehnten eigenen Zug gesetzt werden. Ist es im zehnten Zug noch nicht
  geschehen, kann der Spieler nur noch den Homestone setzen. Ist dann kein Feld der ersten Reihe
  frei, verliert er.

## Spielende

- Wer den gegnerischen Homestone schlägt, gewinnt.
- Der Verlust des Ubar beendet das Spiel nicht.
- Ein Spieler kann aufgeben, und beide können sich auf ein Remis einigen.
- Eigene Ergänzung: Wer am Zug ist und weder ziehen noch den Homestone setzen kann, verliert.
