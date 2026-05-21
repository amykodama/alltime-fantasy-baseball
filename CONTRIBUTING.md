# Contributing

This is a research project being handed off across semesters. The goal of
this doc is to make your first hour on the project productive.

## Read first

1. `README.md` — what the project is, what's done, what's next.
2. `PROJECT_PLAN.md` — the full vision, including pieces nobody's built yet.
3. `experiments/01_pow_prediction/README.md` — the only complete experiment
   today, and the template for everything else.

## Repo conventions

### Where things live

| If you're adding… | Put it in… |
|---|---|
| A new experiment (training a new rating) | `experiments/0N_<rating>_prediction/` — copy 01 as a template |
| A new data source used by multiple experiments | `data/<source_name>/` with its own README |
| A new data source used by one experiment | That experiment's `data/` folder |
| A shared utility script | `scripts/` |
| A new version of the talk deck | `presentation/` (edit the .pptx directly in PowerPoint/Keynote) |
| A new project-level doc | Repo root (use `.md`) |

### Naming

- Experiments: `0N_<rating>_prediction/` — lowercase, underscore-separated.
  See `experiments/README.md` for the full convention.
- Notebooks: `0N_<action>.ipynb`. Always two-digit prefix so they sort
  correctly in file listings.
- Generated outputs: write to `outputs/` inside the experiment folder, not
  to `data/`. `data/` is for inputs and intermediate joined frames.

### Reproducibility

- Use `random_state=42` and an 80/20 train/test split for cross-experiment
  comparability.
- Pin Python dependencies in each experiment's own `requirements.txt`.
- Don't commit caches (`.mlb_career_cache.json`, `.pybaseball_cache/`,
  `node_modules/`) — they're in `.gitignore`. Notebooks should
  regenerate them on first run.
- Commit generated CSVs *only* when they're inputs to other notebooks
  (so people can skip ahead) or are the experiment's deliverable.

## Workflow for a new experiment

1. `cp -r experiments/01_pow_prediction experiments/0N_<rating>_prediction`
2. In notebook 1, change `OOTP_PATH` if needed and update the features.
3. In notebook 2, rename it to `02_train_<rating>_model.ipynb` and swap the
   target column (`POW` → e.g. `CON`).
4. In notebook 3, update the feature engineering to match notebook 1.
5. Run 01 → 02 → 03 end-to-end. Make sure your outputs land in
   `outputs/`, not at the repo root.
6. Rewrite the experiment `README.md` — hypothesis, method, results table
   with MAE/R², conclusions, next steps. Keep the structure the same as
   experiment 1 so future readers know where to look.
7. Add a row to `experiments/README.md` and update the status table in the
   top-level `README.md`.

## What *not* to do

- **Don't commit OOTP licensed data outside this repo's scope.** The OOTP
  exports here are used for academic research. Don't redistribute the
  `.csv`s separately.
- **Don't change the era-adjusted source without flagging it.** The
  `fullhouse` R package (Eck et al., 2025) is the canonical source.
  Switching would invalidate cross-experiment comparisons.
- **Don't renumber existing experiments.** Numbers are stable once assigned.

## Questions

Ask the project advisor (Prof. Daniel J. Eck), or open an issue / PR with
the question in the title.
