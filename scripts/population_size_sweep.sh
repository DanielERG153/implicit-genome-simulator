#!/usr/bin/env bash
set -euo pipefail

# Compare small vs. large starting/max population sizes.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

BIN=${BIN:-"go run ."}
RESULTS_ROOT=${RESULTS_ROOT:-results}
RUN_DIR="${RESULTS_ROOT}/population"
PLOT_DIR="${RUN_DIR}/plots"
DATA_DIR="${RUN_DIR}/data"
mkdir -p "${PLOT_DIR}" "${DATA_DIR}"

POPULATION_SETTINGS=(
  "25:50"
  "50:100"
  "100:200"
  "200:500"
  "500:1000"
  "1000:2000"
)

for setting in "${POPULATION_SETTINGS[@]}"; do
  start="${setting%%:*}"
  max="${setting##*:}"
  label="start${start}-max${max}"
  echo "Running startorgs=${start}, maxorgs=${max}..."
  ${BIN} \
    --startorgs "${start}" \
    --maxorgs "${max}" \
    --plotfile "${PLOT_DIR}/population-${label}.png" \
    --datafile "${DATA_DIR}/population-${label}.tsv" \
    "$@"
done
