# total_cpi_rebase.jl - Función de inflación total con cambio de base sintético. 

# El parámetro de maxchanges permite realizar hasta un máximo de cambios de base
# sintéticos en cada VarCPIBase. El valor cero indica que se utilizarán todos
# los cambios de base sintéticos posibles dentro de cada base
Base.@kwdef struct InflationTotalRebaseCPI <: InflationFunction
    period::Int = 60 # períodos para realizar el cambio de base sintético
    maxchanges::Int = 0
end

# Constructor de convenienica para número máximo de cambios de base en cada
# VarCPIBase
InflationTotalRebaseCPI(period::Int) = InflationTotalRebaseCPI(period, 0)

# Nombre de la medida
measure_name(inflfn::InflationTotalRebaseCPI) = 
    "Variación interanual IPC con cambios de base sintéticos ($(inflfn.period), $(inflfn.maxchanges))"

# Parámetros
params(totalrebasefn::InflationTotalRebaseCPI) = (totalrebasefn.period, )

# Computar variación intermensual resumen de medida de inflación aplicando
# metodología de cambio de base sintético
function (totalrebasefn::InflationTotalRebaseCPI)(base::VarCPIBase)
    
    # Número de períodos para realizar cambio de base
    period = totalrebasefn.period

    # Obtener períodos de la base
    T = periods(base)
    
    # Obtener vector de índices
    startidxs, endidxs = _getranges(T, period, totalrebasefn.maxchanges)
    
    # Mapear cada rango de índices en el resumen intermensual obtenido con
    # fórmula del IPC
    vinterm = mapreduce(vcat, startidxs, endidxs) do startidx, endidx
        cpi = capitalize(view(base.v, startidx:endidx, :)) * base.w / 100
        varinterm(cpi)
    end
    
    # Resumen intermensual es la concatenación vertical del resumen intermensual
    # en las distintas bases sintéticas
    vinterm

end


# Función de ayuda para obtener vector de rangos
function _getranges(T, period, max_changes=0)

    # Si hay menos observaciones que el período, devolver el único rango
    T <= period && return 1, T

    # max_changes == 0 => todos los cambios de base posibles
    if max_changes == 0
        blocks = cld(T, period)
    else
        blocks = min(cld(T, period), max_changes+1)
    end

    startidxs = 1:period:T # índices iniciales
    finalidxs = Vector{Int}(undef, blocks) # vector de índices finales
    c = 0 # contador de cambios de base

    # Completar los índices finales
    for j in 1:blocks
        finalidxs[j] = startidxs[j] + period - 1
        c += 1
        if finalidxs[j] >= T || (max_changes != 0 && c > max_changes)
            finalidxs[j] = T 
            break
        end
    end
    
    startidxs[1:blocks], finalidxs
end


