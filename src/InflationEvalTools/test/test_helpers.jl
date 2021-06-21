
# Función para generar pesos aleatorios 
function get_random_weights(T=Float32, G=218)
    w = rand(T, G)
    w = 100 * w / sum(w)
    w
end

# Función para generar fechas a partir de matriz de variaciones intermensuales
function get_base_dates(vmat, startdate=Date(2000, 12))
    T = size(vmat, 1)
    startdate:Month(1):(startdate + Month(T-1))
end

# Función para obtener base con variaciones intermensuales iguales a cero 
function get_zero_base(T_type=Float32, G=218, T_periods=120, startdate=Date(2001,1), baseindex=100*one(T_type))
    vmat = zeros(T_type, T_periods, G)
    w = get_random_weights(T_type, G)
    dates = get_base_dates(vmat, startdate)
    vmat, w, dates, baseindex
end