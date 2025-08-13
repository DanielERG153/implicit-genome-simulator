package main

import (
	"fmt"
	"os"
	"time"

	"github.com/johnnyb/implicit-genome-simulator-go/datalogging"

	"github.com/johnnyb/implicit-genome-simulator-go/simulator"
)

func main() {
	var err error
	config := NewConfig()
	ParseFlags(config)

	// Seed the PRNG
	if config.Seed == 0 {
		config.Seed = time.Now().UnixNano()
	}
	simulator.Seed(config.Seed)
	simulator.MAX_FITNESS = float32(config.MaxFitness)

	// Create simulator (10 loci, 100 organisms)
	// sim := simulator.NewSimulator(10, 100, simulator.DEFAULT_MUTABILITY)
    sim := simulator.NewSimulator(config.Loci, config.StartingOrganisms, float32(config.Mutability))
    // Apply continuous step size to all continuous loci
    for _, il := range sim.ImplicitGenome.ImplicitLoci {
        if il.LocusType == simulator.LOCUS_CONTINUOUS {
            il.ContinuousChangeMax = float32(config.ContinuousStep)
        }
    }
	sim.NeutralRange = float32(config.NeutralRange)

	if config.DataFile == "" {
		sim.DataStream = os.Stdout
	} else {
		sim.DataStream, err = os.OpenFile(config.DataFile, os.O_CREATE|os.O_TRUNC|os.O_WRONLY, 0644)
		if err != nil {
			panic(err)
		}
	}
	sim.MaxOrganisms = config.MaxOrganisms
	sim.DataLogger = datalogging.DataLogBeneficialMutations

	sim.Log(fmt.Sprintf("Started with seed: %d", config.Seed))

	if config.Quiet {
		sim.Logger = func(sim *simulator.Simulator, message string) {}
	}

	sim.Log("**** IGENOME ****")
	sim.Log(sim.ImplicitGenome.String())

    sim.Initialize()
    // Emit a header line noting key CLI flags for reproducibility
	sim.DataLogOutput(fmt.Sprintf(
		"Generation,Environment,# Organisms Mutated,B/D Ratio,Fitness,Δfit+ mean,Δfit- mean,Δfit net mean,# ARGS seed=%d loci=%d startorgs=%d maxorgs=%d mutability=%g neutral-range=%g max-fitness=%g quiet=%v\n",
		config.Seed, config.Loci, config.StartingOrganisms, config.MaxOrganisms,
		config.Mutability, config.NeutralRange, config.MaxFitness, config.Quiet,
	))

	// Generate environments at the beginning, so that even
	// with different options you will get the same environments
	// if run with the same seed.
	environs := [](*simulator.Environment){}
	for i := 0; i < config.Environments; i++ {
		environs = append(environs, simulator.NewEnvironment(sim.ImplicitGenome))
	}

	for _, environ := range environs {
		sim.SetEnvironment(environ)

		// Report environment
		sim.Log("**** ENVIRONMENT ****")
		sim.Log(sim.Environment.String())

		// Run the simulation for X iterations
		sim.PerformIterations(config.Iterations)
	}
	sim.Finish()
}
