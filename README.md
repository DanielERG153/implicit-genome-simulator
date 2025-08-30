# Implicit Genome Simulator

This is a population dynamics simulator based on the book *The Implicit Genome* by Caporale.  
The idea is that genetic mutations are not as random as previously thought, but instead genomes have an implicit range within which they normally mutate.  
This project explores population dynamics built on that concept.

The code is designed to be modular: you can swap in custom loggers, PRNGs, and other components without touching the simulator core.

---

## Layout

```

cmd/
evosim/     # main CLI (entrypoint)
sweep/      # (planned) parameter sweep harness
simulator/    # engine
datalogging/  # logging hooks
tools/        # analysis scripts (plotting, summaries)
scripts/      # helper scripts (batch\_sim, run\_all, etc.)
data/         # generated CSVs/PNGs + archived runs

````

---

## Building & Running

### Quick run

```bash
go run ./cmd/evosim --help
go run ./cmd/evosim -datafile data/csv/static.csv -quiet
````

### Build a binary

```bash
mkdir -p bin
go build -o bin/evosim ./cmd/evosim
./bin/evosim -datafile data/csv/static.csv -quiet
```

---

## Batch Modes

### Standard scenario suite (nomut, allmut, static, etc.)

```bash
make build
make runs        # write CSVs under data/csv/
make plots       # generate plots into data/png/
make summaries   # generate *_summary.csv into data/
```

### Parallel batch of N runs (`batch_sim`)

For throughput runs, you can launch N simulations in parallel using all cores:

```bash
# 30 runs, concurrency = #cores, loci=1000, 1000 iterations, 5 environments
make batch_sim N=30 JOBS=$(nproc) ARGS='--loci 1000 --iterations 1000 --envs 5 --quiet'
```

Examples:

```bash
# Light run: 10 sims at 4-wide concurrency
make batch_sim N=10 JOBS=4 ARGS='--loci 100 --iterations 200 --quiet'

# Heavy run: 50 sims at all cores, 5000 iterations
make batch_sim N=50 JOBS=$(nproc) ARGS='--loci 1000 --iterations 5000 --startorgs 1000 --envs 5 --quiet'
```

Results:

* Working CSVs: `data/csv/`
* Plots: `data/png/`
* Archived snapshot: `data/runs/<timestamp>_batch_sim/` (includes CSVs, PNGs, summaries, logs)

---

## Reproducibility

* If `-seed` is omitted, the PRNG is seeded from current time (`UnixNano`) and logged.
* For deterministic runs, set a fixed seed:

```bash
./bin/evosim -seed 12345 -datafile data/csv/run.csv
```

When reporting results, always include:

* commit hash
* PRNG seed
* CLI flags (these are embedded in the CSV header as `# ARGS ...`)

---

## Plotting & Summaries

Generate plots and summary tables for all current CSVs:

```bash
python3 tools/plot_runs.py
```

Outputs:

* PNG plots in `data/png/`
* `data/summary.csv`
* `data/env_edges.csv`

Ruby summaries are still supported for per-file stats:

```bash
ruby tools/summary.rb data/csv/static.csv data/static_summary.csv
```

---

## Customizing

You can embed the simulator in your own program. Example minimal `main()`:

```go
package main

import (
	"github.com/johnnyb/implicit-genome-simulator-go/simulator"
	"math/rand"
	"time"
)

func main() {
	sim := simulator.NewSimulator(10, 100, simulator.DEFAULT_MUTABILITY)
	simulator.DataContext = sim
	simulator.DataLog = simulator.DataLogBeneficialMutations

	rand.Seed(time.Now().UnixNano())
	sim.Initialize()
	sim.PerformIterations(1000)
	sim.Finish()
}
```