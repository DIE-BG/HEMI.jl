# EvalPeriod.jl - Tipo para representar períodos de evaluación en el ejercicio
# de simulación 

# Tipo abstracto para representar tipos de períodos de evaluación 
abstract type AbstractEvalPeriod end 

# Tipo para representar un período de evaluación dado por las fechas startdate y
# finaldate. Se debe incluir una etiqueta en el campo tag para adjuntar a los
# resultados 
struct EvalPeriod <: AbstractEvalPeriod
    startdate::Date 
    finaldate::Date 
    tag::String 
end

# Tipo para representar el período completo de evaluación, correspondiente a los
# períodos de inflación del CountryStructure de datos. El tag por defecto para
# el período completo es vacío, para que las métricas de evaluación no tengan un
# prefijo, ya que es el período de evaluación principal 
struct CompletePeriod <: AbstractEvalPeriod
end

# Función para devolver la máscara de períodos a evaluar, respecto de los
# períodos de inflación de un CountryStructure
function eval_periods(cs::CountryStructure, period::EvalPeriod)
    dates = infl_dates(cs)
    period.startdate .<= dates .<= period.finaldate
end

function eval_periods(cs::CountryStructure, ::CompletePeriod)
    1:infl_periods(cs)
end

# Función para obtener etiqueta asociada al período de evaluación. El período de evaluación completo tiene una etiqueta vacía (`""`)
period_tag(period::EvalPeriod) = period.tag
period_tag(::CompletePeriod) = "" 

# Extender Base.string para imprimir período 
Base.show(io::IO, ::CompletePeriod) = print(io, "Período completo")
Base.show(io::IO, p::EvalPeriod) = print(io, p.tag * ":" * Dates.format(p.startdate, DEFAULT_DATE_FORMAT) * "-" * Dates.format(p.finaldate, DEFAULT_DATE_FORMAT))

# Definición de períodos por defecto para evaluación de datos de Guatemala 
const GT_EVAL_B00 = EvalPeriod(Date(2001, 12), Date(2010, 12), "gt_b00")
const GT_EVAL_B10 = EvalPeriod(Date(2011, 12), Date(2020, 12), "gt_b10")
const GT_EVAL_T0010 = EvalPeriod(Date(2011, 1), Date(2011, 11), "gt_t0010")
