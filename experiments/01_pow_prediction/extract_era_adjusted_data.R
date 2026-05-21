# extract_era_adjusted_data.R
#
# One-time extraction script. Pulls era-adjusted career batting stats from the
# `fullhouse` GitHub repo (DEck13/fullhouse) and joins handedness from the
# `Lahman` R package, then writes a single CSV that
# 03_predict_historical.ipynb reads.
#
# Run from the experiment1/ directory:
#     Rscript extract_era_adjusted_data.R
#
# Output:
#     data/era_adjusted_batters.csv
#
# Columns:
#     playerID, name, nameFirst, nameLast, bats, throws,
#     PA, AB, H, HR, BB, BA, OBP, HBP, SF, ebWAR, efWAR
#
# Dependencies (kept intentionally minimal):
#   * base R (>= 3.5) -- download.file(), load(), merge(), write.csv()
#   * Lahman          -- pure data package, no system libraries needed
#
# We deliberately do NOT use devtools / remotes / fullhouse-as-installed-
# package, because devtools drags in textshaping, ragg, gert, etc., which
# require harfbuzz / fribidi / libgit2 system libraries and tend to fail on
# fresh Macs. Instead we just download the .rda data file directly.

# ---- 1. Lahman (pure-data CRAN package) ------------------------------------

cran_repo <- "https://cloud.r-project.org"

if (!requireNamespace("Lahman", quietly = TRUE)) {
    message("Installing Lahman from CRAN ...")
    install.packages("Lahman", repos = cran_repo)
}

# ---- 2. Download fullhouse era-adjusted batter dataset directly ------------

rda_url   <- "https://github.com/DEck13/fullhouse/raw/main/data/batters_career_adjusted.rda"
rda_local <- file.path("data", "batters_career_adjusted.rda")
dir.create("data", showWarnings = FALSE, recursive = TRUE)

if (!file.exists(rda_local)) {
    message("Downloading ", rda_url, " ...")
    download.file(rda_url, rda_local, mode = "wb")
} else {
    message("Using cached ", rda_local)
}

# load() creates `batters_career_adjusted` in this environment.
load(rda_local)

if (!exists("batters_career_adjusted") || !is.data.frame(batters_career_adjusted)) {
    stop("Expected `batters_career_adjusted` data.frame inside ", rda_local)
}

# ---- 3. Lahman People (handedness) -----------------------------------------

suppressPackageStartupMessages(library(Lahman))
data(People, package = "Lahman")

cat(sprintf("fullhouse  batters_career_adjusted : %d rows, %d cols\n",
            nrow(batters_career_adjusted), ncol(batters_career_adjusted)))
cat(sprintf("Lahman     People                  : %d rows\n", nrow(People)))

# ---- 4. Join era-adjusted batters to handedness ----------------------------

handedness <- People[, c("playerID", "bats", "throws", "nameFirst", "nameLast")]

out <- merge(batters_career_adjusted, handedness,
             by = "playerID", all.x = TRUE)

n_missing_bats <- sum(is.na(out$bats))
cat(sprintf("\nJoined: %d rows; missing bats = %d (%.1f%%)\n",
            nrow(out), n_missing_bats, 100 * n_missing_bats / nrow(out)))

# ---- 5. Reorder columns and write CSV --------------------------------------

col_order <- c(
    "playerID", "name", "nameFirst", "nameLast",
    "bats", "throws",
    "PA", "AB", "H", "HR", "BB", "BA", "OBP", "HBP", "SF",
    "ebWAR", "efWAR"
)
col_order <- intersect(col_order, names(out))
out <- out[, col_order]

output_path <- file.path("data", "era_adjusted_batters.csv")
write.csv(out, output_path, row.names = FALSE)

cat(sprintf("\nWrote %d rows to %s\n", nrow(out), output_path))
cat("Columns:\n  ", paste(names(out), collapse = ", "), "\n", sep = "")
