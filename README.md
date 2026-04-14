# alltime-fantasy-baseball

URES Spring 2026. Baseball Analytics Research under guidance of Professor Daniel J Eck.

## Overview

This project contains historical MLB player statistics exported from OOTP (Out of the Park Baseball). The raw data comes as `.txt` files with comma-separated values and is parsed into standard `.csv` files for analysis.

Three stat categories are included:

- **Batting** -- plate appearances, hits, home runs, stolen bases, VORP, etc.
- **Pitching** -- wins, losses, saves, innings pitched, strikeouts, WAR, BABIP, etc.
- **Fielding** -- putouts, assists, errors, zone rating, range factor breakdown, etc.

Each file contains per-player, per-year, per-team rows. A `split_id` column distinguishes overall stats (1), vs LHP (2), vs RHP (3), and playoff stats (21).

## Folder Structure

```
alltime-fantasy-baseball/
  README.md
  raw_data/           # Original .txt exports from OOTP
  parsed_data/        # Cleaned .csv files with proper headers
  scripts/            # Parser script and dependencies
```

## Usage

Install dependencies and run the parser from the repo root:

```bash
pip install -r scripts/requirements.txt
python scripts/parse_stats.py
```

The script reads every `.txt` file in `raw_data/`, skips the leading comment block (lines starting with `//`), strips the trailing `eol` marker from each row, applies column headers, and writes the result to `parsed_data/`.

## Notes on the Raw Data Format

- Lines starting with `//` are comments describing team IDs and the file format. These are not included in the CSV output.
- Every data row ends with a trailing `eol` (end-of-line) placeholder that carries no data.
- The batting and pitching files contain one undocumented column (`bbref_team_code`) between `league_level_id` and `bbrefid`. This is the Baseball Reference team code, which can differ from `team_abbr` for historical franchises (e.g., `ML1` for the 1954 Milwaukee Braves vs `ATL`).
