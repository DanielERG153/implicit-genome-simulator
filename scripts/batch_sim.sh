#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   scripts/batch_sim.sh [-j CONCURRENCY] [-n N] [-- extra evosim flags...]
# Example:
#   scripts/batch_sim.sh -j "$(nproc)" -n 30 -- --loci 1000 --iterations 1000 --envs 5 --quiet

CONC="$(nproc)"
N=30

while [[ $# -gt 0 ]]; do
  case "$1" in
    -j|--jobs) CONC="$2"; shift 2 ;;
    -n|--num)  N="$2";   shift 2 ;;
    --) shift; break ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done
EXTRA=("$@")

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="$ROOT/bin/evosim"
CSV_DIR="$ROOT/data/csv"
STAMP="$(date +%F_%H-%M-%S)"
RUN_DIR="$ROOT/data/runs/${STAMP}_batch_sim"
LOG_DIR="$RUN_DIR/logs"

mkdir -p "$(dirname "$BIN")" "$CSV_DIR" "$RUN_DIR/csv" "$RUN_DIR/png" "$LOG_DIR"

# Build once (force rebuild with BUILD=1)
if [[ ! -x "$BIN" || "${BUILD:-0}" = "1" ]]; then
  echo "Building evosim..."
  go build -o "$BIN" "$ROOT/cmd/evosim"
fi

echo "Launching $N runs with concurrency=$CONC"
export BIN CSV_DIR LOG_DIR EXTRA
seq 0 $((N-1)) | xargs -n1 -P "$CONC" -I{} bash -c '
  i={}
  seed=$(( ($(date +%s%N) ^ i) & 0x7fffffffffffffff ))
  out="$CSV_DIR/output${i}.csv"
  log="$LOG_DIR/progress${i}.out"
  "$BIN" -seed "$seed" "${EXTRA[@]}" -datafile "$out" >"$log" 2>&1 || echo "run $i failed" >> "$LOG_DIR/errors.txt"
'

# Optional: plot & snapshot this batch
python3 "$ROOT/tools/plot_runs.py" || true
cp -a "$CSV_DIR/." "$RUN_DIR/csv/" || true
cp -a "$ROOT/data/png/." "$RUN_DIR/png/" || true
[[ -f "$ROOT/data/summary.csv"   ]] && cp "$ROOT/data/summary.csv" "$RUN_DIR/"
[[ -f "$ROOT/data/env_edges.csv" ]] && cp "$ROOT/data/env_edges.csv" "$RUN_DIR/"

echo "Done. CSVs: $CSV_DIR  Logs: $LOG_DIR  Snapshot: $RUN_DIR"
