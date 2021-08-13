using DrWatson
@quickactivate "HEMI"

## Cargar el módulo de Distributed para computación paralela
using Distributed
# Agregar procesos trabajadores
addprocs(4, exeflags="--project")

# Cargar los paquetes utilizados en todos los procesos
@everywhere using HEMI

inflfn1    = InflationTrimmedMeanEq(57.5, 84)
inflfn2    = InflationTrimmedMeanWeighted(15,97) 
resamplefn = ResampleScrambleVarMonths()
trendfn    = TrendRandomWalk()
paramfn    = InflationTotalRebaseCPI(36, 2)
nsim       = 125_000
ff         = Date(2019, 12)

config1  = SimConfig(inflfn1, resamplefn, trendfn, paramfn, nsim, ff)
config2 = SimConfig(inflfn2, resamplefn, trendfn, paramfn, nsim, ff)

results1, _ = makesim(gtdata, config1)
results2, _ = makesim(gtdata, config2)

filename1   = savename(config1, "jld2")
filename2   = savename(config2, "jld2")

dir1 = datadir("results", string(typeof(inflfn1)),"Esc-A")
dir2 = datadir("results", string(typeof(inflfn2)),"Esc-A")

wsave(joinpath(dir1, filename1), tostringdict(results1))
wsave(joinpath(dir2, filename2), tostringdict(results2))