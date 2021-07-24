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
[`ResampleFunction`](@ref), una función de Tendencia [`TrendFunction`](@ref), y
la cantidad de simulaciones deseadas [`nsim`].

## Ejemplo
Considerando las siguientes instancias de funciones de inflación, remuestreo y
tendencia:

```julia
percEq = InflationPercentileEq(80)
resamplefn = ResampleSBB(36)
trendfn = TrendRandomWalk()
```

Generamos una configuración del tipo `SimConfig` con 1000 simulaciones:

```julia-repl 
julia> config = SimConfig(percEq, resamplefn, trendfn, 1000)
|─> Función de inflación : PercEq-80.0
|─> Función de remuestreo: ResampleSBB-36
|─> Función de tendencia : TrendRandomWalk
```
"""
Base.@kwdef struct SimConfig{F, R, T} <:AbstractConfig{F, R, T}
    # Función de Inflación
    inflfn::F
    # Función de remuestreo
    resamplefn::R
    # Función de Tendencia
    trendfn::T
    # Cantidad de Simulaciones
    nsim::Int  
end


"""
    CrossEvalConfig{F, R, T} <:AbstractConfig{F, R, T}

`CrossEvalConfig` es un tipo concreto que contiene una configuración base para
generar simulaciones utilizando una muestra de los datos como set de
entrenamiento y un período de n meses como período de evaluación . Recibe una
función de inflación [`InflationFunction`](@ref), una función de remuestreo
[`ResampleFunction`](@ref), una función de Tendencia [`TrendFunction`](@ref), la
cantidad de simulaciones deseadas [`nsim`], el último mes del set de
entrenamiento [`train_date`] y el tamaño del período de evaluación en meses
[`eval_size`].

## Ejemplo

Considerando las mismas funciones de inflación, remuestreo y tendencia: 

```julia 
percEq = InflationPercentileEq(80)
resamplefn = ResampleSBB(36)
trendfn = TrendRandomWalk()
```

Generamos una configuración del tipo SimConfig con 1000 simulaciones y
utilizando el fin de set de entrenamiento hasta diciembre de 2012 y 24 meses de
evaluación.

```julia-repl 
julia> config = CrossEvalConfig(percEq, resamplefn, trendfn, 1000, Date(2012, 12), 24)
|─> Función de inflación : PercEq-80.0
|─> Función de remuestreo: ResampleSBB-36
|─> Función de tendencia : TrendRandomWalk
|─> Fin set de entrenamiento: 2012-12-01
|─> Meses de evaluación     : 24
```
"""
Base.@kwdef struct CrossEvalConfig{F, R, T} <:AbstractConfig{F, R, T}
    # Función de Inflación
    inflfn::F
    # Función de remuestreo
    resamplefn::R
    # Función de Tendencia
    trendfn::T
    # Cantidad de simulaciones
    nsim::Int
    # Último mes de set de "entrenamiento"
    train_date::Date   
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
    println(io, "|─> ", "Función de inflación : ", measure_tag(config.inflfn))
    println(io, "|─> ", "Función de remuestreo: ", method_tag(config.resamplefn))
    println(io, "|─> ", "Función de tendencia : ", method_tag(config.trendfn))
    println(io, "|─> ", "Simulaciones         : ", config.nsim)
    if config isa CrossEvalConfig 
        println(io, "|─> ", "Fin set de entrenamiento: ", config.train_date)
        println(io, "|─> ", "Meses de evaluación     : ", config.eval_size)
    end
end


# Extensión de tipos permitidos para simulación en DrWatson
DrWatson.default_allowed(::AbstractConfig) = (String, Symbol, TimeType, Function, Real) 
DrWatson.default_prefix(::AbstractConfig) = "HEMI"

## método para convertir de AbstractConfig a Diccionario 
# Esto lo hace la función struct2dict() de DrWatson

# function convert_dict(config::AbstractConfig)
   
#     if typeof(config) == SimConfig{typeof(config.inflfn),typeof(config.resamplefn), typeof(config.trendfn)}
#         # Convertir SimConfig a Diccionari
#         dict = Dict(:inflfn => config.inflfn, :resamplefn => config.resamplefn, :trendfn => config.trendfn, :nsim => config.nsim)     
    
#     elseif typeof(config) == CrossEvalConfig{typeof(config.inflfn),typeof(config.resamplefn), typeof(config.trendfn)} 
#         # Convertir CrossEvalConfig a Diccionario
#         dict = Dict(:inflfn => config.inflfn, :resamplefn => config.resamplefn, :trendfn => config.trendfn, 
#                     :nsim => config.nsim, :train_date => config.train_date, :eval_size => config.eval_size)    
    
#     end
#     dict
# end

