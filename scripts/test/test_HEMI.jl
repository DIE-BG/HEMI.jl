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

@testset "Pruebas instanciar funciones de inflación" begin 

totalfn = InflationTotalCPI()
println(totalfn)
@test totalfn(gtdata) isa Vector{<:AbstractFloat}

pkfn = InflationEnsemble(
    InflationPercentileEq(72), 
    InflationPercentileEq(74)
)
println(pkfn)

@test pkfn isa EnsembleFunction


end 