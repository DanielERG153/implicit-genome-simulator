# Simulation Sweep Scripts

Each script wraps `go run .` with different flag sets so you can perform the
requested sweeps without remembering every option.  Run them from the repository
root (the scripts will change into the repo automatically) and pass additional
flags as needed—they are appended to every invocation.

```
# Example: override the seed for the entire sweep
BIN="./implicit-genome-simulator-go" bash scripts/mutability_sweep.sh --seed 1234
```

The scripts drop results under `results/<topic>/{plots,data}` and keep filenames
aligned so you can pair plot images with their data tables.

* `scripts/mutability_sweep.sh` – runs `--mutability` across representative
  values from 0.01 through 0.99.
* `scripts/iteration_convergence.sh` – increments `--iterations` to show how
  many cycles it takes for the B/D graph to flatten.
* `scripts/neutral_range_sweep.sh` – varies `--neutral-range` between 0.01 and
  0.30 to remove near-neutral mutations from the B/D ratio.
* `scripts/population_size_sweep.sh` – tests different `--startorgs` / `--maxorgs`
  pairs to see how population size affects the outcome.
* `scripts/loci_sweep.sh` – grows the number of loci (10 → 500) to measure how
  much the effect gets muted as the genome becomes more complex.
* `scripts/multiplicative_fitness_runs.sh` – helper for the experimental change
  where you switch fitness accumulation from averaging to multiplication; it
  sweeps `--max-fitness` values so the new reproduction pressure stays bounded.
* `scripts/run_all_sweeps.sh` – convenience wrapper that executes every script
  above sequentially so you can kick off the entire suite with a single command.
