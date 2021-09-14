## Versión in-place intermedia para evaluación: 
#  capitaliza las matrices de variaciones in-place para ahorrar memoria

# export InflationTotalEvalCPI

Base.@kwdef struct InflationTotalEvalCPI <: InflationFunction
    name::String = "Variación interanual IPC"
end

# Función para bases cuyo índice base es un escalar
function (inflfn::InflationTotalEvalCPI)(base::VarCPIBase{T, T}) where {T <: AbstractFloat} 
    base_ipc = convert(IndexCPIBase, base)
    ipc = base_ipc.ipc * base.w / base.baseindex
    varinterm!(ipc, ipc, 100)
    ipc
end

# # Variación interanual 
# function (inflfn::InflationTotalEvalCPI)(cs::CountryStructure) 
#     vm = mapfoldl(inflfn, vcat, cs.base)
#     capitalize!(vm, vm, 100)
#     varinteran!(vm)
#     vm[12:end]
# end


## Versión in-place extrema para evaluación: 
#  capitaliza las matrices de variaciones in-place para ahorrar memoria y 
#  guarda en vector los resultados

# Base.@kwdef struct TotalExtremeCPI <: InflationFunction
#     name::String = "Variación interanual IPC"
# end

# # # Función para bases cuyo índice base es un escalar
# # function (inflfn::TotalExtremeCPI)(base::VarCPIBase{T, T}) where {T <: AbstractFloat} 
# #     base_ipc = convert(IndexCPIBase, base)
# #     ipc = base_ipc.ipc * base.w / base.baseindex
# #     varinterm!(ipc, ipc, 100)
# #     ipc
# # end

# import LinearAlgebra: mul!

# # Variación interanual 
# function (inflfn::TotalExtremeCPI)(tray_infl::AbstractVector, cs::CountryStructure) 
#     B = length(cs.base) # número de bases

#     # Para cada base, obtener IPC y variación intermensual
#     ib = 0
#     for b in 1:B
#         l = ib + size(cs[b].v, 1) # número de períodos
#         interm = @view tray_infl[ib+1:l] # vector para guardar inflación intermensual
        
#         base_ipc = convert(IndexCPIBase, cs.base[b])
#         mul!(interm, base_ipc.ipc, base_ipc.w)
#         varinterm!(interm, interm, 100*base_ipc.baseindex)
#         ib = l
#     end
    
#     # Capitalizar y obtener var interanual
#     capitalize!(tray_infl, tray_infl, 100)
#     varinteran!(tray_infl)
#     nothing
# end