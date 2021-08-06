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

Generamos una configuración del tipo `SimConfig` con 1000 simulaciones:

```jldoctest genfunctions
julia> config = SimConfig(percEq, resamplefn, trendfn, paramfn, 1000, Date(2019,12))
SimConfig{InflationPercentileEq, ResampleSBB, TrendRandomWalk{Float32}}
|─> Función de inflación            : Percentil equiponderado 80.0
|─> Función de remuestreo           : Block bootstrap estacionario con bloque esperado 36
|─> Función de tendencia            : Tendencia de caminata aleatoria
|─> Método de inflación paramétrica : Media ponderada interanual
|─> Número de simulaciones          : 1000
|─> Fin set de entrenamiento        : 2019-12-01
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
    paramfn
    # Cantidad de Simulaciones
    nsim::Int  
    # Fecha final de evaluación 
    traindate::Date
end


"""
    CrossEvalConfig{F, R, T} <:AbstractConfig{F, R, T}

`CrossEvalConfig` es un tipo concreto que contiene una configuración base para
generar simulaciones utilizando una muestra de los datos como set de
entrenamiento y un período de n meses como período de evaluación . Recibe una
función de inflación [`InflationFunction`](@ref), una función de remuestreo
[`ResampleFunction`](@ref), una función de Tendencia [`TrendFunction`](@ref), la
cantidad de simulaciones deseadas [`nsim`], el último mes del set de
entrenamiento [`traindate`] y el tamaño del período de evaluación en meses
[`eval_size`].

## Ejemplo

Considerando las mismas funciones de inflación, remuestreo, tendencia e
inflación de evaluación: 

```julia 
percEq = InflationPercentileEq(80)
resamplefn = ResampleSBB(36)
trendfn = TrendRandomWalk()
paramfn = InflationTotalRebaseCPI(60)
```

Generamos una configuración del tipo CrossEvalConfig con 1000 simulaciones y
utilizando el fin de set de entrenamiento hasta diciembre de 2012 y 24 meses de
evaluación.

```julia-repl 
julia> config = CrossEvalConfig(percEq, resamplefn, trendfn, paramfn, 1000, Date(2012, 12), 24)
|─> Función de inflación     : PercEq-80.0
|─> Función de remuestreo    : ResampleSBB-36
|─> Función de tendencia     : TrendRandomWalk
|─> Inflación paramétrica    : InflationTotalRebaseCPI
|─> Simulaciones             : 1000
|─> Fin set de entrenamiento : 2012-12-01
|─> Meses de evaluación      : 24
```
"""
Base.@kwdef struct CrossEvalConfig{F, R, T} <:AbstractConfig{F, R, T}
    # Función de Inflación
    inflfn::F
    # Función de remuestreo
    resamplefn::R
    # Función de Tendencia
    trendfn::T
    # # Función de inflación paramétrica 
    paramfn
    # Cantidad de simulaciones
    nsim::Int
    # Último mes de set de "entrenamiento"
    traindate::Date   
    # Tamaño del período de evaluación en meses 
    eval_size::Int = 24
end

# Configuraciones para mostrar nombres de funciones en savename
Base.string(inflfn::InflationFunction) = measure_tag(inflfn)
Base.string(resamplefn::ResampleFunction) = method_tag(resamplefn)
Base.string(trendfn::TrendFunction) = method_tag(trendfn)

# Método para mostrar información de la configuración en el REPL
function Base.show(io::IO, config::AbstractConfig)
    println(io, typeof(config))
    println(io, "|─> ", "Función de inflación            : ", measure_name(config.inflfn))
    println(io, "|─> ", "Función de remuestreo           : ", method_name(config.resamplefn))
    println(io, "|─> ", "Función de tendencia            : ", method_name(config.trendfn))
    println(io, "|─> ", "Método de inflación paramétrica : ", measure_name(config.paramfn))
    println(io, "|─> ", "Número de simulaciones          : ", config.nsim)
    println(io, "|─> ", "Fin set de entrenamiento        : ", config.traindate)
    if config isa CrossEvalConfig 
        println(io, "|─> ", "Meses de evaluación             : ", config.eval_size)
    end
end


# Extensión de tipos permitidos para simulación en DrWatson
DrWatson.default_allowed(::AbstractConfig) = (String, Symbol, TimeType, Function, Real) 
DrWatson.default_prefix(::SimConfig) = "HEMI-SimConfig"
DrWatson.default_prefix(::CrossEvalConfig) = "HEMI-CrossEvalConfig"

# Definición de formato para guardado de archivos relacionados con la configuración
DEFAULT_CONNECTOR = ", "
DEFAULT_EQUALS = "="

DrWatson.savename(conf::SimConfig, suffix::String = "jld2") = 
    savename(conf, suffix; connector=DEFAULT_CONNECTOR, equals=DEFAULT_EQUALS)

DrWatson.savename(conf::CrossEvalConfig, suffix::String = "jld2") = 
    savename(conf, suffix; connector=DEFAULT_CONNECTOR, equals=DEFAULT_EQUALS)


## Método para convertir de AbstractConfig a Diccionario 
# Esto lo hace la función struct2dict() de DrWatson
