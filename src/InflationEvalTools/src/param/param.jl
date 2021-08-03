# param.jl - Desarrollo de funciones para obtener trayectoria paramétrica de
# inflación 

"""
    param_gsbb_mod(base::VarCPIBase)
Obtiene la matriz de variaciones intermensuales paramétricas para la
metodología de remuestreo de Generalized Seasonal Block Bootstrap modificada
que extiende las observaciones a 300 períodos. Devuelve una base de tipo
VarCPIBase con las variaciones intermensuales paramétricas. Actualmente
funciona solamente si `base` tiene 120 observaciones.
"""
function param_gsbb_mod(base::VarCPIBase)

    G = size(base.v, 2)
    vpob = zeros(eltype(base), 300, G)

    # Índices de muestreo para bloques de 25 meses
    ids = [(12i + j):(12i + j + 24) for i in 0:7, j in 1:12]

    # Obtener promedios
    for m in 1:12
        # Obtener matrices en los índices correspondientes
        month_mat = map(range_ -> base.v[range_, :], ids[:, m])

        # Obtener promedio de matrices de meses y asignarlo a la matriz de
        # variaciones intermensuales para construcción de la trayectoria
        # paramétrica de inflación
        vpob[(25(m-1) + 1):(25m), :] = mean(month_mat)
    end

    # Conformar fechas
    dates = getdates(first(base.dates), vpob)
    VarCPIBase(vpob, base.w, dates, base.baseindex)
end

"""
    param_gsbb_mod(cs::CountryStructure)
Obtiene un `CountryStructure` paramétrico. 
"""
function param_gsbb_mod(cs::CountryStructure)
    # Obtener bases poblacionales
    pob_base = map(param_gsbb_mod, cs.base)
    
    # Modificar las fechas de la segunda base
    finalbase = pob_base[2]
    startdate = pob_base[1].dates[end] + Month(1)
    T = periods(finalbase)
    newdates = getdates(startdate, T)
    base10_mod = VarCPIBase(finalbase.v, finalbase.w, newdates, finalbase.baseindex)

    # Conformar nuevo CountryStructure con bases poblacionales
    getunionalltype(cs)(pob_base[1], base10_mod)
end



"""
    param_sbb(base::VarCPIBase)
Obtiene la matriz de variaciones intermensuales paramétricas para la
metodología de remuestreo de Stationary Block Bootstrap. Devuelve una base de
tipo `VarCPIBase` con las variaciones intermensuales promedio de los mismos meses
de ocurrencia (también llamadas variaciones intermensuales paramétricas). 

Esta definición también aplica a otras metodologías que utilicen como variaciones 
intermensuales paramétricas los promedios en los mismos meses de ocurrencia. 
"""
function param_sbb(base::VarCPIBase)

    # Obtener matriz de promedios mensuales
    month_mat = monthavg(base.v)

    # Conformar base de variaciones intermensuales promedio
    VarCPIBase(month_mat, base.w, base.dates, base.baseindex)
end


"""
    param_sbb(cs::CountryStructure)
Obtiene un `CountryStructure` paramétrico. 
Véase también [`param_sbb`](@ref param_sbb).
"""
function param_sbb(cs::CountryStructure)
    pob_base = map(param_sbb, cs.base)
    getunionalltype(cs)(pob_base)
end


