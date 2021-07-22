# MovingAverageFunction.jl - Tipo para computar medias móviles de medidas de inflación

struct InflationMovingAverage{F <: InflationFunction} <: InflationFunction
    inflfn::F
    periods::Int
end

function (mafn::InflationMovingAverage)(cs::CountryStructure)
    
    # Cómputo usual de inflación
    tray_infl = mafn.inflfn(cs)
    
    # Algoritmo de promedio móvil 
    k = mafn.periods
    k
end

function (mafn::InflationMovingAverage)(base::VarCPIBase)
    mafn.inflfn(base)
end

function moving_average(v, k)

end