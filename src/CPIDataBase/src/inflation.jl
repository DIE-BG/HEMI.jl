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



## Versión in-place intermedia para evaluación: 
#  capitaliza las matrices de variaciones in-place para ahorrar memoria

Base.@kwdef struct TotalEvalCPI <: InflationFunction
    name::String = "Variación interanual IPC"
end

# Función para bases cuyo índice base es un escalar
function (inflfn::TotalEvalCPI)(base::VarCPIBase{T, T}) where {T <: AbstractFloat} 
    base_ipc = convert(IndexCPIBase, base)
    ipc = base_ipc.ipc * base.w / base.baseindex
    varinterm!(ipc, ipc, 100)
    ipc
end

# Variación interanual 
function (inflfn::TotalEvalCPI)(cs::CountryStructure) 
    vm = mapfoldl(inflfn, vcat, cs.base)
    capitalize!(vm, vm, 100)
    varinteran!(vm)
    vm[12:end]
end


## Versión in-place extrema para evaluación: 
#  capitaliza las matrices de variaciones in-place para ahorrar memoria y 
#  guarda en vector los resultados

Base.@kwdef struct TotalExtremeCPI <: InflationFunction
    name::String = "Variación interanual IPC"
end

# # Función para bases cuyo índice base es un escalar
# function (inflfn::TotalExtremeCPI)(base::VarCPIBase{T, T}) where {T <: AbstractFloat} 
#     base_ipc = convert(IndexCPIBase, base)
#     ipc = base_ipc.ipc * base.w / base.baseindex
#     varinterm!(ipc, ipc, 100)
#     ipc
# end

import LinearAlgebra: mul!

# Variación interanual 
function (inflfn::TotalExtremeCPI)(tray_infl::AbstractVector, cs::CountryStructure) 
    B = length(cs.base) # número de bases

    # Para cada base, obtener IPC y variación intermensual
    ib = 0
    for b in 1:B
        l = ib + size(cs[b].v, 1) # número de períodos
        interm = @view tray_infl[ib+1:l] # vector para guardar inflación intermensual
        
        base_ipc = convert(IndexCPIBase, cs.base[b])
        mul!(interm, base_ipc.ipc, base_ipc.w)
        varinterm!(interm, interm, 100*base_ipc.baseindex)
        ib = l
    end
    
    # Capitalizar y obtener var interanual
    capitalize!(tray_infl, tray_infl, 100)
    varinteran!(tray_infl)
    nothing
end