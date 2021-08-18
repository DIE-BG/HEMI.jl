using DrWatson
@quickactivate "HEMI"

## Cargar el módulo de Distributed para computación paralela
using Distributed
# Agregar procesos trabajadores
addprocs(4, exeflags="--project")

# Cargar los paquetes utilizados en todos los procesos
@everywhere using HEMI


include("grid_batch.jl")
include("plot_grid.jl")
include("grid_optim.jl")

grid_batch(gtdata,InflationTrimmedMeanEq, ResampleScrambleVarMonths(), TrendRandomWalk(),10_000, 45:75, 70:100,InflationTotalRebaseCPI(60),Date(2019,12);esc="Esc-C")
grid_batch(gtdata,InflationTrimmedMeanWeighted, ResampleScrambleVarMonths(), TrendRandomWalk(),10_000, 5:35, 70:100,InflationTotalRebaseCPI(60),Date(2019,12);esc="Esc-C")

grid_batch(gtdata,InflationTrimmedMeanEq, ResampleScrambleVarMonths(), TrendRandomWalk(),10_000, 45:75, 70:100,InflationTotalRebaseCPI(60),Date(2020,12);esc="Esc-C")
grid_batch(gtdata,InflationTrimmedMeanWeighted, ResampleScrambleVarMonths(), TrendRandomWalk(),10_000, 5:35, 70:100,InflationTotalRebaseCPI(60),Date(2020,12);esc="Esc-C")