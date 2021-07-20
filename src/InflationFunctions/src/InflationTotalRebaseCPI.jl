# total_cpi_rebase.jl - Función de inflación total con cambio de base sintético. 

Base.@kwdef struct InflationTotalRebaseCPI <: InflationFunction
    period::Int = 60 # períodos para realizar el cambio de base sintético
end

# Nombre de la medida
measure_name(::InflationTotalRebaseCPI) = "Variación interanual IPC con cambio de base sintético"
# Etiqueta 
measure_tag(::InflationTotalRebaseCPI) = "TotalRebaseCPI"

# Parámetros
params(totalrebasefn::InflationTotalRebaseCPI) = (totalrebasefn.period, )

# Computar variación intermensual resumen de medida de inflación aplicando
# metodología de cambio de base sintético
function (totalrebasefn::InflationTotalRebaseCPI)(base::VarCPIBase)
    
    # Número de períodos para realizar cambio de base
    period = totalrebasefn.period

    # Función de ayuda para obtener vector de rangos
    function getranges(startidxs, T)
        finalidxs = broadcast(x -> x + period - 1, startidxs) .|> x -> (x > T) ? T : x
        startidxs, finalidxs
    end

    # Obtener períodos de la base
    T = periods(base)

    # Obtener vector de índices
    startidxs, endidxs = getranges(1:totalrebasefn.period:T, T)
    

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



