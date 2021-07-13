using DrWatson
@quickactivate HEMI 

using InflationEvalTools
using InflationEvalTools: ResampleFunction

## Crear el tipo y extender definiciones 

# Tipo para representar los parámetros necesarios para generar la simulación
# Base.@kwdef struct SimConfig{F <: InflationFunction, R <: ResampleFunction}
#     inflfn::F
#     resamplefn::R
#     trendfn = "rw"
#     nsim::Int
# end

# # Configuraciones necesarias para mostrar nombres de funciones en savename
# Base.string(inflfn::InflationFunction) = measure_tag(inflfn)
# Base.string(inflfn::ResampleFunction) = method_name(inflfn)

# # Extender definición de tipos permitidos para simulación
# DrWatson.default_allowed(::SimConfig) = (Real, String, Symbol, TimeType, Function)
# DrWatson.default_prefix(::SimConfig) = "HEMI"

# Implementar un método Base.show(io::IO, config::SimConfig) más amigable ...

## Obtener un ejemplo 

totalfn = InflationTotalCPI()
resamplefn = ResampleSBB(36)
trendfn = TrendRandomWalk()
ff = Date(2020, 12)

# Crear una configuración de prueba
config = SimConfig(totalfn, resamplefn, trendfn, 10_000,ff)

# Mostrar el nombre generado por la configuración 
savename(config)