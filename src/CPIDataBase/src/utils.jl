using Base: start_base_include
# utils.jl - Funciones de utilidad 

# Obtiene un rango de fechas a partir de una fecha inicial `startdate` y la cantidad de períodos de una matriz de variaciones intermensuales 
function getdates(startdate::Date, periods::Int)
    startdate:Month(1):(startdate + Month(periods - 1))
end

function getdates(startdate::Date, vmat::AbstractMatrix)
   T = size(vmat, 1)
   getdates(startdate, T)
end 