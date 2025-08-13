# Makefile at repo root

CSV_DIR := data/csv
PNG_DIR := data/png
DATA_DIR := data

RUNS := \
	$(CSV_DIR)/nomut.csv \
	$(CSV_DIR)/allmut.csv \
	$(CSV_DIR)/static.csv \
	$(CSV_DIR)/multi.csv \
	$(CSV_DIR)/highfit.csv \
	$(CSV_DIR)/neutral.csv \
	$(CSV_DIR)/loci1.csv \
	$(CSV_DIR)/loci100.csv

.PHONY: all test race clean runs plots summaries ruby-summary

all: test runs plots summaries

test:
	go test ./simulator -v -count=1

race:
	go test -race ./simulator -count=1

clean:
	go clean -testcache
	rm -f $(CSV_DIR)/*.csv
	rm -f $(DATA_DIR)/*.csv
	rm -f $(PNG_DIR)/*.png

runs:
	mkdir -p $(CSV_DIR)
	# No mutation
	go run . -envs 1 -iterations 500 -mutability 0 -quiet -datafile $(CSV_DIR)/nomut.csv
	# All mutate
	go run . -envs 1 -iterations 500 -mutability 1.0 -quiet -datafile $(CSV_DIR)/allmut.csv
	# Static
	go run . -envs 1 -iterations 500 -quiet -datafile $(CSV_DIR)/static.csv
	# Multi environment (5 envs, 100 iters each)
	go run . -envs 5 -iterations 100 -quiet -datafile $(CSV_DIR)/multi.csv
	# High fitness scale
	go run . -envs 1 -iterations 500 -max-fitness 1000 -quiet -datafile $(CSV_DIR)/highfit.csv
	# Neutral band
	go run . -envs 1 -iterations 500 -neutral-range 0.01 -quiet -datafile $(CSV_DIR)/neutral.csv
	# Loci sensitivity
	go run . -loci 1   -startorgs 50 -iterations 300 -quiet -datafile $(CSV_DIR)/loci1.csv
	go run . -loci 100 -startorgs 50 -iterations 300 -quiet -datafile $(CSV_DIR)/loci100.csv

plots:
	mkdir -p $(PNG_DIR)
	python3 tools/plot_runs.py

# Summaries for all CSVs using Ruby script
summaries: $(RUNS)
	mkdir -p $(DATA_DIR)
	@for f in $(RUNS); do \
		base=$$(basename $$f .csv); \
		echo "Summarizing $$f -> $(DATA_DIR)/$${base}_summary.csv"; \
		ruby summary.rb $$f $(DATA_DIR)/$${base}_summary.csv || exit 1; \
	done

# Example single-summary target if you want to run just one
ruby-summary:
	ruby summary.rb $(CSV_DIR)/multi.csv $(DATA_DIR)/multi_summary.csv
