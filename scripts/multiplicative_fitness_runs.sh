#!/usr/bin/env bash
set -euo pipefail

# Helper to rerun scenarios after changing the fitness calculation to multiplicative.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

BIN=${BIN:-"go run ."}
RESULTS_ROOT=${RESULTS_ROOT:-results}
RUN_DIR="${RESULTS_ROOT}/multiplicative-fitness"
PLOT_DIR="${RUN_DIR}/plots"
DATA_DIR="${RUN_DIR}/data"
mkdir -p "${PLOT_DIR}" "${DATA_DIR}"

MAX_FITNESS_VALUES=(
  1.50
  1.25
  1.10
)

for value in "${MAX_FITNESS_VALUES[@]}"; do
  label="${value/./p}"
  echo "Running max-fitness ${value} (multiplicative fitness mode)..."
  ${BIN} \
    --max-fitness "${value}" \
    --plotfile "${PLOT_DIR}/maxfitness-${label}.png" \
    --datafile "${DATA_DIR}/maxfitness-${label}.tsv" \
    "$@"
done
