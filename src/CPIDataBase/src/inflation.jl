# inflation.jl - Basic inflation function structure, annual change on cpi

abstract type InflationFunction <: Function end
	
Base.@kwdef struct TotalCPI <: InflationFunction
    name::String = "Variación interanual IPC"
end

## Las funciones sobre VarCPIBase resumen en variaciones intermensuales

# Función para bases cuyo índice base es un escalar
function (inflfn::TotalCPI)(base::VarCPIBase{T, T}) where {T <: AbstractFloat} 
    base_ipc = capitalize(base.v, base.baseindex)
    ipc = base_ipc * base.w / base.baseindex
    varinterm!(ipc, ipc, 100)
    ipc
end

# Función para bases cuyos índices base son un vector
function (inflfn::TotalCPI)(base::VarCPIBase{T, B}) where {T <: AbstractFloat, B <: AbstractVector{T}} 
    base_ipc = capitalize(base.v, base.baseindex)
    # Obtener índice base y normalizar a 100
    baseindex = base.baseindex' * base.w
    ipc = 100 * (base_ipc * base.w / baseindex)
    varinterm!(ipc, ipc, 100)
    ipc
end

## La función sobre CountryStructure devuelve la inflación interanual sobre todas las bases que componen 

function (inflfn::TotalCPI)(cs::CountryStructure) 
    vm = mapfoldl(inflfn, vcat, cs.base)
    capitalize!(vm, vm, 100)
    varinteran(vm)
end