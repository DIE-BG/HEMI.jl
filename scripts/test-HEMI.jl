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

totalfn = InflationTotalCPI()
plot(infl_dates(gtdata), totalfn(gtdata)) 

using InflationFunctions

pkfn = EnsembleFunction(InflationPercentileEq(72), InflationPercentileEq(74))
plot(infl_dates(gtdata), pkfn(gtdata), 
    label=["PK72" "PK74"], 
    title="Inflación interanual basada en percentiles 72 y 74 ") 