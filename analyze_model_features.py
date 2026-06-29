"""Same as analyze_domain_features.py but reads outputs_models/*__lftk.parquet.

Usage:
    python analyze_model_features.py            # all sets (incl. human_human)
    python analyze_model_features.py --no-hh    # only qwen role sets
"""
import argparse, glob, os
import pandas as pd

ap = argparse.ArgumentParser()
ap.add_argument("--no-hh", action="store_true", help="exclude human_human")
ap.add_argument("--dir", default="outputs_models")
ap.add_argument("--topn", type=int, default=20)
args = ap.parse_args()

files = sorted(glob.glob(f"{args.dir}/*__lftk.parquet"))
if args.no_hh:
    files = [f for f in files if "human_human" not in f]

frames = {}
for f in files:
    name = os.path.basename(f).replace("__lftk.parquet", "").replace("qwen4b_", "")
    frames[name] = pd.read_parquet(f).select_dtypes("number").mean()

M = pd.DataFrame(frames)
M["abs_gap"] = M.max(axis=1) - M.min(axis=1)
mx = M.drop(columns=["abs_gap"]).max(axis=1)
mn = M.drop(columns=["abs_gap"]).min(axis=1)
M["rel_gap"] = (mx - mn) / (mx.abs() + mn.abs() + 1e-9)
cols = ["abs_gap", "rel_gap"] + [c for c in M.columns if c not in ("abs_gap", "rel_gap")]
M = M[cols].sort_values("rel_gap", ascending=False)

print(f"=== lftk: {len(M)} numeric features, {len(frames)} sets ===")
print(M.head(args.topn).to_string(float_format=lambda v: f"{v:7.3f}"))

suffix = "_modelonly" if args.no_hh else "_all"
out = f"{args.dir}/topdiff_lftk{suffix}.csv"
M.to_csv(out)
print(f"\nsaved full table -> {out}")
