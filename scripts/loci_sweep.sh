#!/usr/bin/env bash
set -euo pipefail

# Evaluate how different locus counts dampen or amplify the signal.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

BIN=${BIN:-"go run ."}
RESULTS_ROOT=${RESULTS_ROOT:-results}
RUN_DIR="${RESULTS_ROOT}/loci"
PLOT_DIR="${RUN_DIR}/plots"
DATA_DIR="${RUN_DIR}/data"
mkdir -p "${PLOT_DIR}" "${DATA_DIR}"

LOCI_VALUES=(
  10
  25
  50
  100
  200
  500
)

for loci in "${LOCI_VALUES[@]}"; do
  echo "Running loci ${loci}..."
  ${BIN} \
    --loci "${loci}" \
    --plotfile "${PLOT_DIR}/loci-${loci}.png" \
    --datafile "${DATA_DIR}/loci-${loci}.tsv" \
    "$@"
done
