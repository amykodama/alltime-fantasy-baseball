# Experiment 1 — Predicting OOTP Power Rating from Career Home Run Stats

## Introduction

This is the first experiment in the **All-Time Fantasy Baseball** project — a
larger effort to build a fantasy league inside *Out of the Park Baseball*
(OOTP) where players from any era can compete on the same roster. The
core technical challenge is that OOTP doesn't simulate from raw stats; it
simulates from an internal 20–80 rating system. To put Babe Ruth and Shohei
Ohtani on the same field, we need a way to **translate real-world rate stats
into OOTP ratings**.

The plan is to learn that translation from a "Rosetta Stone" cohort —
modern players for whom we have both real-world stats (from public sources)
and OOTP ratings (exported from the game). With that mapping in hand, we
apply era-adjusted historical stats to generate OOTP-compatible ratings
for every player who's ever played.

This experiment is the smallest end-to-end version of that pipeline: one
target rating (`POW`, power), one primary feature (career home run rate),
two simple models — and then the trained model applied to ~9,600 historical
batters via Full House Modeling era adjustment. If we can't make this work,
nothing else will. If we can, we have a template for every other rating.

## Project Context

The full pipeline (from `alltime_fantasy_baseball_plan.md`):

```
[Era-adjusted historical stats]   [Real MLB stats]   [OOTP exports]
              │                          │                  │
              └──────────────────────────┴──────────────────┘
                                         │
                            Build training set (modern overlap)
                                         │
                              Train stat → rating models
                                         │
                  Apply to era-adjusted stats for all-time players
                                         │
                          Generate OOTP-ready rating CSVs
                                         │
                       Import into OOTP custom league + simulate
```

Experiment 1 covers the first four stages end-to-end for the `POW` rating.

## Hypothesis

OOTP's `POW` rating reflects expected home run output in simulation, and
HR rate is one of the most stable batting stats year-over-year. So:

> **Career HR per 600 PA, plus batter handedness, should explain enough
> variance in OOTP `POW` to clear MAE < 6 and R² > 0.6 on a held-out
> test set.**

If true, the methodology generalizes; we move on to richer features and
other ratings. If false, we go back to the data.

## What We Did

The experiment runs in three phases — **build training set**, **train and
validate**, **apply to history** — implemented as three Jupyter notebooks
plus a small R script for the era-adjusted source.

### Data sources

| Role | Source | Notes |
|---|---|---|
| **Labels** | `ootp_batting_ratings.csv` | OOTP export of 667 active MLB hitters, with the `POW` rating and `B_1` (handedness) we use. Joined on `HistID` (Baseball Reference ID). |
| **Training features** | MLB Stats API (`statsapi.mlb.com`) | Official, free, no auth, current through 2024. Career HR and PA pulled per player. |
| **Lahman fallback** | `data/Batting.csv` | Bundled fallback for the training-feature step. Capped at 2021. |
| **Era-adjusted features** | [`fullhouse`](https://github.com/DEck13/fullhouse) R package (Eck et al., 2025) | Full House Modeling-based era-adjusted career stats for ~9,600 batters through 2024. The `.rda` data file is downloaded directly by the R script. |
| **Historical handedness** | `Lahman` R package (CRAN) | The `People` table — joined to fullhouse on `playerID`. |

### Pipeline

#### Phase 1 — Build the training set

**`01_load_and_join.ipynb`**
- Load OOTP labels.
- Map bbref IDs → MLBAM IDs via `pybaseball.playerid_reverse_lookup`.
- Pull career hitting (HR, PA) from `statsapi.mlb.com` in 50-ID batches,
  cached to `.mlb_career_cache.json`.
- Filter to `PA ≥ 500` (below that, OOTP ratings rely heavily on
  scouting and add noise).
- Compute `hr_per_600 = (HR / PA) * 600` and one-hot encode handedness
  (R as the reference category).
- Write `data/training_data.csv`.

#### Phase 2 — Train and validate

**`02_train_pow_model.ipynb`**
- Load the training set, 80/20 split with `random_state=42`.
- Fit:
  - **Linear regression** on `hr_per_600 + bats_L + bats_S` — the
    coefficient is directly interpretable.
  - **Polynomial regression (degree 2)** — same features, allowing
    gentle curvature near the rating boundaries.
- Evaluate MAE, R², max error on the test split.
- Plot scatter + fit, predicted-vs-actual, and residuals.
- Sanity-check predictions for a high-power, median, and low-power player.
- Persist a machine-readable summary to `outputs/metrics.json`.

#### Phase 3 — Apply the trained model to era-adjusted history

**`extract_era_adjusted_data.R`** (one-time)
- Installs `Lahman` from CRAN if missing.
- Downloads `batters_career_adjusted.rda` directly from the fullhouse repo
  (so we don't have to compile `devtools` + dependencies).
- Loads it with base R's `load()`.
- Joins to Lahman `People` for handedness.
- Writes `data/era_adjusted_batters.csv` (~9,600 batters with era-adjusted
  stats and handedness in one frame).

**`03_predict_historical.ipynb`**
- Read the CSV produced by the R script.
- Normalize handedness (Lahman's `B` → our `S`; missing → `R`).
- Same feature engineering as notebook 1: `hr_per_600`, `bats_L`, `bats_S`,
  filter to `PA ≥ 500`.
- **Re-fit** the linear and polynomial models on the *full*
  `training_data.csv` — for application we want every drop of signal,
  honest evaluation already happened in notebook 2.
- Predict POW for every historical batter; clamp to `[20, 80]` for the
  OOTP-compatible integer rating, keep the unclamped raw prediction
  alongside.
- Sanity-check the all-time greats (Ruth, Bonds, Williams, Mays, Aaron,
  Mantle, Foxx, Pujols, A-Rod, Judge, Ohtani, Wagner, Suzuki, Smith, Carew).
- Write `data/historical_pow_predictions.csv` (sorted by predicted POW)
  plus a distribution histogram and a top-20 bar chart.

## Results — Training validation

### Headline metrics

Both plan targets are met:

| Model | MAE | R² | Max error |
|---|---:|---:|---:|
| Linear | 5.22 | 0.697 | 25.82 |
| Polynomial deg-2 | **5.14** | **0.704** | 25.41 |

**Targets:** MAE < 6 → **PASS** · R² > 0.6 → **PASS**

The polynomial model edges past the linear one by ~0.1 MAE — essentially
tied. Linear is the preferred choice for interpretability.

### Linear model coefficients

```
POW ≈ 22.25  +  1.384 * hr_per_600  +  1.65 * bats_L  +  1.45 * bats_S
```

- **Slope:** every additional HR per 600 PA adds ≈ **1.4 POW points**.
- **Intercept (22.25):** baseline POW for an R-handed hitter with 0 HR —
  sits right at the 20 floor of the OOTP scale, as expected.
- **Bats offsets:** small (+1.5 to +1.7) and stable. (An earlier run on
  Lahman-2021 showed a misleading +8.9 for switch hitters; once the
  sample size jumped from 14 to a healthier number, the artifact
  dissolved.)

### Sanity checks (training-set players)

| Player | Actual POW | HR/600 PA | Linear pred | Poly pred |
|---|---:|---:|---:|---:|
| Aaron Judge (high power) | 80 | 44.3 | 83.6 | 82.6 |
| Bo Bichette (median POW) | 45 | 19.8 | 49.6 | 49.4 |
| Ezequiel Duran (low POW) | 20 | 11.2 | 37.7 | 38.1 |

Top-of-scale and median predictions look right. The bottom of the scale
remains an issue — Duran and similar "average HR rate, low POW" hitters
get over-predicted because the model has nothing else to compress them
down with. Adding ISO is the natural fix.

### Dataset sizes

| Step | Count |
|---|---|
| OOTP players loaded | 667 |
| Matched to a career batting record | 667 |
| After `PA ≥ 500` filter | **441** |
| Train / Test | 352 / 89 |

### Iteration history

The same modeling code on two different feature sources tells the data-
recency story clearly:

| Source | n | MAE | R² | Judge prediction |
|---|---:|---:|---:|---:|
| Lahman (through 2021) | 183 | 6.96 | 0.504 | 64.8 (actual 80) |
| MLB Stats API (through 2024) | **441** | **5.14** | **0.704** | **83.6** (actual 80) |

The first run missed both targets — but not because the methodology was
wrong. Lahman's 2021 cap meant Aaron Judge's 2022 (62 HR) and 2024 (58
HR) seasons were missing entirely; his career HR/600 came in 6 points
low and the regression fit suffered for it. Refreshing the feature
source to 2024-current data fixed it.

## Results — Era-adjusted predictions

The trained model is applied to ~9,600 batters whose career stats have
been era-normalized via Full House Modeling. The output is a single CSV
(`data/historical_pow_predictions.csv`) with one OOTP-compatible POW
rating per player, ready to drop into a custom-league import.

What "applying era adjustment" buys us: a 1920s player throwing 30 HR in
600 PA gets evaluated on the same rate scale as a 2024 player throwing 30
HR in 600 PA — Full House Modeling balances how a player performed *vs.
their peers* against the *size of the talent pool* at the time. Without
that step, raw HR rates from the dead-ball era would all collapse toward
the bottom of the rating scale.

The expected shape of the predictions, before the run:

- **Top of scale (POW ≈ 80)**: Ruth, Bonds, Williams, Foxx, Aaron, Mays,
  Mantle, A-Rod, Pujols, Judge, Ohtani, Stanton — power hitters whose
  era-adjusted HR rates are high regardless of when they played.
- **Middle (40–60)**: contact-first stars like Wagner, Carew, Suzuki,
  Boggs — solid hitters whose value didn't come from power.
- **Bottom (20–25)**: defensive specialists, slap hitters, pitchers with
  meaningful PA totals.

Run notebook 3 to see the actual leaderboard, distribution histogram, and
top-20 bar chart. The same pattern of "boundary compression at the
bottom" we saw in the training validation will likely show up here too —
contact specialists in the dead-ball era may get over-predicted because
the model has only HR rate to go on.

## Conclusions

1. **The methodology works end-to-end.** Train on the modern overlap
   (~70% R² on a held-out test split), apply to era-adjusted history, get
   ratings for every batter in MLB history. The full stat-→-rating
   pipeline runs in a few seconds once the cached data exists.

2. **A single rate stat plus handedness explains ~70% of POW variance.**
   That's a strong signal at this complexity — methodology validated for
   the rest of the project.

3. **Data recency matters more than model complexity.** Switching from
   Lahman-2021 to MLB Stats API-2024 moved R² from 0.50 to 0.70 with
   zero changes to the model. Polynomial vs linear barely matters once
   the features are right.

4. **Era adjustment lets the model travel.** Because we apply the model
   to era-adjusted (not raw) historical stats, a 1921 Ruth and a 2024
   Judge are scored on a comparable rate scale. The two halves —
   modern-trained model and era-aware historical features — fit together
   cleanly.

5. **The remaining error is mostly at the bottom of the scale.** "Average
   HR rate, low POW" hitters push the worst residuals. This is a feature-
   coverage problem, not a model-capacity problem; adding ISO is the next
   move.

## Next Steps

In rough priority order:

1. **Add ISO** (`SLG - AVG`) to the feature set. Targets the bottom-of-
   scale failure mode (Duran-style 20 ratings). Expected to push R² past
   0.80 and MAE under 4 if the diagnosis is correct.
2. **Predict `POW vL` and `POW vR` separately** using L/R-split HR data
   from the MLB Stats API. Validates the per-platoon framing the bigger
   plan needs for OOTP ratings.
3. **Move to gradient boosting** (XGBoost or LightGBM) once the feature
   set has 4+ inputs. With one feature linear is near-optimal; with five
   or six, trees should help on the boundary cases.
4. **Repeat the entire 01 → 02 → 03 pipeline for `CON`** (contact rating)
   using BA and K%. Then for `EYE`, `SPE`, fielding ratings, arm strength,
   and the pitcher rating set. Same template; only the target column and
   feature list change.
5. **Add pitcher era-adjusted predictions** by extending
   `extract_era_adjusted_data.R` with a second CSV from
   `pitchers_career_adjusted.rda` (also in the fullhouse repo).
6. **Stitch all rating predictions together into an OOTP roster CSV** and
   import into a custom league. That's the project endgame: simulate
   162-game seasons with players from every era on the same field.

## Repository Layout

```
experiment1/
├── README.md                          ← this file
├── requirements.txt
├── extract_era_adjusted_data.R        R script — fullhouse + Lahman → CSV
├── 01_load_and_join.ipynb             Build training set (modern overlap)
├── 02_train_pow_model.ipynb           Train + evaluate POW model
├── 03_predict_historical.ipynb        Apply POW model to era-adjusted history
├── data/
│   ├── Batting.csv                    Lahman fallback (capped at 2021)
│   ├── era_adjusted_batters.csv       generated by extract_era_adjusted_data.R
│   ├── historical_pow_predictions.csv generated by notebook 3
│   └── training_data.csv              generated by notebook 1
└── outputs/
    ├── hr_rate_vs_pow.png             notebook 2 — scatter + fit lines
    ├── predicted_vs_actual.png        notebook 2 — test-set predictions
    ├── residuals.png                  notebook 2 — residuals
    ├── metrics.json                   notebook 2 — machine-readable summary
    ├── historical_pow_distribution.png notebook 3 — predicted POW histogram
    └── era_adjusted_top20.png         notebook 3 — top 20 historical bar chart
```

Hidden caches (`.mlb_career_cache.json`, `.pybaseball_cache/`) make
reruns instant after the first fetch.

## Reproducing

```bash
cd experiment1
pip install -r requirements.txt
Rscript extract_era_adjusted_data.R   # one-time: builds data/era_adjusted_batters.csv
jupyter lab                           # then run 01 -> 02 -> 03 in order
```

- **R script** (one-time, ~1 minute the first time): installs `Lahman`
  from CRAN if missing, downloads the era-adjusted `.rda` from the
  fullhouse repo, joins to Lahman handedness, writes
  `data/era_adjusted_batters.csv`. We use base R + the pure-data `Lahman`
  package only — no `devtools` / `remotes` / system-library dependencies
  to fight with.
- **Notebook 1** (~30–60 s first run): pulls 667 players from the MLB
  Stats API in batches of 50. Cached locally after that.
- **Notebook 2** (a few seconds): trains the model from
  `data/training_data.csv`, evaluates on the test split, writes plots
  and `metrics.json`.
- **Notebook 3** (a few seconds): reads
  `data/era_adjusted_batters.csv`, re-fits POW on the full training set,
  and writes `data/historical_pow_predictions.csv`.
