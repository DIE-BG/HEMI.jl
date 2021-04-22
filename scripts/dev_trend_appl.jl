# dev_trend_appl.jl - Trend application development
using DrWatson
@quickactivate "HEMI"

## Desarrollo de aplicación de tendencia

using CPIDataBase
using JLD2

@load datadir("guatemala", "gtdata32.jld2") gt00 gt10
gtdata = UniformCountryStructure(gt00, gt10)

using InflationEvalTools
using BenchmarkTools
using Test

## Test apply trend with VarCPIBase

# In-place
cgt00 = deepcopy(gt00)
trend00 = RWTREND[1:120]
apply_trend!(cgt00, trend00)
@test any(cgt00.v .== gt00.v)

gt00.v[1:10, 1:10]
cgt00.v[1:10, 1:10]

@btime apply_trend!($cgt00, $trend00)
# 363.800 μs (0 allocations: 0 bytes)

# With copy of trended vmat
cgt00 = deepcopy(gt00)
trend00 = RWTREND[1:120]
trended_gt00 = apply_trend(cgt00, trend00)

@test any(cgt00.v .== gt00.v)
gt00.v[1:10, 1:10]
trended_gt00.v[1:10, 1:10]

@btime apply_trend($cgt00, $trend00)
# 82.500 μs (2 allocations: 102.27 KiB)


## Now test with CountryStructure

# In place: 
# Datos hasta dic-20
gt10_sliced = VarCPIBase(gt10.v[1:120, :], gt10.w, gt10.fechas[1:120], gt10.baseindex)
newgtdata = UniformCountryStructure(deepcopy(gt00), gt10_sliced)

apply_trend!(newgtdata, RWTREND)

gtdata[1].v[1:10, 1:10]
newgtdata[1].v[1:10, 1:10]

gtdata[2].v[1:10, 1:10]
newgtdata[2].v[1:10, 1:10]

@test any(gtdata[1].v .== newgtdata[1].v)
@test any(gtdata[2].v[1:120, :] .== newgtdata[2].v)

@btime apply_trend!($newgtdata, $RWTREND)
# 817.600 μs (9 allocations: 1.48 KiB)

# With copies of trended vmats and CountryStructure
gt10_sliced = VarCPIBase(gt10.v[1:120, :], gt10.w, gt10.fechas[1:120], gt10.baseindex)
newgtdata = UniformCountryStructure(deepcopy(gt00), gt10_sliced)

trended_cs = apply_trend(newgtdata, RWTREND)

gtdata[1].v[1:10, 1:10]
trended_cs[1].v[1:10, 1:10]

gtdata[2].v[1:10, 1:10]
trended_cs[2].v[1:10, 1:10]

@test any(gtdata[1].v .== trended_cs[1].v)
@test any(gtdata[2].v[1:120, :] .== trended_cs[2].v)

@btime apply_trend($newgtdata, $RWTREND)
# 187.300 μs (9 allocations: 234.44 KiB)
