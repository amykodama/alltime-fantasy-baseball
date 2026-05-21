# Experiments

Each experiment trains a stat→rating model for one OOTP rating, applies it
to era-adjusted historical stats, and writes a CSV of historical
predictions. The folder pattern is the same every time so a new person can
read any one of them and immediately know where to look.

## Folder convention

```
experiments/
└── 0N_<rating>_prediction/
    ├── README.md                      ← writeup: hypothesis, method, results, conclusions
    ├── requirements.txt               ← pinned Python deps
    ├── extract_era_adjusted_data.R    ← (optional) R script to pull from fullhouse
    ├── 01_load_and_join.ipynb         ← build the training set (modern overlap)
    ├── 02_train_<rating>_model.ipynb  ← train + validate
    ├── 03_predict_historical.ipynb    ← apply trained model to era-adjusted history
    ├── data/                          ← experiment-specific data
    └── outputs/                       ← plots, metrics.json, prediction CSVs
```

Numbering (`0N_`) is monotonic in the order experiments are *started*, not
in priority. Once started, never renumber — it would break notebooks and
docs that cross-reference each other.

## Naming

`<rating>` is the lowercase OOTP rating column:

- `pow`, `con`, `eye`, `spe`, `fld`, `arm` — hitter ratings
- `stu`, `mov`, `ctl`, `sta` — pitcher ratings

Examples that follow the convention:
- `01_pow_prediction/` ✅
- `02_con_prediction/` ✅
- `03_eye_prediction/` ✅

## Cross-experiment shared things

- **Labels source.** Every hitter experiment joins on
  `data/ootp_ratings/ootp_batting_ratings.csv` (the OOTP-exported ratings).
  Pitcher experiments will need a parallel pitcher-ratings export from OOTP.
- **Era-adjusted source.** Every experiment that touches historical players
  pulls from the `fullhouse` R package via
  `extract_era_adjusted_data.R`. The pattern in
  `01_pow_prediction/extract_era_adjusted_data.R` is the template — copy
  it, change the `.rda` it downloads if you need pitchers.
- **Train/test split.** Use `random_state=42` and 80/20 for comparability
  across experiments.

## Existing experiments

| # | Folder | Target | Status |
|---|---|---|---|
| 01 | `01_pow_prediction/` | POW (power) | ✅ Validated (MAE 5.14, R² 0.70), historical predictions written |

## Starting a new experiment

1. Copy `01_pow_prediction/` to `0N_<rating>_prediction/`.
2. Update `OOTP_PATH` cells if the labels column changes.
3. Update the feature engineering — for example, `02_con_prediction/`
   would use batting average and strikeout rate instead of HR rate.
4. Rerun `01` → `02` → `03` in order.
5. Update the experiment's own `README.md` with hypothesis, method,
   numbers, and conclusions.
6. Add your row to the table above.
7. Update the top-level `README.md` status table.

See `CONTRIBUTING.md` (repo root) for broader conventions.
