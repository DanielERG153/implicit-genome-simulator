#!/usr/bin/env python3
"""
plot_runs.py — Analysis & plotting for Implicit Genome Simulator CSVs.

- Reads CSVs from ./data/csv
- Accepts trailing header token "SEED:..." or "# ARGS ..."
- Produces:
    ./data/png/<file>_{fitness|bd_ratio|mutated|delta_means}.png
    ./data/summary.csv
    ./data/env_edges.csv
- If CSVs include extra columns (Δfit+ mean / Δfit- mean / Δfit net mean), they are plotted too.
- Clips B/D (99th percentile, ignoring Inf/sentinels) for readability.
"""

import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from typing import Dict, Tuple, List

ROOT = os.path.abspath(os.path.dirname(__file__) + "/..")
CSV_DIR = os.path.join(ROOT, "data", "csv")
PNG_DIR = os.path.join(ROOT, "data", "png")
SUMMARY_CSV = os.path.join(ROOT, "data", "summary.csv")
EDGES_CSV = os.path.join(ROOT, "data", "env_edges.csv")

os.makedirs(CSV_DIR, exist_ok=True)
os.makedirs(PNG_DIR, exist_ok=True)
os.makedirs(os.path.dirname(SUMMARY_CSV), exist_ok=True)

def parse_header_meta(header_line: str) -> Dict[str, str]:
    meta = {}
    if not header_line:
        return meta
    last_token = header_line.split(",")[-1].strip()
    if last_token.startswith("SEED:"):
        meta["seed"] = last_token.split(":", 1)[-1].strip()
    elif last_token.startswith("# ARGS"):
        for kv in last_token[len("# ARGS"):].strip().split():
            if "=" in kv:
                k, v = kv.split("=", 1)
                meta[k.strip()] = v.strip()
    return meta

def load_igs_csv(path: str) -> Tuple[pd.DataFrame, Dict[str, str]]:
    with open(path, "r", encoding="utf-8", errors="ignore") as f:
        header_line = f.readline().strip()
    df = pd.read_csv(path)

    # Standardize 1st five columns by position
    std_cols = ["Generation","Environment","Mutated","B/D Ratio","Fitness"]
    col_map = {df.columns[i]: std_cols[i] for i in range(min(5, len(df.columns)))}
    df = df.rename(columns=col_map)

    # Preserve any extra columns (e.g., Δfit means)
    ordered = [c for c in std_cols if c in df.columns]
    for c in df.columns:
        if c not in ordered:
            ordered.append(c)
    df = df[ordered]

    # numeric coercion (robust to blanks / NA)
    for c in ["Generation","Environment","Mutated","B/D Ratio","Fitness",
              "Δfit+ mean","Δfit- mean","Δfit net mean"]:
        if c in df.columns:
            df[c] = pd.to_numeric(df[c], errors="coerce")

    meta = parse_header_meta(header_line)
    return df, meta

def env_edge_snapshots(df: pd.DataFrame) -> List[dict]:
    rows = []
    if df.empty or "Environment" not in df.columns or "Generation" not in df.columns:
        return rows

    df2 = df.copy()
    for c in ["Generation", "Environment"]:
        if c in df2.columns:
            df2[c] = pd.to_numeric(df2[c], errors="coerce")

    mask_keep = (~df2["Environment"].isna()) | (~df2["Generation"].isna())
    df2 = df2.loc[mask_keep]
    if df2.empty:
        return rows

    env_series = df2["Environment"].astype("Int64").ffill()
    if env_series.isna().all():
        return rows

    starts = [df2.index[0]]
    prev = env_series.iloc[0]
    for idx, cur in zip(env_series.index[1:], env_series.iloc[1:]):
        if pd.isna(cur) or pd.isna(prev):
            prev = cur
            continue
        if cur != prev:
            starts.append(idx)
        prev = cur

    ends = list(starts[1:]) + [df2.index[-1] + 1]

    for a, b in zip(starts, ends):
        block = df2.loc[a:b-1].dropna(subset=["Environment","Generation"])
        if block.empty:
            continue

        head = block.head(2)
        tail = block.tail(2)

        for tag, sub in (("begin", head), ("end", tail)):
            for _, r in sub.iterrows():
                rows.append({
                    "Environment": int(r["Environment"]),
                    "Tag": tag,
                    "Generation": int(r["Generation"]),
                    "Mutated": float(r["Mutated"]) if "Mutated" in r and pd.notna(r["Mutated"]) else None,
                    "B/D Ratio": float(r["B/D Ratio"]) if "B/D Ratio" in r and pd.notna(r["B/D Ratio"]) else None,
                    "Fitness": float(r["Fitness"]) if "Fitness" in r and pd.notna(r["Fitness"]) else None,
                })
    return rows

def clipped_bd_for_plot(series: pd.Series) -> pd.Series:
    if series is None or series.empty:
        return series
    s = series.replace(1e9, np.inf)
    finite = s.replace([np.inf, -np.inf], np.nan).dropna()
    if finite.empty:
        return series
    clip = finite.quantile(0.99)
    return s.clip(upper=clip)

def plot_file(df: pd.DataFrame, fname: str):
    base = os.path.splitext(fname)[0]
    # Fitness
    plt.figure()
    df.plot(x="Generation", y="Fitness", legend=False)
    plt.title(f"{fname}: Fitness vs Generation")
    plt.xlabel("Generation"); plt.ylabel("Fitness")
    plt.savefig(os.path.join(PNG_DIR, f"{base}_fitness.png"), dpi=150, bbox_inches="tight")
    plt.close()

    # B/D (clipped)
    if "B/D Ratio" in df.columns:
        plt.figure()
        y = clipped_bd_for_plot(df["B/D Ratio"])
        plt.plot(df["Generation"], y)
        plt.title(f"{fname}: B/D Ratio vs Generation (clipped 99%)")
        plt.xlabel("Generation"); plt.ylabel("B/D Ratio")
        plt.savefig(os.path.join(PNG_DIR, f"{base}_bd_ratio.png"), dpi=150, bbox_inches="tight")
        plt.close()

    # Mutated
    if "Mutated" in df.columns:
        plt.figure()
        df.plot(x="Generation", y="Mutated", legend=False)
        plt.title(f"{fname}: Mutated Count vs Generation")
        plt.xlabel("Generation"); plt.ylabel("# Mutated")
        plt.savefig(os.path.join(PNG_DIR, f"{base}_mutated.png"), dpi=150, bbox_inches="tight")
        plt.close()

    # Δ means if present
    have_d = any(c in df.columns for c in ["Δfit+ mean","Δfit- mean","Δfit net mean"])
    if have_d:
        plt.figure()
        for col in ["Δfit+ mean","Δfit- mean","Δfit net mean"]:
            if col in df.columns:
                plt.plot(df["Generation"], df[col], label=col)
        plt.title(f"{fname}: Mean Δfitness (per generation)")
        plt.xlabel("Generation"); plt.ylabel("Mean Δfitness")
        plt.legend()
        plt.savefig(os.path.join(PNG_DIR, f"{base}_delta_means.png"), dpi=150, bbox_inches="tight")
        plt.close()

def main():
    files = sorted([f for f in os.listdir(CSV_DIR) if f.lower().endswith(".csv")])
    summary_rows, edges_rows = [], []

    for fname in files:
        path = os.path.join(CSV_DIR, fname)
        df, meta = load_igs_csv(path)

        # Summary
        bd_stats = df["B/D Ratio"].replace(1e9, np.inf) if "B/D Ratio" in df.columns else None
        fitness_nan = int(df["Fitness"].isna().sum()) if "Fitness" in df.columns else 0
        summary_rows.append({
            "file": fname,
            "seed": meta.get("seed"),
            "envs": meta.get("envs"),
            "iterations": meta.get("iterations"),
            "mutability": meta.get("mutability"),
            "neutral-range": meta.get("neutral-range"),
            "max-fitness": meta.get("max-fitness"),
            "loci": meta.get("loci"),
            "startorgs": meta.get("startorgs"),
            "maxorgs": meta.get("maxorgs"),
            "rows": len(df),
            "fitness_mean": float(df["Fitness"].mean(skipna=True)) if "Fitness" in df.columns else None,
            "fitness_std": float(df["Fitness"].std(skipna=True)) if "Fitness" in df.columns else None,
            "fitness_min": float(df["Fitness"].min(skipna=True)) if "Fitness" in df.columns else None,
            "fitness_max": float(df["Fitness"].max(skipna=True)) if "Fitness" in df.columns else None,
            "fitness_nan_count": fitness_nan,
            "bd_mean": float(bd_stats.replace([np.inf, -np.inf], np.nan).mean(skipna=True)) if bd_stats is not None else None,
            "bd_median": float(bd_stats.replace([np.inf, -np.inf], np.nan).median(skipna=True)) if bd_stats is not None else None,
            "bd_inf_count": int(np.isinf(bd_stats).sum()) if bd_stats is not None else 0,
            "mutated_mean": float(df["Mutated"].mean(skipna=True)) if "Mutated" in df.columns else None,
            "mutated_median": float(df["Mutated"].median(skipna=True)) if "Mutated" in df.columns else None,
            "mutated_max": float(df["Mutated"].max(skipna=True)) if "Mutated" in df.columns else None,
        })

        # Edges
        edges = env_edge_snapshots(df)
        for r in edges:
            r["file"] = fname
        edges_rows.extend(edges)

        # Plots
        plot_file(df, fname)

    pd.DataFrame(summary_rows).to_csv(SUMMARY_CSV, index=False)
    if edges_rows:
        pd.DataFrame(edges_rows)[
            ["file","Environment","Tag","Generation","Mutated","B/D Ratio","Fitness"]
        ].to_csv(EDGES_CSV, index=False)
    else:
        pd.DataFrame(columns=["file","Environment","Tag","Generation","Mutated","B/D Ratio","Fitness"]).to_csv(EDGES_CSV, index=False)
    print("WROTE", SUMMARY_CSV, EDGES_CSV, PNG_DIR)

if __name__ == "__main__":
    main()
