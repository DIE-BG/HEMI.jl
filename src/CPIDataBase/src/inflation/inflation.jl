# inflation.jl - Estructura básica para cómputo de estimadores de inflación interanual

"""
    abstract type InflationFunction <: Function

Tipo abstracto para representar las funciones de inflación que operan sobre
[`CountryStructure`](@ref) y [`VarCPIBase`](@ref). Permiten computar la medida
de ritmo inflacionario interanual, el índice de precios dado por la metodología
y las variaciones intermensuales del índice de precios.
"""
abstract type InflationFunction <: Function end

# La mayoría de funciones de inflación devuelven una medida
"""
    num_measures(::InflationFunction)

Devuelve la cantidad de medidas devueltas por la función de inflación. Las
funciones de [`EnsembleFunction`](@ref) pueden computar varias medidas de
inflación simultáneamente.
"""
num_measures(::InflationFunction) = 1

# Funciones de inflación deben extender el método measure_name para devolver su nombre
"""
    measure_name(inflfn::InflationFunction)

Este método permite obtener el nombre convencional de una medida de inflación. 
"""
measure_name(inflfn::InflationFunction) = 
    error("Se debe extender el método `measure_name` para la función de inflación " * string(nameof(inflfn)))
    
# Funciones de inflación pueden extender opcionalmente un método measure_tag
# para indicar en archivos de resultados. Si no, se tomará por defecto el nombre
# del tipo de la función de inflación
"""
    measure_tag(inflfn::InflationFunction)

Obtiene una etiqueta de la medida de inflación. Se puede utilizar para guardar
como parámetro en archivos de resultados de evaluación.
"""
measure_tag(inflfn::InflationFunction) = string(nameof(inflfn))


## Tipos para resultados, utilizados para el despacho de métodos
"Tipo abstracto para manejar el despacho de las funciones de inflación"
abstract type CPIResult end
"Tipo concreto único para obtener el índice de una función de inflación"
struct CPIIndex <: CPIResult end
"""
Tipo concreto único para obtener la variación intermensual de una función de inflación
"""
struct CPIVarInterm <: CPIResult end

## Esquema general de cómputo (programación genérica con tipos abstractos): 
# - La función sobre CountryStructure devuelve la inflación interanual sobre
#   todas las bases que componen 
# - Esta llama a la función de inflación que recibe `CPIIndex`. 
# - Y esta a su vez, llama a la función de inflación que recibe `CPIVarInterm`. 
# - Finalmente, se llama al método que opera sobre objetos `VarCPIBase` para
#   obtener la variación intermensual resumen. De tal manera que la mayoría de
#   funciones solamente requieren definir su operación sobre los contenedores
#   `VarCPIBase` y devolver una variación intermensual resumen.

function (inflfn::InflationFunction)(cs::CountryStructure)
    vm = inflfn(cs, CPIIndex())
    varinteran(vm)
end

function (inflfn::InflationFunction)(cs::CountryStructure, ::CPIIndex)
    vm = inflfn(cs, CPIVarInterm())
    capitalize!(vm, 100)
    vm
end

function (inflfn::InflationFunction)(cs::CountryStructure, ::CPIVarInterm) 
    # Acá se llama a inflfn(base), en donde base es de tipo VarCPIBase. Esta
    # es la función que debe definirse para cualquier medida de inflación.
    vm = mapfoldl(inflfn, vcat, cs.base)
    vm
end

# Funciones de inflación deben extender el método que opera sobre VarCPIBase
# para computar la variación intermensual resumen 
function (inflfn::InflationFunction)(::VarCPIBase)
    error("Se debe extender un método para computar la variación intermensual resumen de la medida de inflación " * string(nameof(inflfn)))
end
    




# InflationTotalCPI - Implementación para obtener la medida estándar de ritmo
# inflacionario a través de la variación interanual del IPC

struct InflationTotalCPI <: InflationFunction
end

# Extender el método para obtener el nombre de esta medida
measure_name(::InflationTotalCPI) = "Variación interanual IPC"

# Las funciones sobre VarCPIBase deben resumir en variaciones intermensuales

# Método para objetos VarCPIBase cuyo índice base es un escalar
function (inflfn::InflationTotalCPI)(base::VarCPIBase{T, T}) where {T <: AbstractFloat} 
    base_ipc = capitalize(base.v, base.baseindex)
    ipc = base_ipc * base.w / base.baseindex
    varinterm!(ipc, ipc, 100)
    ipc
end

# Esta medida sí se comporta diferente de acuerdo a los índices base, por lo que 
# se define una versión que toma en cuenta los diferentes índices. Si la medida
# solamente genera resumen de las variaciones intermensuales, no es necesario.
# Método para objetos VarCPIBase cuyos índices base son un vector
function (inflfn::InflationTotalCPI)(base::VarCPIBase{T, B}) where {T <: AbstractFloat, B <: AbstractVector{T}} 
    base_ipc = capitalize(base.v, base.baseindex)
    # Obtener índice base y normalizar a 100
    baseindex = base.baseindex' * base.w
    ipc = 100 * (base_ipc * base.w / baseindex)
    varinterm!(ipc, ipc, 100)
    ipc
end

