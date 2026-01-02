#!/usr/bin/env bash
set -euo pipefail

# Runs every sweep script in sequence so you can kick off the full test suite.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

SWEEPS=(
  "mutability_sweep.sh"
  "iteration_convergence.sh"
  "neutral_range_sweep.sh"
  "population_size_sweep.sh"
  "loci_sweep.sh"
  "multiplicative_fitness_runs.sh"
)

for sweep in "${SWEEPS[@]}"; do
  echo
  echo "========== Running ${sweep} =========="
  bash "scripts/${sweep}" "$@"
done

echo
echo "All sweeps finished."
