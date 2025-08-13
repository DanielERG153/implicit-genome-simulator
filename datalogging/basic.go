package datalogging

import (
	"fmt"
	"math"
	"github.com/johnnyb/implicit-genome-simulator-go/simulator"
)

var currentTime int = 1
var beneficialCount int = 0
var deleteriousCount int = 0
var posDeltaSum float32 = 0
var negDeltaSum float32 = 0

var currentEnvironment *simulator.Environment

// DataLogBeneficialMutations is a logging function which gives the beneficial/deleterious ratio.
func DataLogBeneficialMutations(sim *simulator.Simulator, metric simulator.Metric, value interface{}) {
	switch metric {
	case simulator.ENVIRONMENT_START:
		currentEnvironment = value.(*simulator.Environment)
	case simulator.ENVIRONMENT_COMPLETE:
		// no-op
	case simulator.SIMULATION_START:
		// no-op since first row is handled immediately after main.go sim.Initialize() so that it can display all ARGs
	case simulator.ORGANISM_FITNESS_DIFFERENCE:
		df := value.(float32)
		if df > 0 { posDeltaSum += df } else if df < 0 { negDeltaSum += df }
	case simulator.ORGANISM_MUTATIONS_BENEFICIAL:
		if value.(bool) {
			beneficialCount += 1
		} else {
			deleteriousCount += 1
		}
	case simulator.ITERATION_COMPLETE:
		// Average fitness (NaN if pop == 0, which is informative in your runs)
		var ftotal float32
		for _, o := range sim.Organisms {
			ftotal += o.FitnessForEnvironment(sim.Environment)
		}
		var favg float32
		if len(sim.Organisms) > 0 {
			favg = ftotal / float32(len(sim.Organisms))
		} else {
			favg = float32(math.NaN())
		}

		// B/D ratio (guard divide-by-zero)
		var bd float32
		if deleteriousCount == 0 {
			if beneficialCount == 0 {
				bd = 0 // or NaN if you prefer
			} else {
				bd = 1e9 // sentinel for +Inf
			}
		} else {
			bd = float32(beneficialCount) / float32(deleteriousCount)
		}

		// Effect-size means
		var posMean, negMean, netMean float32
		if beneficialCount > 0 { posMean = posDeltaSum / float32(beneficialCount) } else { posMean = float32(math.NaN()) }
		if deleteriousCount > 0 { negMean = negDeltaSum / float32(deleteriousCount) } else { negMean = float32(math.NaN()) }
		total := beneficialCount + deleteriousCount
		if total > 0 { netMean = (posDeltaSum + negDeltaSum) / float32(total) } else { netMean = float32(math.NaN()) }

		// SINGLE format string, arguments in order
		sim.DataLogOutput(fmt.Sprintf(
			"%d,%d,%d,%f,%f,%f,%f,%f\n",
			currentTime,
			currentEnvironment.EnvironmentId,
			beneficialCount+deleteriousCount,
			bd,
			favg,
			posMean,
			negMean,
			netMean,
		))

		currentTime++
		beneficialCount = 0
		deleteriousCount = 0
		posDeltaSum = 0
		negDeltaSum = 0

	}
}

// DataLogVerbose is a logging function that prints everything.  Mostly useful for debugging.
func DataLogVerbose(sim *simulator.Simulator, metric simulator.Metric, value interface{}) {
	switch value.(type) {
	case float32:
		sim.Log(fmt.Sprintf("METRIC: %d / %d / %f", sim.Time, metric, value))
	default:
		sim.Log(fmt.Sprintf("METRIC: %d / %d / %+v", sim.Time, metric, value))
	}
}
