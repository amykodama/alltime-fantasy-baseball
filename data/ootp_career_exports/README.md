# OOTP career exports

Per-player, per-year, per-team career stats exported from OOTP as `.txt`,
parsed into clean `.csv` by `scripts/parse_stats.py`.

```
ootp_career_exports/
├── raw/        ← original .txt files (comma-separated with header comments)
└── parsed/     ← clean .csv with column headers
```

Three stat categories, each represented as both a raw `.txt` and a parsed
`.csv`:

- **Batting** — plate appearances, hits, home runs, stolen bases, VORP, etc.
- **Pitching** — wins, losses, saves, innings pitched, strikeouts, WAR, BABIP, etc.
- **Fielding** — putouts, assists, errors, zone rating, range-factor breakdown, etc.

## Refreshing the data

From the repo root:

```bash
pip install -r scripts/requirements.txt
python scripts/parse_stats.py
```

The script reads every `.txt` in `raw/`, skips the leading comment block
(lines starting with `//`), strips the trailing `eol` marker from each row,
applies column headers, and writes the result to `parsed/`.

## Raw format quirks

- **Comment lines.** Files begin with a block of `//`-prefixed lines
  describing team IDs and the file format. Not included in the CSV output.
- **Trailing `eol` placeholder.** Every data row ends with a literal `eol`
  marker that carries no data — the parser drops the last column.
- **`split_id` column** distinguishes overall stats (`1`), vs LHP (`2`),
  vs RHP (`3`), and playoff stats (`21`).
- **`bbref_team_code` column** (batting and pitching files only) is an
  undocumented column between `league_level_id` and `bbrefid`. It's the
  Baseball Reference team code, which can differ from `team_abbr` for
  historical franchises — e.g., `ML1` for the 1954 Milwaukee Braves vs
  `ATL` for the modern Atlanta Braves.

## What experiments use this?

Currently: none of the experiments in `experiments/` use these files. They
were the earliest data pull for the project (April 2026, before the
fullhouse era-adjusted package was integrated). They're kept because:

1. They're a fully-OOTP-internal "ground truth" — useful for sanity-checking
   simulated outputs once the league is up and running.
2. They include splits and fielding detail the public Lahman/MLB-API
   sources don't expose cleanly.

Future experiments may use them — see `PROJECT_PLAN.md` for ideas.
