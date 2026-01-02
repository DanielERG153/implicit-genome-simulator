#!/usr/bin/env bash
set -euo pipefail

# Check how removing near-neutral mutations changes the output.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

BIN=${BIN:-"go run ."}
RESULTS_ROOT=${RESULTS_ROOT:-results}
RUN_DIR="${RESULTS_ROOT}/neutral-range"
PLOT_DIR="${RUN_DIR}/plots"
DATA_DIR="${RUN_DIR}/data"
mkdir -p "${PLOT_DIR}" "${DATA_DIR}"

NEUTRAL_RANGES=(
  0.01
  0.05
  0.10
  0.15
  0.20
  0.25
  0.30
)

for value in "${NEUTRAL_RANGES[@]}"; do
  label="${value/./p}"
  echo "Running neutral range ${value}..."
  ${BIN} \
    --neutral-range "${value}" \
    --plotfile "${PLOT_DIR}/neutral-${label}.png" \
    --datafile "${DATA_DIR}/neutral-${label}.tsv" \
    "$@"
done
