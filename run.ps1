# Not tested yet!

param([switch]$Runs, [switch]$Plots, [switch]$Test, [switch]$Race)

if ($Test) { go test ./simulator -v -count=1 }
if ($Race) { go test -race ./simulator -count=1 }

if ($Runs) {
  New-Item -ItemType Directory -Force -Path data/csv | Out-Null
  go run . -envs 1 -iterations 500 -mutability 0 -quiet -datafile data/csv/nomut.csv
  go run . -envs 1 -iterations 500 -mutability 1.0 -quiet -datafile data/csv/allmut.csv
  go run . -envs 1 -iterations 500 -quiet -datafile data/csv/static.csv
  go run . -envs 5 -iterations 100 -quiet -datafile data/csv/multi.csv
  go run . -envs 1 -iterations 500 -max-fitness 1000 -quiet -datafile data/csv/highfit.csv
  go run . -envs 1 -iterations 500 -neutral-range 0.01 -quiet -datafile data/csv/neutral.csv
  go run . -loci 1   -startorgs 50 -iterations 300 -quiet -datafile data/csv/loci1.csv
  go run . -loci 100 -startorgs 50 -iterations 300 -quiet -datafile data/csv/loci100.csv
}

if ($Plots) {
  New-Item -ItemType Directory -Force -Path data/png | Out-Null
  python3 tools/plot_runs.py
}

# Example powershell usecase: 
# .\run.ps1 -Test
# .\run.ps1 -Runs
# .\run.ps1 -Plots