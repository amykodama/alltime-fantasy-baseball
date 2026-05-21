# Data

Project-wide reference data. Experiment-specific files (training sets,
prediction outputs, plots) live inside each experiment's own `data/` and
`outputs/` folders, not here.

## Contents

```
data/
├── ootp_ratings/
│   └── ootp_batting_ratings.csv     ← 667 modern hitters, OOTP 20-80 ratings
└── ootp_career_exports/
    ├── README.md                    ← raw format details
    ├── raw/                         ← OOTP's exported .txt files
    └── parsed/                      ← clean .csv versions (run scripts/parse_stats.py)
```

## Sources at a glance

| Dataset | Source | Refresh | Used by | License |
|---|---|---|---|---|
| `ootp_batting_ratings.csv` | Exported from an OOTP saved game (in-game report → CSV) | When OOTP rosters update | All hitter-rating experiments — this is the training-signal *labels* | OOTP proprietary; for research use only |
| `ootp_career_exports/` | Same OOTP save, "career stats" export | Same as above | Reference / cross-checks against simulated histories | Same |
| (external) MLB Stats API | https://statsapi.mlb.com — pulled on demand by notebook 1 | Always current | Modern-player training features | Free, no auth |
| (external) Lahman `People` table | `Lahman` R package on CRAN | ~Annual | Historical handedness in notebook 3 | Open data (Lahman license) |
| (external) `fullhouse` R package | https://github.com/DEck13/fullhouse | When Eck et al. update | Era-adjusted historical career stats (notebook 3) | See repo license |

## OOTP ratings — what's in the labels file?

`ootp_batting_ratings.csv` has one row per modern MLB hitter at the time of
the OOTP export. The columns the project actually uses today:

| Column | Meaning |
|---|---|
| `HistID` | Baseball Reference ID — the join key to external stats |
| `Name` | Display name |
| `POW` | Power rating, 20-80 (the target in experiment 1) |
| `B_1` | Bats — `L`, `R`, or `S` (switch) |

Many other columns are present (CON, EYE, SPE, FLD per position, ARM,
overall) and will become targets for future experiments. See
`ootp_batting_ratings.csv` directly for the full schema.

## How to refresh the OOTP exports

1. Open the OOTP saved game used as the rating source.
2. In-game: Reports → "Player Ratings" → export as CSV → save as
   `ootp_batting_ratings.csv` in `data/ootp_ratings/`.
3. For career stats (the `ootp_career_exports/` folder): Reports → "Career
   Stats" — three reports, one each for batting/pitching/fielding. Save as
   `.txt` into `data/ootp_career_exports/raw/`. Then run
   `python scripts/parse_stats.py` from the repo root to regenerate the
   parsed CSVs.

## How big is this?

| File | Size |
|---|---:|
| `ootp_batting_ratings.csv` | ~60 KB |
| `ootp_career_exports/raw/*.txt` | ~85 MB total |
| `ootp_career_exports/parsed/*.csv` | ~85 MB total |

The career-export files are large because they're per-player, per-year, per-team
rows for every player in every era. The repo commits them directly so the project
is self-contained without a separate data download.
