## Ergebnis in Kürze

- **Gelb hat keinen großen Anzugsvorteil.** Über alle Partien holt Gelb gut die Hälfte der Punkte.
- **Die besten ersten Züge** sind laut Engine der Sprung des rechten Tarnsman **g10-i7** (oder
  g10-e7) und der Vorstoß eines mittleren Spearman um drei Felder, **f9-f6** oder **g9-g6**. Lange
  Spearman-Züge am Rand (a8-a7, j8-j7), frühe Physician- und Rider-Züge sowie c9-c7 schneiden
  schlecht ab.
- **g10-i7 ist eine Falle für schwächere Bots:** Die Stufe schwer antwortet fast immer mit
  **j3-j6** (greift den Tarnsman an) und verliert dann 85 % der Partien. Die Engine bewertet j3-j6
  als klaren Fehler (rund 4 Spearmen schlechter als die beste Antwort f2-f3 oder h2-h3).
- **Mit Buch auf beiden Seiten verschwindet die Falle:** In 60 Partien schwer gegen schwer, in
  denen beide Seiten das Buch nutzten, holte g10-i7 nur noch 48 %, weil Rot jetzt richtig
  antwortet. Gelb insgesamt: 53 %.
- **Gegen den Meister hält der Vorteil nicht:** In je sechs Partien Meister gegen Meister holte
  g10-i7 50 % und f9-f6 58 %. Das sind zu wenige Partien für eine sichere Aussage, die beiden
  Eröffnungen sind aber spielbar und etwa gleichwertig.
- **Nach g10-i7 oder g10-e7 und ruhiger Antwort von Rot** setzt Gelb am besten gleich den
  Homestone auf das frei gewordene Feld **g10**, direkt neben der Ubara.
- **g10-e7** sieht für die Engine genauso gut aus wie g10-i7, holte in den Bot-Partien aber nur
  43 % und steht deshalb nicht im Buch. Ebenso fiel **e9-e6** heraus (41 %).
- **Das Buch** umfasst 5 erste Züge von Gelb (g10-i7, f9-f6, g9-g6, d9-d8, f9-f7) und reicht in
  den Hauptlinien bis zum fünften Halbzug. In jeder Buchstellung verfolgt die Engine die zwei
  besten Fortsetzungen weiter (`tools/expand_book.py`).

Die Stufe schwer spielte in den Bot-Partien nur 200 ms je Zug, damit genug Partien
zusammenkommen (rund eine Minute je Partie). Die Engine-Werte stammen von der Stufe Meister mit
3 s je Zug (4 bis 5 Halbzüge tief). Rohdaten: `docs/daten/`.
