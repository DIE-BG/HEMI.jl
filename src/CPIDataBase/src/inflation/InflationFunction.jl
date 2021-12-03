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


# Método para obtener parámetros 
"""
    params(inflfn::InflationFunction)
Método para obtener parámetros de la función de inflación. Devuelve una tupla
con el conjunto de parámetros utilizado por la función de inflación `inflfn`.
Este método debe redefinirse en las nuevas medidas de inflación si estas están
parametrizadas.
"""
params(inflfn::InflationFunction) = getproperty.(Ref(inflfn), propertynames(inflfn))


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
    cpi_index = inflfn(cs, CPIIndex())
    varinteran(cpi_index)
end

function (inflfn::InflationFunction)(cs::CountryStructure, ::CPIIndex)
    v_interm = inflfn(cs, CPIVarInterm())
    capitalize!(v_interm, 100) # v_interm -> cpi_index
    v_interm  
end

function (inflfn::InflationFunction)(cs::CountryStructure, ::CPIVarInterm) 
    # Acá se llama a inflfn(base), en donde base es de tipo VarCPIBase. Esta
    # es la función que debe definirse para cualquier medida de inflación.
    v_interm = mapfoldl(inflfn, vcat, cs.base)
    v_interm
end

# Funciones de inflación deben extender el método que opera sobre VarCPIBase
# para computar la variación intermensual resumen 
function (inflfn::InflationFunction)(::VarCPIBase)
    error("Se debe extender un método para computar la variación intermensual resumen de la medida de inflación " * string(nameof(inflfn)))
end
    
