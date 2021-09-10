using DrWatson
@quickactivate :HEMI 

# Forma compacta: 
#   @quickactivate :HEMI 
# Activa el proyecto "HEMI" del directorio y ejecuta `using HEMI`

# Forma explícita: 
#   @quickactivate "HEMI"
#   using HEMI 

## Carga de datos -- los datos se cargan en @quickactivate :HEMI
# @load datadir("guatemala", "gtdata32.jld2") gt00 gt10
# gtdata = UniformCountryStructure(gt00, gt10)

using Test 

totalfn = InflationTotalCPI()
@test totalfn(gtdata) isa Vector{<:AbstractFloat}
plot(infl_dates(gtdata), totalfn(gtdata)) 

pkfn = InflationEnsemble(
    InflationPercentileEq(72), 
    InflationPercentileEq(74)
)

@test pkfn isa EnsembleFunction
plot(pkfn, gtdata)