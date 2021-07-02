# Tipo abstracto para manejar las funciones de tendencia
abstract type TrendFunction <: Function end

# Tipo para funcion "analítica": para especificar una función anónima de tendencia
abstract type AnalyticalTrendFunction <: TrendFunction end

# Tipo para función de tendencia almacenada en vector (para caminata aleatoria)
abstract type ArrayTrendFunction <: TrendFunction end


## Implementación para la función de aplicación de tendencia con vector 

# Función de ayuda para obtener vector de rangos para hacer slicing de los
# vectores de tendencia.
function _get_ranges(cs::CountryStructure) 
    periods = map( base -> size(base.v, 1), cs.base)
    ranges = Vector{UnitRange}(undef, length(periods))
    start = 0
    for i in eachindex(periods)
        ranges[i] = start + 1 : start + periods[i]
        start = periods[i]
    end
    NTuple{length(cs.base), UnitRange{Int64}}(ranges)
end


# Cómo aplicar la función de tendencia sobre un CountryStructure
function (trendfn::ArrayTrendFunction)(cs::CountryStructure)
    trend = trendfn.trend
    ranges = _get_ranges(cs)
    # trends = map(r -> getindex(trend, r), ranges)
    newbases = map(trendfn, cs.base, ranges)
    typeof(cs)(newbases)
end

# Cómo aplicar la función de tendencia sobre un VarCPIBase
function (trendfn::ArrayTrendFunction)(base::VarCPIBase, range)
    # Obtener el vector de tendencia 
    trend = @view trendfn.trend[range]
    # Aplicar la tendencia sobre la matriz de variaciones intermensuales
    vtrend =  @. base.v .* ((base.v > 0) * trend + !(base.v > 0))
    # Crear un nuevo VarCPIBase con las nuevas variaciones intermensuales
    VarCPIBase(vtrend, base.w, base.fechas, base.baseindex)
end


## Tendencia de caminata aleatoria 

Base.@kwdef struct TrendRandomWalk <: ArrayTrendFunction
    trend::Vector{Float32} = RWTREND
end

