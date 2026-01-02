#!/usr/bin/env bash
set -euo pipefail

# Run the simulator across a range of mutability values and keep plots/data together.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

BIN=${BIN:-"go run ."}
RESULTS_ROOT=${RESULTS_ROOT:-results}
RUN_DIR="${RESULTS_ROOT}/mutability"
PLOT_DIR="${RUN_DIR}/plots"
DATA_DIR="${RUN_DIR}/data"
mkdir -p "${PLOT_DIR}" "${DATA_DIR}"

MUTABILITIES=(
  0.01
  0.05
  0.10
  0.20
  0.40
  0.60
  0.80
  0.99
)

for value in "${MUTABILITIES[@]}"; do
  label="${value/./p}"
  echo "Running mutability ${value}..."
  ${BIN} \
    --mutability "${value}" \
    --plotfile "${PLOT_DIR}/mutability-${label}.png" \
    --datafile "${DATA_DIR}/mutability-${label}.tsv" \
    "$@"
done
