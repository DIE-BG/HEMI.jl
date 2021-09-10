# SimConfig.jl - Definición de tipos contenedores para parámetros de simulación

"""
    abstract type AbstractConfig{F <: InflationFunction, R <:ResampleFunction, T <:TrendFunction} end

`AbstractConfig` es un tipo abstracto para representar variantes de simulación que utilizan, en
general, una función de inflación [`InflationFunction`](@ref), una función de
remuestreo [`ResampleFunction`](@ref) y una función de Tendencia
[`TrendFunction`](@ref). Contiene el esquema general de la simulación.
"""
abstract type AbstractConfig{F <: InflationFunction, R <:ResampleFunction, T <:TrendFunction} end

"""
    SimConfig{F, R, T} <:AbstractConfig{F, R, T}

Tipo concreto que contiene una configuración base para generar simulaciones
utilizando todos los datos como set de entrenamiento. Recibe una función de
inflación [`InflationFunction`](@ref), una función de remuestreo
[`ResampleFunction`](@ref), una función de Tendencia [`TrendFunction`](@ref), 
una función de inflación de evaluación [`paramfn`] y la cantidad de simulaciones 
deseadas [`nsim`].

## Ejemplo
Considerando las siguientes instancias de funciones de inflación, remuestreo,
tendencia e inflación de evaluación:

```jldoctest genfunctions
julia> percEq = InflationPercentileEq(80);

julia> resamplefn = ResampleSBB(36);

julia> trendfn = TrendRandomWalk();

julia> paramfn = InflationWeightedMean();
```

Generamos una configuración del tipo `SimConfig` con 1000 simulaciones, con períodos de evaluación por defecto:
- `CompletePeriod()`, 
- `GT_EVAL_B00`, 
- `GT_EVAL_T0010` y  
- `GT_EVAL_B10`

```jldoctest genfunctions
julia> config = SimConfig(percEq, resamplefn, trendfn, paramfn, 1000, Date(2019,12))
SimConfig{InflationPercentileEq, ResampleSBB, TrendRandomWalk{Float32}}
|─> Función de inflación            : Percentil equiponderado 80.0
|─> Función de remuestreo           : Block bootstrap estacionario con bloque esperado 36
|─> Función de tendencia            : Tendencia de caminata aleatoria
|─> Método de inflación paramétrica : Media ponderada interanual
|─> Número de simulaciones          : 1000
|─> Fin set de entrenamiento        : Dec-19
|─> Períodos de evaluación          : Período completo, gt_b00:Dec-01-Dec-10, gt_t0010:Jan-11-Nov-11 y gt_b10:Dec-11-Dec-20
```

Para generar una configuración con períodos específicos podemos brindar la colección de períodos de interés:

```jldoctest genfunctions
julia> config2 = SimConfig(percEq, resamplefn, trendfn, paramfn, 1000, Date(2019,12),
       (CompletePeriod(), EvalPeriod(Date(2008,1), Date(2009,12), "fincrisis")))
SimConfig{InflationPercentileEq, ResampleSBB, TrendRandomWalk{Float32}}
|─> Función de inflación            : Percentil equiponderado 80.0
|─> Función de remuestreo           : Block bootstrap estacionario con bloque esperado 36
|─> Función de tendencia            : Tendencia de caminata aleatoria
|─> Método de inflación paramétrica : Media ponderada interanual
|─> Número de simulaciones          : 1000
|─> Fin set de entrenamiento        : Dec-19
|─> Períodos de evaluación          : Período completo y fincrisis:Jan-08-Dec-09
```
"""
Base.@kwdef struct SimConfig{F, R, T} <:AbstractConfig{F, R, T}
    # Función de Inflación
    inflfn::F
    # Función de remuestreo
    resamplefn::R
    # Función de Tendencia
    trendfn::T
    # Función de inflación paramétrica 
    paramfn::InflationFunction
    # Cantidad de Simulaciones
    nsim::Int  
    # Fecha final de evaluación 
    traindate::Date
    # Colección de período(s) de evaluación, por defecto el período completo 
    evalperiods = (CompletePeriod(),)
end

# Constructor con períodos de evaluación por defecto para Guatemala 
SimConfig(inflfn, resamplefn, trendfn, paramfn, nsim, traindate) = 
    SimConfig(inflfn, resamplefn, trendfn, paramfn, nsim, traindate, 
    # Configuración de períodos por defecto 
    (CompletePeriod(), GT_EVAL_B00, GT_EVAL_T0010, GT_EVAL_B10))
    



"""
    CrossEvalConfig{F, R, T} <:AbstractConfig{F, R, T}
    CrossEvalConfig(ensemblefn, resamplefn, trendfn, paramfn, nsim, evalperiods)

`CrossEvalConfig` es un tipo concreto que contiene la configuración base para
generar simulaciones utilizando un conjunto de funciones de inflación a
combinarse. 

Recibe una
- función de inflación de conjunto [`EnsembleFunction`](@ref), 
- una función de remuestreo [`ResampleFunction`](@ref), 
- una función de Tendencia [`TrendFunction`](@ref), 
- la cantidad de simulaciones a realizar `nsim`, 
- un período (o conjunto de períodos) de evaluación [`EvalPeriod`](@ref) para en
  los cuales se obtendrán métricas de evaluación de validación cruzada. El
  período de entrenamiento se considera desde el inicio de la muestra hasta el
  período anterior a cada período de evaluación dado.

## Ejemplo

Considerando un conjunto de funciones de inflación, remuestreo, tendencia e
inflación paramétrica: 

```jldoctest crosseval_ex
julia> ensemblefn = EnsembleFunction(InflationPercentileEq(72), InflationPercentileWeighted(68));

julia> resamplefn = ResampleSBB(36); 

julia> trendfn = TrendRandomWalk(); 

julia> paramfn = InflationTotalRebaseCPI(60); 
```

Generamos una configuración del tipo `CrossEvalConfig` con 10000 simulaciones,
configurando dos períodos de evaluación para los métodos de validación cruzada. 

```jldoctest crosseval_ex
julia> config = CrossEvalConfig(ensemblefn, resamplefn, trendfn, paramfn, 10000, 
       (EvalPeriod(Date(2016, 1), Date(2017, 12), "cv1617"), 
       EvalPeriod(Date(2017, 1), Date(2018, 12), "cv1718")))
CrossEvalConfig{InflationTotalRebaseCPI, ResampleSBB, TrendRandomWalk{Float32}}
|─> Función de inflación            : ["Percentil equiponderado 72.0", "Percentil ponderado 68.0"]
|─> Función de remuestreo           : Block bootstrap estacionario con bloque esperado 36
|─> Función de tendencia            : Tendencia de caminata aleatoria
|─> Método de inflación paramétrica : Variación interanual IPC con cambios de base sintéticos (60, 0)
|─> Número de simulaciones          : 10000
|─> Períodos de evaluación          : cv1617:Jan-16-Dec-17 y cv1718:Jan-17-Dec-18
```
"""
Base.@kwdef struct CrossEvalConfig{F, R, T} <:AbstractConfig{F, R, T}
    # Conjunto de funciones de inflación para obtener trayectorias a combinar 
    inflfn::EnsembleFunction
    # Función de remuestreo
    resamplefn::R
    # Función de Tendencia
    trendfn::T
    # Función de inflación paramétrica 
    paramfn::F
    # Cantidad de simulaciones a realizar 
    nsim::Int
    # Colección de período(s) de evaluación, por defecto el período completo 
    evalperiods::Union{EvalPeriod, Vector{EvalPeriod}, NTuple{N, EvalPeriod} where N}
end

# Configuraciones para mostrar nombres de funciones en savename
Base.string(inflfn::InflationFunction) = measure_tag(inflfn)
Base.string(resamplefn::ResampleFunction) = method_tag(resamplefn)
Base.string(trendfn::TrendFunction) = method_tag(trendfn)

# Método para mostrar información de la configuración en el REPL
function Base.show(io::IO, config::AbstractConfig)
    println(io, typeof(config))
    println(io, "|─> Función de inflación            : ", measure_name(config.inflfn))
    println(io, "|─> Función de remuestreo           : ", method_name(config.resamplefn))
    println(io, "|─> Función de tendencia            : ", method_name(config.trendfn))
    println(io, "|─> Método de inflación paramétrica : ", measure_name(config.paramfn))
    println(io, "|─> Número de simulaciones          : ", config.nsim)
    if hasproperty(config, :traindate)
        println(io, "|─> Fin set de entrenamiento        : ", Dates.format(config.traindate, DEFAULT_DATE_FORMAT))
    end
    println(io, "|─> Períodos de evaluación          : ", join(config.evalperiods, ", ", " y "))
end


# Extensión de tipos permitidos para simulación en DrWatson
DrWatson.default_allowed(::AbstractConfig) = (String, Symbol, TimeType, Function, Real) 

# Definición de formato para guardado de archivos relacionados con la configuración
DEFAULT_CONNECTOR = ", "
DEFAULT_EQUALS = "="
DEFAULT_DATE_FORMAT = DateFormat("u-yy")
COMPACT_DATE_FORMAT = DateFormat("uyy")

# Extensión de savename para SimConfig
DrWatson.savename(config::SimConfig, suffix::String = "jld2"; kwargs...) = 
    savename(DrWatson.default_prefix(config), config, suffix; kwargs...)

function DrWatson.savename(prefix::String, config::SimConfig, suffix::String; kwargs...)
    _prefix = prefix == "" ? "" : prefix * "_"
    _suffix = suffix != "" ? "." * suffix : ""

    _prefix * join([ 
        measure_tag(config.inflfn), # Función de inflación 
        method_tag(config.resamplefn), # Función de remuestreo 
        method_tag(config.trendfn), # Función de tendencia
        measure_tag(config.paramfn), # Función de inflación paramétrica de evaluación
        config.nsim >= 1000 ? string(config.nsim ÷ 1000) * "k" : string(config.nsim), # Número de simulaciones, 
        Dates.format(config.traindate, COMPACT_DATE_FORMAT)
    ], DEFAULT_CONNECTOR) * _suffix 
end

# Extensión de savename para CrossEvalConfig
DrWatson.savename(config::CrossEvalConfig, suffix::String = "jld2"; kwargs...) = 
    savename(DrWatson.default_prefix(config), config, suffix; kwargs...)

function DrWatson.savename(prefix::String, config::CrossEvalConfig, suffix::String = "jld2"; kwargs...)
    _prefix = prefix == "" ? "" : prefix * "_"
    _suffix = suffix != "" ? "." * suffix : ""
    num_infl_functions = length(config.inflfn.functions)
    num_eval_periods = length(config.evalperiods)
    startdate = minimum(map(p -> p.startdate, config.evalperiods))
    finaldate = maximum(map(p -> p.finaldate, config.evalperiods))

    _prefix * join([
        # Función de inflación de conjunto denotada por CrossEvalConfig
        "CrossEvalConfig($num_infl_functions, $num_eval_periods)", 
        method_tag(config.resamplefn), # Función de remuestreo 
        method_tag(config.trendfn), # Función de tendencia
        measure_tag(config.paramfn), # Función de inflación paramétrica de evaluación
        config.nsim >= 1000 ? string(config.nsim ÷ 1000) * "k" : string(config.nsim), # Número de simulaciones, 
        Dates.format(startdate, COMPACT_DATE_FORMAT) * "-" * Dates.format(finaldate, COMPACT_DATE_FORMAT)
    ], DEFAULT_CONNECTOR) * _suffix
end


# Funciones de ayuda 


## Método para convertir de AbstractConfig a Diccionario 
# Esto lo hace la función struct2dict() de DrWatson

"""
    dict_config(params::Dict)

Función para convertir diccionario de parámetros a `SimConfig` o `CrossEvalConfig`.
"""
function dict_config(params::Dict)
    # CrossEvalConfig contiene el campo de períodos de evaluación 
    if (:traindate in keys(params))
        config = SimConfig(params[:inflfn], params[:resamplefn], params[:trendfn], params[:paramfn], params[:nsim], params[:traindate])
    else
        config = CrossEvalConfig(params[:inflfn], params[:resamplefn], params[:trendfn], params[:paramfn], params[:nsim], params[:evalperiods])
    end
    config 
end

# Método opcional para lista de configuraciones
dict_config(params::AbstractVector) = dict_config.(params)

