import os

import pandas as pd

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
RAW_DATA_DIR = os.path.join(SCRIPT_DIR, "..", "raw_data")
PARSED_DATA_DIR = os.path.join(SCRIPT_DIR, "..", "parsed_data")

BATTING_HEADERS = [
    "player ID", "lastname", "firstname", "year", "team ID",
    "g", "gs", "pa", "ab", "h", "2b", "3b", "hr", "rbi", "r",
    "sb", "cs", "bb", "hp", "k", "sh", "sf", "gdp", "ibb", "ci",
    "pitches seen", "vorp", "split_id", "team_abbr", "league_abbr",
    "team_name", "league_name", "league_level_id",
    "bbref_team_code", "bbrefid", "bbrefminorid", "OOTP pID",
]

PITCHING_HEADERS = [
    "player ID", "lastname", "firstname", "year", "team id",
    "g", "gs", "w", "l", "s", "ip", "ha", "r", "er", "bb", "hp", "k",
    "bf", "ab", "1b", "2b", "3b", "hr", "tb", "sh", "sf", "ci", "iw",
    "bk", "wp", "dp", "qs", "svopp", "blownsv", "reliefapp", "cg", "sho",
    "holds", "sb", "cs", "gb", "fb", "pitches", "runsupport", "war", "babip",
    "split_id", "team_abbr", "league_abbr", "team_name", "league_name",
    "league_level_id", "bbref_team_code", "bbrefid", "bbrefminorid", "OOTP pID",
]

FIELDING_HEADERS = [
    "player ID", "lastname", "firstname", "year", "team id",
    "position", "g", "gs", "ip", "tc", "po", "a", "e", "dp", "tp", "pb",
    "sb attempts", "cs", "plays", "plays_base", "team_abbr", "league_abbr",
    "team_name", "league_name", "league_level_id", "bbref_id", "bbref_minor_id",
    "roe", "opp_0", "made_0", "opp_1", "made_1", "opp_2", "made_2",
    "opp_3", "made_3", "opp_4", "made_4", "opp_5", "made_5", "zr", "OOTP pID",
]

FILE_CONFIGS = [
    ("player_batting_stats.txt", "player_batting_stats.csv", BATTING_HEADERS),
    ("player_pitching_stats.txt", "player_pitching_stats.csv", PITCHING_HEADERS),
    ("player_fielding_stats.txt", "player_fielding_stats.csv", FIELDING_HEADERS),
]


def count_comment_lines(path):
    count = 0
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            stripped = line.strip()
            if stripped.startswith("//") or not stripped:
                count += 1
            else:
                break
    return count


def convert_file(input_path, output_path, headers):
    skip = count_comment_lines(input_path)

    df = pd.read_csv(
        input_path,
        skiprows=skip,
        header=None,
        encoding="utf-8",
        skip_blank_lines=True,
    )

    # Drop trailing "eol" placeholder column
    df = df.iloc[:, :-1]

    df.columns = headers
    df.to_csv(output_path, index=False)

    return len(df)


def main():
    for txt_name, csv_name, headers in FILE_CONFIGS:
        input_path = os.path.join(RAW_DATA_DIR, txt_name)
        output_path = os.path.join(PARSED_DATA_DIR, csv_name)

        if not os.path.exists(input_path):
            print(f"Skipping {txt_name} (file not found)")
            continue

        print(f"Converting {txt_name} -> {csv_name} ({len(headers)} columns)...")
        rows = convert_file(input_path, output_path, headers)
        print(f"  Done: {rows} rows written")


if __name__ == "__main__":
    main()
