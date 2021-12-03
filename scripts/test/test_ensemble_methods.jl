using DrWatson
@quickactivate "HEMI"

## TODO 
# Cómputo de funciones de inflación en conjunto ✔

using Dates, CPIDataBase, InflationFunctions
using JLD2

@load datadir("guatemala", "gtdata32.jld2") gt00 gt10
const gtdata = UniformCountryStructure(gt00, gt10)

## Computar inflación de Guatemala

totalfn = InflationTotalCPI()
perk50 = InflationPercentileEq(0.5)

newdata = deepcopy(gtdata)

## Construct EnsembleFunction object
ensemblefn = EnsembleFunction(totalfn, perk50)
ensemblefn(newdata)

# Construct ensemble functions that contains another ensemble function 
ensemblefn2 = EnsembleFunction(totalfn, ensemblefn, perk50)
ensemblefn2(newdata)


# Construct a CombinationFunction object
combfn = CombinationFunction(ensemblefn, Float32[0.4, 0.6])
combfn(newdata)

# Construct a CombinationFunction object without EnsembleFunction
combfn2 = CombinationFunction(totalfn, perk50, totalfn, Float32[0.1, 0.4, 0.5])
combfn2(newdata)

# Error
combfn3 = CombinationFunction(totalfn, InflationTotalCPI(), Float32[0.1, 0.4, 0.5])


## Using StaticArrays for + performance?

using StaticArrays

# combfn4 = CombinationFunction(totalfn, InflationTotalCPI(), SVector{2, Float32}([0.4, 0.5]))
combfn4 = CombinationFunction(totalfn, InflationTotalCPI(), totalfn, @SVector Float32[0.1, 0.4, 0.5])
combfn(newdata)

using BenchmarkTools

@btime combfn2($newdata);
# 311.900 μs (53 allocations: 725.39 KiB)

@btime combfn4($newdata);
# 311.700 μs (54 allocations: 725.42 KiB)