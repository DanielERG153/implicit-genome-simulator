#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CSV_DIR="$ROOT/data/csv"
PNG_DIR="$ROOT/data/png"
RUNS_DIR="$ROOT/data/runs"
STAMP="$(date +%F_%H-%M-%S)"
RUN_TAG="${1:-static}"   # optional arg becomes the tag (default: static)

mkdir -p "$CSV_DIR" "$PNG_DIR" "$RUNS_DIR"

# Build if missing
if [[ ! -x "$ROOT/bin/evosim" ]]; then
  echo "Building evosim..."
  go build -o "$ROOT/bin/evosim" "$ROOT/cmd/evosim"
fi

# Example runs (tweak to your taste)
"$ROOT/bin/evosim" -datafile "$CSV_DIR/nomut.csv"     -mutability 0        -quiet || true
"$ROOT/bin/evosim" -datafile "$CSV_DIR/allmut.csv"    -mutability 1        -quiet || true
"$ROOT/bin/evosim" -datafile "$CSV_DIR/loci1.csv"     -loci 1              -quiet || true
"$ROOT/bin/evosim" -datafile "$CSV_DIR/loci100.csv"   -loci 100            -quiet || true
"$ROOT/bin/evosim" -datafile "$CSV_DIR/neutral.csv"   -neutral-range 0.02  -quiet || true
"$ROOT/bin/evosim" -datafile "$CSV_DIR/highfit.csv"   -max-fitness 10      -quiet || true
"$ROOT/bin/evosim" -datafile "$CSV_DIR/static.csv"    -quiet || true

# Plot & summarize
python3 "$ROOT/tools/plot_runs.py"

# Snapshot this batch into a dated folder under data/runs/
DEST="$RUNS_DIR/${STAMP}_${RUN_TAG}"
mkdir -p "$DEST"
mkdir -p "$DEST/csv" "$DEST/png"

# Move/copy artifacts into the run folder (leave working csv/png dirs intact)
cp -a "$CSV_DIR"/. "$DEST/csv/" || true
cp -a "$PNG_DIR"/. "$DEST/png/" || true
[[ -f "$ROOT/data/summary.csv" ]] && cp "$ROOT/data/summary.csv" "$DEST/"
[[ -f "$ROOT/data/env_edges.csv" ]] && cp "$ROOT/data/env_edges.csv" "$DEST/"

echo "Run archived to: $DEST"
