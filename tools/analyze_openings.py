#!/usr/bin/env python3
"""Wertet Bot-gegen-Bot-Partien und Zugbewertungen aus tools/bot_match.gd aus.

Aufruf:
  python3 tools/analyze_openings.py --games runs/*.jsonl --rank runs/rank*.jsonl \
      --report docs/eroeffnungen.md --book scripts/opening_book.gd

--games  JSON-Zeilen aus dem Modus "play"
--rank   JSON-Zeilen aus dem Modus "rank" (Engine-Bewertung je Zug)
--report schreibt einen Bericht in Markdown
--book   ersetzt den Buchteil von scripts/opening_book.gd
--notes  Markdown-Zusammenfassung für den Anfang des Berichts (z.B. docs/eroeffnungen_notizen.md)
"""
import argparse
import json
import math
from collections import defaultdict

SCORE = {"1-0": 1.0, "0-1": 0.0, "1/2": 0.5}


def load(paths):
    rows = []
    for path in paths:
        with open(path, encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line.startswith("{"):
                    rows.append(json.loads(line))
    return rows


def wilson(p, n, z=1.64):
    """Untere Grenze des 90-%-Vertrauensbereichs für einen Anteil."""
    if n == 0:
        return 0.0
    denom = 1 + z * z / n
    centre = p + z * z / (2 * n)
    margin = z * math.sqrt(p * (1 - p) / n + z * z / (4 * n * n))
    return (centre - margin) / denom


def game_stats(games, max_depth):
    """prefix -> move -> [Partien, Punkte für die ziehende Seite, Siege, Remis, Niederlagen]."""
    stats = defaultdict(lambda: defaultdict(lambda: [0, 0.0, 0, 0, 0]))
    for g in games:
        yellow_score = SCORE[g["result"]]
        moves = g["moves"]
        for ply in range(min(max_depth, len(moves))):
            mover_score = yellow_score if ply % 2 == 0 else 1 - yellow_score
            entry = stats[" ".join(moves[:ply])][moves[ply]]
            entry[0] += 1
            entry[1] += mover_score
            entry[2 + (0 if mover_score == 1 else 1 if mover_score == 0.5 else 2)] += 1
    return stats


def rank_table(ranks):
    table = defaultdict(dict)
    for r in ranks:
        table[r["opening"]][r["move"]] = r
    return table


def build_book(ranks, stats, margin, max_moves, min_games, min_score, root_moves=None):
    """Buchzüge je Stellung: Züge nahe am Engine-Bestwert, die in Partien nicht schlecht abschneiden."""
    book = {}
    for prefix, moves in ranks.items():
        best = max(m["score"] for m in moves.values())
        chosen = []
        for name, m in sorted(moves.items(), key=lambda kv: -kv[1]["score"]):
            if m["score"] < best - margin:
                break
            weight = 10 - (best - m["score"]) * 9 // max(margin, 1)
            s = stats.get(prefix, {}).get(name)
            if s and s[0] >= min_games:
                # Ergebnis der Bot-Partien: schlechte Züge raus, gute häufiger.
                if s[1] / s[0] < min_score:
                    continue
                weight = weight * 2 * s[1] / s[0]
            chosen.append((name, max(1, round(weight))))
            if len(chosen) >= (root_moves or max_moves if prefix == "" else max_moves):
                break
        if chosen:
            book[prefix] = dict(chosen)
    return book


def write_book(path, book):
    with open(path, encoding="utf-8") as f:
        text = f.read()
    start = text.index("# BEGIN BOOK")
    end = text.index("# END BOOK")
    lines = ["# BEGIN BOOK", "const LINES := {"]
    for prefix in sorted(book, key=lambda p: (len(p.split()), p)):
        moves = ", ".join('"%s": %d' % kv for kv in book[prefix].items())
        lines.append('\t"%s": {%s},' % (prefix, moves))
    lines.append("}")
    text = text[:start] + "\n".join(lines) + "\n" + text[end:]
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)


def pct(x):
    return "%d %%" % round(100 * x)


def write_report(path, games, stats, ranks, book, notes=None):
    out = []
    n = len(games)
    yellow = sum(SCORE[g["result"]] for g in games)
    decided = sum(1 for g in games if g["result"] != "1/2")
    adjudicated = sum(1 for g in games if g["reason"] == "Wertung nach Material")
    out.append("# Eröffnungen aus Bot-gegen-Bot-Partien\n")
    out.append("Erzeugt mit `tools/bot_match.gd` und `tools/analyze_openings.py`.\n")
    if notes:
        with open(notes, encoding="utf-8") as f:
            out.append(f.read().strip() + "\n")
    out.append("## Überblick\n")
    out.append("- Partien: %d (davon %d entschieden, %d nach Materialvorsprung gewertet)" % (n, decided, adjudicated))
    if n:
        out.append("- Gelb (Anzugsseite) holt %s der Punkte" % pct(yellow / n))
        out.append("- Durchschnittliche Länge: %d Halbzüge" % round(sum(g["plies"] for g in games) / n))
    levels = sorted({"%s %d ms" % (g["yellow"], g["time_ms"]) for g in games})
    out.append("- Bots: %s\n" % ", ".join(levels))

    def table(prefix, title, limit=None):
        moves = ranks.get(prefix, {})
        played = stats.get(prefix, {})
        names = set(moves) | set(played)
        if not names:
            return
        rows = []
        for name in names:
            r = moves.get(name)
            s = played.get(name, [0, 0, 0, 0, 0])
            rows.append((r["score"] if r else None, name, s))
        rows.sort(key=lambda t: (t[0] is None, -(t[0] or 0), -t[2][0]))
        if limit:
            rows = rows[:limit]
        out.append("### %s\n" % title)
        out.append("| Zug | Engine-Wert | Partien | S / R / N | Punkte | Buch |")
        out.append("|---|---:|---:|---|---:|---:|")
        for score, name, s in rows:
            weight = book.get(prefix, {}).get(name, "")
            out.append("| %s | %s | %d | %d / %d / %d | %s | %s |" % (
                name, "–" if score is None else "%+d" % score, s[0], s[2], s[3], s[4],
                pct(s[1] / s[0]) if s[0] else "–", weight))
        out.append("")

    out.append("## Erster Zug von Gelb\n")
    out.append("Engine-Wert: Bewertung der Stufe Meister nach dem Zug, aus Sicht der ziehenden Seite, in "
               "Hundertstel Spearman (100 = ein Spearman). Partien: Bot-Partien, in denen der Zug gespielt wurde; "
               "Punkte aus Sicht der ziehenden Seite. Buch: Gewicht im Eröffnungsbuch.\n")
    table("", "Startstellung")
    out.append("## Antworten und Fortsetzungen\n")
    for prefix in sorted(ranks, key=lambda p: (len(p.split()), p)):
        if prefix:
            table(prefix, "Nach %s" % prefix, limit=12)

    out.append("## Häufigste Zugfolgen (erste vier Halbzüge, ab 3 Partien)\n")
    seqs = defaultdict(lambda: [0, 0.0])
    for g in games:
        if len(g["moves"]) >= 4:
            key = " ".join(g["moves"][:4])
            seqs[key][0] += 1
            seqs[key][1] += SCORE[g["result"]]
    rows = sorted(((v[0], v[1], k) for k, v in seqs.items() if v[0] >= 3), reverse=True)[:15]
    if rows:
        out.append("| Zugfolge | Partien | Punkte Gelb |")
        out.append("|---|---:|---:|")
        for cnt, pts, key in rows:
            out.append("| %s | %d | %s |" % (key, cnt, pct(pts / cnt)))
    else:
        out.append("Noch zu wenige Partien.")
    out.append("")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(out))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--games", nargs="*", default=[])
    ap.add_argument("--rank", nargs="*", default=[])
    ap.add_argument("--report")
    ap.add_argument("--book")
    ap.add_argument("--notes", help="Markdown-Datei mit Zusammenfassung, kommt an den Anfang des Berichts")
    ap.add_argument("--depth", type=int, default=8, help="Halbzüge, die für die Statistik zählen")
    ap.add_argument("--margin", type=int, default=40, help="Abstand zum Bestwert für Buchzüge")
    ap.add_argument("--max-moves", type=int, default=3)
    ap.add_argument("--root-moves", type=int, default=5, help="Buchzüge in der Startstellung")
    ap.add_argument("--min-games", type=int, default=6)
    ap.add_argument("--min-score", type=float, default=0.45)
    a = ap.parse_args()
    games = [g for g in load(a.games) if g.get("moves")]
    stats = game_stats(games, a.depth)
    ranks = rank_table(load(a.rank))
    book = build_book(ranks, stats, a.margin, a.max_moves, a.min_games, a.min_score, a.root_moves)
    if a.book:
        write_book(a.book, book)
    if a.report:
        write_report(a.report, games, stats, ranks, book, a.notes)
    print("Partien: %d, bewertete Stellungen: %d, Buchstellungen: %d" % (len(games), len(ranks), len(book)))


if __name__ == "__main__":
    main()
