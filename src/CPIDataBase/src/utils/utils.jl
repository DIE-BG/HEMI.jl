# utils.jl - Funciones de utilidad 

"""
    getdates(startdate::Date, periods::Int)
Obtiene un rango de fechas a partir de una fecha inicial `startdate` y la
cantidad de períodos de una matriz de variaciones intermensuales 
"""
function getdates(startdate::Date, periods::Int)
    startdate:Month(1):(startdate + Month(periods - 1))
end

"""
    getdates(startdate::Date, vmat::AbstractMatrix)
Obtiene un rango de fechas a partir de una fecha inicial `startdate` y la
cantidad de períodos en la matriz de variaciones intermensuales `vmat`.
"""
function getdates(startdate::Date, vmat::AbstractMatrix)
   T = size(vmat, 1)
   getdates(startdate, T)
end 