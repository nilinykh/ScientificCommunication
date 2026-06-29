#!/usr/bin/env python
"""Per-domain feature stats and pairwise comparisons.

Reads parquet files produced by run_on_domains.sh and writes:
  outputs_domains/summary_<extractor>_means.csv  -- per-domain mean of every numeric feature
  outputs_domains/summary_<extractor>_long.csv   -- long-form (domain, feature, mean, std)
  outputs_domains/topdiff_<extractor>.csv        -- features with the largest pairwise mean gaps

Usage:
  python analyze_domain_features.py                       # both extractors
  python analyze_domain_features.py --extractor lftk
"""
from __future__ import annotations
import argparse
import itertools
from pathlib import Path
import pandas as pd
import numpy as np

REPO_DIR = Path(__file__).resolve().parent
OUT_DIR = REPO_DIR / "outputs_domains"


def load_extractor(extractor: str) -> pd.DataFrame:
    """Concatenate all <dataset>__<extractor>.parquet files, tagging with `domain`."""
    rows = []
    for p in sorted(OUT_DIR.glob(f"*__{extractor}.parquet")):
        domain = p.name.replace(f"__{extractor}.parquet", "")
        df = pd.read_parquet(p)
        df["__domain"] = domain
        rows.append(df)
    if not rows:
        raise SystemExit(f"No parquet files for extractor={extractor} under {OUT_DIR}")
    return pd.concat(rows, ignore_index=True)


def numeric_features(df: pd.DataFrame) -> list[str]:
    drop = {"__domain", "doc_id", "domain", "categories", "update_date",
            "title_clean", "text"}
    return [c for c in df.select_dtypes(include=[np.number]).columns if c not in drop]


def summarize(df: pd.DataFrame, extractor: str) -> None:
    feats = numeric_features(df)
    grp = df.groupby("__domain")[feats]
    means = grp.mean().T
    means.index.name = "feature"
    means.to_csv(OUT_DIR / f"summary_{extractor}_means.csv")

    long = (grp.agg(["mean", "std", "median"])
              .stack(level=0, future_stack=True)
              .reset_index()
              .rename(columns={"level_1": "feature"}))
    long.to_csv(OUT_DIR / f"summary_{extractor}_long.csv", index=False)

    # Pairwise gaps: for each feature, max - min across domain means
    gap = (means.max(axis=1) - means.min(axis=1)).abs()
    rel = gap / (means.abs().mean(axis=1) + 1e-9)
    top = pd.DataFrame({"abs_gap": gap, "rel_gap": rel}).sort_values(
        "rel_gap", ascending=False)
    top = top.join(means)
    top.to_csv(OUT_DIR / f"topdiff_{extractor}.csv")

    print(f"\n=== {extractor}: {len(feats)} numeric features, "
          f"{df['__domain'].nunique()} domains ===")
    print(top.head(15).round(4).to_string())


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--extractor", choices=["lftk", "elfen", "both"], default="both")
    args = ap.parse_args()
    targets = ["lftk", "elfen"] if args.extractor == "both" else [args.extractor]
    for ex in targets:
        try:
            df = load_extractor(ex)
        except SystemExit as e:
            print(e)
            continue
        summarize(df, ex)
    print(f"\nWrote outputs to {OUT_DIR}")


if __name__ == "__main__":
    main()
