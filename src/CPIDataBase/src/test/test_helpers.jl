# test_helpers.jl - Funciones de ayuda para probar los tipos de este paquete 

"""
    getrandomweights(T=Float32, G=218)
Función para generar pesos aleatorios 
"""
function getrandomweights(T=Float32, G=218)
    w = rand(T, G)
    w = 100 * w / sum(w)
    w
end

"""
    getbasedates(vmat, startdate=Date(2000, 12))
Función para generar fechas a partir de matriz de variaciones intermensuales
"""
function getbasedates(vmat, startdate=Date(2000, 12))
    T = size(vmat, 1)
    startdate:Month(1):(startdate + Month(T-1))
end


"""
    get_zero_base(T_type=Float32, G=218, T_periods=120, startdate=Date(2001,1), baseindex=100*one(T_type))
Función para obtener base de tipo `VarCPIBase` con variaciones intermensuales
iguales a cero.
"""
function getzerobase(T_type=Float32, G=218, T_periods=120, startdate=Date(2001,1), baseindex=100*one(T_type))
    vmat = zeros(T_type, T_periods, G)
    w = getrandomweights(T_type, G)
    dates = getbasedates(vmat, startdate)
    VarCPIBase(vmat, w, dates, baseindex)
end

"""
    getzerocountryst(T_type=Float32)
Obtiene un `UniformCountryStructure` cuyas variaciones intermensuales son todas
iguales a cero en la configuración de períodos del IPC de Guatemala.
"""
function getzerocountryst(T_type=Float32)
    gt00 = getzerobase(T_type, 218, 120, Date(2001, 1))
    gt10 = getzerobase(T_type, 279, 120, Date(2011, 1))
    UniformCountryStructure(gt00, gt10)
end