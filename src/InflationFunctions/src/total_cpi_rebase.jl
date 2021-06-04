# total_cpi_rebase.jl - Función de inflación total con cambio de base sintético. 

Base.@kwdef struct TotalRebaseCPI <: InflationFunction
    name::String = "Variación interanual IPC con CB"
    period::Int = 36 # períodos para realizar el cambio de base sintético
end

# Computar variación intermensual resumen de medida de inflación aplicando
# metodología de cambio de base sintético
function (totalrebasefn::TotalRebaseCPI)(base::VarCPIBase)
    
    # Función de ayuda para obtener vector de rangos
    function getranges(startidxs, T)
        finalidxs = broadcast(x -> x+35, startidxs) .|> x -> (x > T) ? T : x
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



