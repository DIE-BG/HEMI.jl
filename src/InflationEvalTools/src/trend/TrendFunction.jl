"""
    abstract type TrendFunction <: Function end
Tipo abstracto para manejar las funciones de tendencia.

## Utilización
    (trendfn::TrendFunction)(cs::CountryStructure)
Aplica la función de tendencia sobre un `CountryStructure` y devuelve un nuevo
`CountryStructure`.
"""
abstract type TrendFunction <: Function end


""" 
    abstract type ArrayTrendFunction <: TrendFunction end
Tipo para función de tendencia que almacena el vector de valores a aplicar a
las variaciones intermensuales.

## Utilización 
    (trendfn::ArrayTrendFunction)(base::VarCPIBase{T}, range::UnitRange) where T
Especifica cómo aplicar la función de tendencia sobre un VarCPIBase con el rango de
índices `range`.
"""
abstract type ArrayTrendFunction <: TrendFunction end


## Implementación del comportamiento general de función de aplicación de tendencia  

"""
    get_ranges(cs::CountryStructure)
Función de ayuda para obtener tupla de rangos de índices para hacer slicing de los
vectores de tendencia.
"""
function get_ranges(cs::CountryStructure) 
    # Obtiene los períodos de cada base
    periods = map( base -> size(base.v, 1), cs.base)
    # Genera un vector de rangos y llena cada rango con los índices que se
    # forman con los elementos de periods
    ranges = Vector{UnitRange}(undef, length(periods))
    start = 0
    for i in eachindex(periods)
        ranges[i] = start + 1 : start + periods[i]
        start = periods[i]
    end
    # Devuelve una tupla de rangos de índices 
    NTuple{length(cs.base), UnitRange{Int64}}(ranges)
end

# Aplicación general de TrendFunction sobre CountryStructure
function (trendfn::TrendFunction)(cs::CountryStructure)
    # Obtener rango de índices para las bases del CountryStructure
    ranges = get_ranges(cs)
    # Aplicar en cada base la función de tendencia. Se requiere definir para
    # cualquier TrendFunction cómo operar sobre la tupla (::VarCPIBase,
    # ::UnitRange)
    newbases = map(trendfn, cs.base, ranges)
    # Construir un nuevo CountryStructure con las bases modificadas
    typeof(cs)(newbases)
end


## Implementación de aplicación de tendencia para ArrayTrendFunction

# Aplicación de ArrayTrendFunction, que almacena el vector de tendencia a ser
# aplicado sobre un VarCPIBase
function (trendfn::ArrayTrendFunction)(base::VarCPIBase{T}, range::UnitRange) where T
    # Obtener el vector de tendencia del campo trend
    trend::Vector{T} = @view trendfn.trend[range]
    # Aplicar la tendencia condicional sobre la matriz de variaciones
    # intermensuales
    vtrend =  @. base.v * ((base.v > 0) * trend + !(base.v > 0))
    # Crear un nuevo VarCPIBase con las nuevas variaciones intermensuales
    VarCPIBase(vtrend, base.w, base.fechas, base.baseindex)
end 


## Definición del tipo para tendencia de caminata aleatoria 

"""
    TrendRandomWalk{T} <: ArrayTrendFunction

Tipo para representar una función de tendencia de caminata aleatoria. Utiliza el
vector de caminata aleatoria precalibrado en [`RWTREND`](@ref).

# Ejemplo: 
```julia-repl 
# Crear la función de tendencia de caminata aleatoria
trendfn = TrendRandomWalk()
```
"""
Base.@kwdef struct TrendRandomWalk{T} <: ArrayTrendFunction
    trend::Vector{T} = RWTREND
end

## Definición del tipo para tendencia con función anónima

"""
    TrendAnalytical{T} <: ArrayTrendFunction

Tipo para representar una función de tendencia definida por una función anónima.
Recibe los datos de un `CountryStructure` o un rango de índices para precomputar
el vector de tendencia utlizando una función anónima.

# Ejemplos: 

Para crear una función de tendencia a partir de una función anónima: 
```julia-repl 
trendfn = TrendAnalytical(param_data, t -> 1 + sin(2π*t/12))
```
o bien: 
```julia-repl 
trendfn = TrendAnalytical(1:periods(param_data), t -> 1 + sin(2π*t/12))
```
"""
struct TrendAnalytical{T} <: ArrayTrendFunction
    trend::Vector{T}

    # Método constructor para obtener la cantidad de períodos a computar de un
    # CountryStructure
    function TrendAnalytical(cs::CountryStructure, fnhandle::Function)
        # Obtener el número de períodos de las bases del CountryStructure
        p = periods(cs)
        # Se crea un vector con la función mapeada en los períodos
        trend::Vector{eltype(cs)} = fnhandle.(1:p)
        # Se retorna con el mismo tipo que el CountryStructure utilizado.
        new{eltype(cs)}(trend)
    end
    # Método constructor a partir de rango de períodos
    function TrendAnalytical(range::UnitRange, fnhandle::Function)
        # Mapea una función en los elementos de un UnitRange 
        trend::Vector{Float32} = fnhandle.(range)
        # Lo retorna en con el tipo Float32
        new{Float32}(trend)
    end

end

## Definición del tipo para función de tendencia neutra

"""
    TrendIdentity <: TrendFunction

Tipo concreto para representar una función de tendencia neutra. Es decir, esta
función de tendencia mantiene los datos sin alteración. 

## Ejemplos: 
```julia-repl 
# Crear una función de tendencia neutra. 
trendfn = TrendIdentity()
```

## Utilización 
    (trendfn::TrendIdentity)(cs::CountryStructure)

    Aplicación de tendencia TrendIdentity sobre VarCPIBase. Se redefine este método
para dejar invariante la base VarCPIBase. 
```julia-repl 
trendfn = TrendIdentity() 
trended_cs = trendfn(gtdata) 
```
"""
struct TrendIdentity <: TrendFunction end

# Se redefine para devolver el mismo CountryStructure sin alteración
function (trendfn::TrendIdentity)(cs::CountryStructure)
    # Simplemente devuelve el CountryStructure
    cs
end 