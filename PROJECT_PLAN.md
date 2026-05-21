# All-Time Fantasy Baseball Game — Project Plan

## Overview

The goal is to build an all-time fantasy baseball game using **Out of the Park Baseball (OOTP)** as the simulation engine, allowing players from different eras (e.g. Babe Ruth and Shohei Ohtani) to compete on the same roster with realistic, non-deterministic outcomes.

The core challenge is that OOTP does not use raw baseball stats directly — it uses an internal rating system. This plan describes how to bridge real (era-adjusted) baseball stats to OOTP's rating format using a machine learning translation model.

---

## Pipeline Overview

```
[Illinois era-adjusted dataset]  [Baseball Reference]  [OOTP player export]
           │                            │                        │
           └────────────────────────────┴────────────────────────┘
                                        │
                              Build training dataset
                         (modern overlap players only)
                                        │
                           Train stat → rating model
                         (gradient boosting per target)
                                        │
                     Apply model to historical era-adjusted stats
                                        │
                        Generate OOTP-ready player rating CSVs
                                        │
                      Import into OOTP custom league + simulate
```

---

## Phase 1 — Source Data Collection

### The "Rosetta Stone" Cohort

The key is identifying **modern players (~1990–2024)** for whom you have both:
- Real baseball stats (from Baseball Reference)
- OOTP internal ratings (exported from the game)

These overlap players form your labeled training set.

### Data Sources

| Source | Purpose | Access Method |
|---|---|---|
| [Illinois Era-Adjusted Dataset](https://eckeraadjustment.web.illinois.edu/) | Era-normalized stats for all historical players | Download from site |
| Baseball Reference | Rate stats for modern players | `pybaseball` Python library |
| OOTP Player Export | In-game ratings as training labels | In-game CSV export / report system |

### OOTP Export

From any OOTP saved game, you can export player data as CSV via the built-in report system. Key rating fields to capture:

**Hitters:** Contact vs L, Contact vs R, Power vs L, Power vs R, Eye/Discipline, Avoid K, Speed, Fielding (per position), Arm

**Pitchers:** Stuff, Movement, Control, Stamina, per-pitch ratings (fastball, breaking ball, changeup, etc.)

---

## Phase 2 — Feature Engineering

Use **rate stats**, not counting stats, so that modern and historical players exist in the same statistical space after era adjustment.

### Hitter Features

- K%, BB%, ISO, wRC+ (or OPS+), BABIP
- wOBA, hard-hit rate
- Sprint speed / SB% (proxy for Speed rating)
- Fielding metrics (DRS, OAA) per position

### Pitcher Features

- K/9, BB/9, HR/9
- FIP, xFIP
- Groundball rate, fly ball rate
- Average fastball velocity (Statcast era; use era-adjusted proxies for older players)
- Strikeout-to-walk ratio

> **Note:** For pre-Statcast players, velocity and batted ball data won't be available. The Illinois dataset's era-adjusted figures should compensate for most of this. You may need to impute or exclude velocity-dependent features for those players.

---

## Phase 3 — Training the Translation Model

### Approach

Train a separate model **per rating target** using the modern overlap cohort as your labeled dataset.

- **Model type:** Gradient boosting (XGBoost or LightGBM) — handles non-linearity, robust to smaller datasets, and gives feature importance for interpretability
- **Separate models for hitters and pitchers**
- Use cross-validation to evaluate predictions on a holdout set

### Sanity Checks

After training, generate ratings for well-known modern players and compare to OOTP's own historical roster ratings:

- Mike Trout → should score high on Contact, Eye, Speed
- Barry Bonds (~2001–2004) → should show elite Power, Eye
- Pedro Martinez → high Stuff, Movement, Control
- Randy Johnson → elite Stuff, but lower Control than Pedro

If the model's outputs broadly agree with OOTP's own assessments of these players, the translation is working.

### Output

One predicted rating vector per player:

```
player_id, name, contact_l, contact_r, power_l, power_r, eye, avoid_k,
speed, fielding, arm, [pitcher fields if applicable...]
```

---

## Phase 4 — Inference on Historical Players

Apply the trained model to era-adjusted stats from the Illinois dataset to generate ratings for historical players.

### Standard Cases

Most historical players will be straightforward: feed their era-adjusted rate stats through the appropriate hitter or pitcher model and output a rating vector.

### Edge Cases to Handle

**Two-way players (Ruth, Ohtani)**

OOTP supports two-way players natively. For these players:
1. Run both the hitter model and pitcher model on their respective stats
2. Assign both hitting and pitching rating blocks in the roster file
3. Set position eligibility to include both pitcher and their outfield/DH position

For **Babe Ruth specifically:** the Illinois dataset should have his pitching stats (1914–1919) and hitting stats separated. Treat him as two-way and flag accordingly.

**Era spread and workload**

OOTP uses Stamina and Durability ratings that relate to workload, not just per-game performance. Map these from:
- Innings pitched per season → Stamina
- Career length and injury history → Durability

A 1920s pitcher throwing 300+ innings is a different durability profile than a modern ace.

**Missing data**

Pre-Statcast players will lack velocity and batted ball data. Options:
- Train a model version without those features for older players
- Impute using era and role averages
- Simply exclude those features and rely on rate stat proxies

---

## Phase 5 — OOTP Custom League Setup

### Import Workflow

1. Generate the final player rating CSV from model output
2. Create a new custom league in OOTP (fictional teams, custom schedule)
3. Import player ratings using OOTP's built-in editor or via the `.ootp` roster file format
4. Draft or assign players to teams
5. Simulate seasons

### Non-Determinism

OOTP's simulation engine already introduces game-to-game variance through its internal game engine — you do not need to add randomness yourself. This is one of the strongest arguments for using OOTP as the backbone rather than building a sim from scratch.

### League Structure Ideas

- 4–8 fictional franchises, each drafting from the all-time player pool
- Snake draft or auction format
- Simulate a full 162-game season with playoffs
- Track stats across simulated seasons to compare eras

---

## Recommended Tech Stack

| Tool | Purpose |
|---|---|
| Python (pandas, scikit-learn, XGBoost) | Data pipeline and model training |
| `pybaseball` | Fetch Baseball Reference and Statcast data |
| Jupyter Notebooks | Iterative development and validation |
| OOTP CSV export/import | Bridge between model output and game |

### Suggested Notebook Structure

1. `01_data_collection.ipynb` — pull Baseball Reference stats and OOTP exports
2. `02_feature_engineering.ipynb` — build the training dataset
3. `03_model_training.ipynb` — train and validate the translation models
4. `04_inference.ipynb` — apply models to historical era-adjusted stats
5. `05_roster_export.ipynb` — format output for OOTP import

---

## Open Questions / Next Steps

- [ ] Confirm which OOTP rating fields are exportable and their scale (1–20? 1–200?)
- [ ] Determine how many modern players overlap between Baseball Reference and OOTP exports (training set size)
- [ ] Decide on handling strategy for pre-Statcast missing features
- [ ] Validate that OOTP supports two-way player imports in custom leagues
- [ ] Design draft format and team structure for the fantasy league
