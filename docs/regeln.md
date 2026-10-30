# Spielregeln

Kaissa ist in den Gor-Romanen das beliebteste Brettspiel der Goreaner. Die Bücher erwähnen das
Brett mit 100 roten und gelben Feldern, die beiden Farben der Parteien und die Namen vieler
Figuren, beschreiben aber kaum, wie die Figuren ziehen. Die folgenden Regeln sind deshalb eine
eigene Ausarbeitung für dieses Spiel. Alle Zugmuster stehen zentral in `scripts/piece_types.gd`
und lassen sich dort ändern.

## Brett und Aufstellung

Gespielt wird auf 10 × 10 Feldern. Gelb steht unten und beginnt, Rot steht oben.

| Reihe | a | b | c | d | e | f | g | h | i | j |
|---|---|---|---|---|---|---|---|---|---|---|
| Grundreihe | R | T | E | S | U | A | S | E | T | R |
| Vorderreihe | B | Sp | Sp | Sp | Sp | Sp | Sp | Sp | Sp | B |

Beide Ubar stehen sich auf der e-Linie gegenüber.

## Figuren

| Zeichen | Figur | Zug |
|---|---|---|
| U | Ubar | ein Feld in jede Richtung |
| A | Ubara | beliebig weit gerade oder schräg |
| R | Reiter des Hohen Tharlarion | beliebig weit gerade |
| T | Tarnkämpfer | springt 1+2 oder 1+3 Felder (wie ein verlängerter Springer), darf über Figuren fliegen |
| E | Eingeweihter | beliebig weit schräg |
| S | Schreiber | bis zu zwei Felder in jede Richtung |
| B | Baumeister | bis zu zwei Felder gerade |
| Sp | Speerträger | ein Feld vorwärts, beim ersten Zug auch zwei; schlägt schräg vorwärts |

Außer dem Tarnkämpfer kann keine Figur über andere hinwegziehen. Geschlagen wird, indem man auf
das Feld einer gegnerischen Figur zieht.

## Umwandlung

Ein Speerträger, der die gegnerische Grundreihe erreicht, wird zum Reiter des Hohen Tharlarion.

## Spielende

- Wer den gegnerischen Ubar schlägt, gewinnt.
- Wer am Zug ist und keinen erlaubten Zug mehr hat, verliert.

Es gibt bewusst kein Schach im Sinne des irdischen Schachspiels: Ein ungeschützter Ubar kann
einfach geschlagen werden.

## Offene Punkte

- **Heimstein:** In den Romanen wird ein Heimstein erwähnt, der im Spiel eine Rolle hat. Eine
  mögliche Erweiterung: Jede Seite setzt ihren Heimstein in den ersten Zügen auf ein Feld der
  eigenen Hälfte, und wer den gegnerischen Heimstein erobert, gewinnt.
- Remisregeln (Zugwiederholung, zu wenig Material)
- Feinabstimmung der Figurenstärken nach Testpartien
