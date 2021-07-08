## Definiciones para obtener un parámetro de inflación 

"""
Tipo abstracto para representar los parámetros de inflación 
"""
abstract type AbstractInflationParameter{F <: InflationFunction, R <: ResampleFunction} end 

"""
Tipo concreto para representar un parámetro de inflación computado con la
función de inflación `inflfn` y el método de remuestreo `resamplefn`.

Ver también: [`ParamTotalCPIRebase`](@ref), [`ParamTotalCPI`](@ref), [`ParamWeightedMean`](@ref)
"""
Base.@kwdef struct InflationParameter{F, R} <: AbstractInflationParameter{F, R}
    inflfn::F = InflationTotalRebaseCPI()
    resamplefn::R = ResampleSBB(36)
end

# Método para obtener la trayectoria paramétrica a partir de un CountryStructure
function (param::AbstractInflationParameter)(cs::CountryStructure)
    # Obtener la función para obtener los datos paramétricos (promedio) del método de remuestreo
    paramfn = get_param_function(param.resamplefn)
    # Computar un CountryStructure con datos paramétricos (promedio) 
    param_data = paramfn(cs)

    # Aplicar la función de inflación para obtener la trayectoria paramétrica
    traj_infl_param = param.inflfn(param_data)

    # Devolver la trayectoria de inflación paramétrica
    traj_infl_param
end

# Redefinir un método Base.show para InflationParameter
function Base.show(io::IO, param::AbstractInflationParameter)
    println(io, typeof(param))
    println(io, "|─> InflationFunction : " * measure_name(param.inflfn) )
    println(io, "|─> ResampleFunction  : " * method_name(param.resamplefn) )
end


"""
    DEFAULT_RESAMPLE_FN

Define la funcón de remuestreo a utilizar por defecto en el ejercicio de simulación.
"""
const DEFAULT_RESAMPLE_FN = ResampleSBB(36)


"""
    ParamTotalCPIRebase()

Función de ayuda para obtener la configuración del parámetro de inflación dado por la función de inflación del IPC con cambio de base sintético y el método de remuestreo por defecto.
"""
ParamTotalCPIRebase() = 
    InflationParameter(InflationTotalRebaseCPI(60), DEFAULT_RESAMPLE_FN)

# Función para obtener el parámetro con otra función de remuestreo 
ParamTotalCPIRebase(resamplefn::ResampleFunction) = 
    InflationParameter(InflationTotalRebaseCPI(60), resamplefn)


"""
    ParamTotalCPI()

Función de ayuda para obtener la configuración del parámetro de inflación dado por la función de inflación del IPC y el método de remuestreo por defecto.
"""
ParamTotalCPI() = InflationParameter(InflationTotalCPI(), DEFAULT_RESAMPLE_FN)

# Función para obtener el parámetro con otra función de remuestreo 
ParamTotalCPI(resamplefn::ResampleFunction) = 
    InflationParameter(InflationTotalCPI(), resamplefn)


"""
    ParamWeightedMean()

Función de ayuda para obtener la configuración del parámetro de inflación dado por la media ponderada interanual y el método de remuestreo por defecto.
"""
ParamWeightedMean() = error("Este parámetro no está implementado aún")