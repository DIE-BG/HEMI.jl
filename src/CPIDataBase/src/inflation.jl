# inflation.jl - Basic inflation function structure, annual change on cpi

abstract type InflationFunction <: Function end

# La mayoría de funciones de inflación devuelven una medida
num_measures(::InflationFunction) = 1

# Funciones de inflación deben definir campo `name`
measure_name(inflfn::InflationFunction) = getfield(inflfn, :name)

## Tipos para resultados, utilizados para el despacho de métodos
abstract type CPIResult end
struct CPIIndex <: CPIResult end
struct CPIVarInterm <: CPIResult end

## Esquema general de cómputo (programación genérica con tipos abstractos): 
# - La función sobre CountryStructure devuelve la inflación interanual sobre todas las bases que componen 
# - Esta llama a la función de inflación que recibe `CPIIndex`. 
# - Y esta a su vez, llama a la función de inflación que recibe `CPIVarInterm`. 
# De tal manera que la mayoría de funciones solamente requieren definir su operación
# sobre los contenedores `VarCPIBase` y devolver una variación intermensual resumen 

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




## TotalCPI - Variación interanual del IPC

Base.@kwdef struct TotalCPI <: InflationFunction
    name::String = "Variación interanual IPC"
end

# Las funciones sobre VarCPIBase deben resumir en variaciones intermensuales

# Función para bases cuyo índice base es un escalar
function (inflfn::TotalCPI)(base::VarCPIBase{T, T}) where {T <: AbstractFloat} 
    base_ipc = capitalize(base.v, base.baseindex)
    ipc = base_ipc * base.w / base.baseindex
    varinterm!(ipc, ipc, 100)
    ipc
end

# Esta medida sí se comporta diferente de acuerdo a los índices base, por lo que 
# se define una versión que toma en cuenta los diferentes índices. Si la medida
# solamente genera resumen de las variaciones intermensuales, no es necesario.
# Función para bases cuyos índices base son un vector
function (inflfn::TotalCPI)(base::VarCPIBase{T, B}) where {T <: AbstractFloat, B <: AbstractVector{T}} 
    base_ipc = capitalize(base.v, base.baseindex)
    # Obtener índice base y normalizar a 100
    baseindex = base.baseindex' * base.w
    ipc = 100 * (base_ipc * base.w / baseindex)
    varinterm!(ipc, ipc, 100)
    ipc
end

