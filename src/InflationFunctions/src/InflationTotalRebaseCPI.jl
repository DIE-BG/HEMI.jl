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
measure_name(::InflationTotalRebaseCPI) = "Variación interanual IPC con cambios de base sintéticos"
# Etiqueta 
measure_tag(inflfn::InflationTotalRebaseCPI) = "TotalRebaseCPI-" * string(inflfn.period)

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
    startidxs, endidxs = _getranges(1:period:T, T, period, totalrebasefn.maxchanges)
    
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
function _getranges(startidxs, T, period, max_changes=0)
    finalidxs = broadcast(x -> x + period - 1, startidxs) .|> x -> (x > T) ? T : x
    
    # Devolver solo hasta los cambios de base solicitados 
    if max_changes != 0
        startidxs = startidxs[1:max_changes+1]
        finalidxs = finalidxs[1:max_changes+1]
        finalidxs[end] = T
    end

    startidxs, finalidxs
end


