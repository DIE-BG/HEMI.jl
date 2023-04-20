# EvalPeriod.jl - Tipo para representar períodos de evaluación en el ejercicio
# de simulación 

"""
    abstract type AbstractEvalPeriod    
Tipo abstracto para representar tipos de períodos de evaluación. 

Ver también: [`EvalPeriod`](@ref), [`CompletePeriod`](@ref).
"""
abstract type AbstractEvalPeriod end 

"""
    EvalPeriod <: AbstractEvalPeriod
Tipo para representar un período de evaluación dado por las fechas `startdate` y
`finaldate`. Se debe incluir una etiqueta en el campo `tag` para adjuntar a los
resultados generados en [`evalsim`](@ref). Este período se puede brindar a una
configuración [`SimConfig`](@ref) para evaluar sobre un rango de fechas
determinado. 

## Ejemplo 

Creamos un período de evaluación denominado `b2010` al generar los resultados. 
```jldoctest
julia> b2010 = EvalPeriod(Date(2011,1), Date(2019,12), "b2010")
b2010:Jan-11-Dec-19
```

Ver también: [`GT_EVAL_B00`](@ref), [`GT_EVAL_B10`](@ref), [`GT_EVAL_T0010`](@ref)
"""
struct EvalPeriod <: AbstractEvalPeriod
    startdate::Date 
    finaldate::Date 
    tag::String 
end

"""
    CompletePeriod <: AbstractEvalPeriod
Tipo para representar el período completo de evaluación, correspondiente a los
períodos de inflación del `CountryStructure` de datos. El `tag` por defecto para
el período completo es vacío (`""`), para que las métricas de evaluación en los
resultados generados en [`evalsim`](@ref) no tienen un prefijo, ya que es el
período de evaluación principal. Este período se puede brindar a una
configuración [`SimConfig`](@ref) para evaluar sobre todo el rango de fechas
de inflación simuladas. 

## Ejemplo 

Creamos una instancia de este tipo para representar la evaluación sobre el
período completo de las trayectorias de inflación generadas en las simulaciones.
```jldoctest
julia> comp = CompletePeriod()
Período completo
```

Ver también: [`EvalPeriod`](@ref), [`GT_EVAL_B00`](@ref), [`GT_EVAL_B10`](@ref),
[`GT_EVAL_T0010`](@ref)
"""
struct CompletePeriod <: AbstractEvalPeriod
end

"""
    eval_periods(cs::CountryStructure, period::EvalPeriod) -> BitVector
    eval_periods(cs::CountryStructure, ::CompletePeriod) -> UnitRange
Devuelve una máscara o un rango de índices de los períodos comprendidos en
`EvalPeriod` o `CompletePeriod` para aplicar *slicing* a las trayectorias de
inflación y al parámetro antes de obtener las métricas de evaluación.

Ver también: [`EvalPeriod`](@ref), [`CompletePeriod`](@ref), [`period_tag`](@ref).
"""
function eval_periods end

# Función para devolver la máscara de períodos a evaluar, respecto de los
# períodos de inflación de un CountryStructure
function eval_periods(cs::CountryStructure, period::EvalPeriod)
    dates = infl_dates(cs)
    period.startdate .<= dates .<= period.finaldate
end

function eval_periods(cs::CountryStructure, ::CompletePeriod)
    1:infl_periods(cs)
end

# Etiqueta para resultados 
"""
    period_tag(period::EvalPeriod) -> String
    period_tag(::CompletePeriod) -> String
Función para obtener etiqueta asociada al período de evaluación. El período de
evaluación completo tiene una etiqueta vacía (`""`). 

Ver también: [`EvalPeriod`](@ref), [`CompletePeriod`](@ref), [`eval_periods`](@ref).
"""
period_tag(period::EvalPeriod) = period.tag
period_tag(::CompletePeriod) = "" 

# Extender Base.string para imprimir período 
Base.show(io::IO, ::CompletePeriod) = print(io, "Período completo")
Base.show(io::IO, p::EvalPeriod) = print(io, p.tag * ":" * Dates.format(p.startdate, DEFAULT_DATE_FORMAT) * "-" * Dates.format(p.finaldate, DEFAULT_DATE_FORMAT))

# Definición de períodos por defecto para evaluación de datos de Guatemala 
"""
    const GT_EVAL_B00 = EvalPeriod(Date(2001, 12), Date(2010, 12), "gt_b00")
Período por defecto para evaluación en la década de los años 2000, incluyendo el año 2010. 
"""
const GT_EVAL_B00 = EvalPeriod(Date(2001, 12), Date(2010, 12), "gt_b00")

"""
    const GT_EVAL_B10 = EvalPeriod(Date(2011, 12), Date(2021, 12), "gt_b10")
Período por defecto para evaluación en la década de los años 2010, incluyendo el año 2021.
"""
const GT_EVAL_B10 = EvalPeriod(Date(2011, 12), Date(2021, 12), "gt_b10")

"""
    const GT_EVAL_T0010 = EvalPeriod(Date(2011, 1), Date(2011, 11), "gt_t0010")
Período por defecto para evaluación en la transición de la década de los años 2000 a 2010. 
"""
const GT_EVAL_T0010 = EvalPeriod(Date(2011, 1), Date(2011, 11), "gt_t0010")



## Iteración sobre períodos

# Se definen estos métodos para funciones que involucren CrossEvalConfig con un
# período o una colección de períodos
Base.length(::EvalPeriod) = 1
Base.size(e::EvalPeriod) = (1,)
Base.iterate(e::EvalPeriod) = e, nothing
Base.iterate(::EvalPeriod, ::Nothing) = nothing