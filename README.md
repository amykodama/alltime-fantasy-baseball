# All-Time Fantasy Baseball

**URES Spring 2026 · Baseball Analytics Research · Advisor: Prof. Daniel J. Eck**

A research project to build a fantasy baseball league inside *Out of the Park
Baseball* (OOTP) where players from every era of MLB history — Ruth, Wagner,
Mays, Judge, Ohtani — can compete on the same roster with realistic,
non-deterministic outcomes.

## Why this is hard

OOTP is a powerful simulation engine but it doesn't take raw stats as input —
it uses an internal 20–80 rating system (POW, CON, EYE, SPE, FLD, ARM for
hitters; STU, MOV, CTL, STA for pitchers). To put any historical player into
the game, we have to convert their career stats into one of those rating
vectors.

So the central technical problem is: **learn a mapping from real-world
career stats → OOTP 20–80 ratings**, then apply it to era-adjusted historical
stats so a 1921 Ruth and a 2024 Judge are scored on the same scale.

## The pipeline

```
[Era-adjusted stats]   [Real career stats]   [OOTP in-game export]
        │                       │                       │
        └───────────────────────┴───────────────────────┘
                                │
                  ① Build training set (modern overlap)
                                │
                  ② Train stat → rating model
                                │
                  ③ Apply to era-adjusted history
                                │
                  ④ Generate OOTP-ready ratings CSV
                                │
                  ⑤ Import to OOTP custom league + simulate
```

Each phase has a home in this repo (see "Repository tour" below). The full
visual version is in `presentation/Big_Idea_Diagram.pptx`.

## Status as of May 2026

| Phase | Status | Where |
|---|---|---|
| Source data — modern stats (MLB Stats API) | ✅ working | `experiments/01_pow_prediction/01_load_and_join.ipynb` |
| Source data — era-adjusted stats (fullhouse) | ✅ working | `experiments/01_pow_prediction/extract_era_adjusted_data.R` |
| Source data — OOTP ratings | ✅ exported | `data/ootp_ratings/ootp_batting_ratings.csv` |
| Source data — OOTP career stats (in-game history) | ✅ parsed | `data/ootp_career_exports/` |
| Train POW (power rating) model | ✅ MAE 5.14, R² 0.70 | `experiments/01_pow_prediction/02_train_pow_model.ipynb` |
| Predict historical POW for ~9,600 batters | ✅ done | `experiments/01_pow_prediction/03_predict_historical.ipynb` |
| Train CON, EYE, SPE, FLD, ARM (hitter ratings) | ⬜ next | (open) |
| Train STU, MOV, CTL, STA (pitcher ratings) | ⬜ next | (open) |
| Stitch all ratings → OOTP roster import | ⬜ later | (open) |
| Simulate a full league season | ⬜ endgame | (open) |

**Bottom line:** the proof of concept works end-to-end, on one rating (POW),
for every batter in MLB history. The remaining work is repeating the
template for every other rating.

## Repository tour

```
alltime-fantasy-baseball/
├── README.md                  ← you are here
├── PROJECT_PLAN.md            ← the full vision, including unbuilt pieces
├── CONTRIBUTING.md            ← conventions for adding experiments + data
│
├── data/                      ← project-wide reference data
│   ├── ootp_ratings/          ← OOTP-exported labels (the training signal)
│   └── ootp_career_exports/   ← in-game career stats (raw + parsed)
│
├── scripts/                   ← shared utilities (currently: OOTP txt parser)
│
├── experiments/               ← one folder per experiment, self-contained
│   ├── README.md              ← experiment naming + template
│   └── 01_pow_prediction/     ← POW model + era-adjusted application
│
└── presentation/              ← the 5-min talk deck (.pptx; speaker notes embedded)
```

**If you're new to the project, read in this order:**

1. This README (status + repo layout)
2. `PROJECT_PLAN.md` (the full vision)
3. `experiments/01_pow_prediction/README.md` (full writeup of what works today)
4. `experiments/README.md` (how to add experiment 2)

## Getting started

```bash
git clone <repo-url>
cd alltime-fantasy-baseball

# Python environment for the experiments
cd experiments/01_pow_prediction
pip install -r requirements.txt

# R is needed once, to extract era-adjusted stats from the fullhouse package
# (see experiments/01_pow_prediction/README.md for details)
brew install r              # macOS; or apt/winget on other systems
Rscript extract_era_adjusted_data.R

# Then open the notebooks
jupyter lab                 # run 01 → 02 → 03 in order
```

## How to add a new experiment

Short version: copy `experiments/01_pow_prediction/` to
`experiments/0N_<rating>_prediction/`, change the target column, follow the
same `01_load_and_join` → `02_train_<rating>_model` → `03_predict_historical`
pattern. Full conventions are in `experiments/README.md` and
`CONTRIBUTING.md`.

## Next steps (prioritized)

1. **Sharpen POW** — add ISO (`SLG - AVG`) as a second feature. Targets the
   bottom-of-scale failure mode where contact hitters get over-predicted.
2. **Train CON** (contact rating) ← BA, K%. Same template, swap the target
   and features.
3. **Train EYE** ← BB%, chase rate.
4. **Train SPE** ← SB%, sprint speed.
5. **Train fielding ratings** (FLD, ARM) ← DRS, OAA, throw velocity.
6. **Train pitcher ratings** (STU, MOV, CTL, STA) ← K/9, velocity, BB/9, IP/start.
   Extend `extract_era_adjusted_data.R` to also export
   `pitchers_career_adjusted.rda` from the fullhouse package.
7. **Stitch all ratings into a single OOTP roster CSV** and import into a
   custom league. That's the project endgame: simulate 162-game seasons with
   players from every era on the same field.

The full version of this list, with feature ideas and edge cases (two-way
players like Ruth and Ohtani, pre-Statcast missing data, durability
mapping), is in `PROJECT_PLAN.md`.

## References

- Eck, D. J., et al. (2025). *Full House Modeling for era-adjusted career
  statistics in Major League Baseball.* https://github.com/DEck13/fullhouse
- Out of the Park Baseball (OOTP). https://www.ootpdevelopments.com/
- MLB Stats API. https://statsapi.mlb.com/
- Lahman Baseball Database. https://sabr.org/lahman-database/

## Acknowledgments

Conducted as part of Undergraduate Research Experience in Statistics (URES),
Spring 2026, under the guidance of Prof. Daniel J. Eck.
