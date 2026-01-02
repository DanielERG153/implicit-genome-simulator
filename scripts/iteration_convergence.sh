#!/usr/bin/env bash
set -euo pipefail

# Explore how many iterations it takes for the B/D graph to flatten.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

BIN=${BIN:-"go run ."}
RESULTS_ROOT=${RESULTS_ROOT:-results}
RUN_DIR="${RESULTS_ROOT}/iterations"
PLOT_DIR="${RUN_DIR}/plots"
DATA_DIR="${RUN_DIR}/data"
mkdir -p "${PLOT_DIR}" "${DATA_DIR}"

ITERATION_COUNTS=(
  250
  500
  1000
  2000
  4000
  8000
)

for count in "${ITERATION_COUNTS[@]}"; do
  echo "Running ${count} iterations..."
  ${BIN} \
    --iterations "${count}" \
    --plotfile "${PLOT_DIR}/iterations-${count}.png" \
    --datafile "${DATA_DIR}/iterations-${count}.tsv" \
    "$@"
done
