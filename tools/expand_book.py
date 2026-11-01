#!/usr/bin/env python3
"""Baut den Eröffnungsbaum automatisch aus.

Bewertet mit tools/bot_match.gd (Modus "rank") jede Stellung, die über Buchzüge
erreicht wird und noch keine Bewertung hat, bis die Zugfolgen --depth Halbzüge
lang sind. Mehrere Godot-Prozesse laufen parallel.

Aufruf:
  python3 tools/expand_book.py --godot /pfad/zu/godot --rank docs/daten/bewertungen.jsonl \
      --games docs/daten/partien.jsonl --depth 5 --jobs 4
"""
import argparse
import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import analyze_openings as ao  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def rank(godot, prefix, time_ms, out):
    tmp = "%s.%d.part" % (out, abs(hash(prefix)))
    subprocess.run([godot, "--headless", "--path", ROOT, "-s", "tools/bot_match.gd", "--",
                    "--mode", "rank", "--yellow", "master", "--time", str(time_ms),
                    "--opening", prefix, "--out", tmp],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False)
    return tmp


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--godot", required=True)
    ap.add_argument("--rank", required=True, help="Bewertungsdatei, wird ergänzt")
    ap.add_argument("--games", nargs="*", default=[])
    ap.add_argument("--depth", type=int, default=5, help="Länge der Buchlinien in Halbzügen")
    ap.add_argument("--jobs", type=int, default=4)
    ap.add_argument("--time", type=int, default=3000)
    ap.add_argument("--margin", type=int, default=40)
    ap.add_argument("--max-moves", type=int, default=2, help="verfolgte Fortsetzungen je Stellung")
    ap.add_argument("--root-moves", type=int, default=5)
    a = ap.parse_args()
    stats = ao.game_stats([g for g in ao.load(a.games) if g.get("moves")], 8)
    while True:
        ranks = ao.rank_table(ao.load([a.rank]) if os.path.exists(a.rank) else [])
        if "" not in ranks:
            todo = [""]
        else:
            book = ao.build_book(ranks, stats, a.margin, a.max_moves, 6, 0.45, a.root_moves)
            todo = sorted({(p + " " + m).strip() for p, moves in book.items() for m in moves
                           if len(p.split()) + 1 < a.depth} - set(ranks))
        if not todo:
            break
        print("Bewerte %d Stellungen ..." % len(todo), flush=True)
        with ThreadPoolExecutor(a.jobs) as pool:
            parts = list(pool.map(lambda p: rank(a.godot, p, a.time, a.rank), todo))
        with open(a.rank, "a", encoding="utf-8") as out:
            for part in parts:
                if os.path.exists(part):
                    with open(part, encoding="utf-8") as f:
                        out.write(f.read())
                    os.remove(part)
    print("Fertig: %d bewertete Stellungen" % len(ranks))


if __name__ == "__main__":
    main()
