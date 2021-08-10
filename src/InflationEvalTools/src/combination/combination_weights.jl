## Método de solución analítica de ponderadores de la combinación lineal óptima del MSE 

"""
    combination_weights(tray_infl, tray_infl_param) -> Vector{<:AbstractFloat}

Función de obtención de ponderadores óptimos de la solución analítica al
problema de minimización del error cuadrático medio de la combinación lineal de
estiamadores de inflación en `tray_infl` utilizando la trayectoria de inflación
paramétrica `tray_infl_param`. Devuelve un vector con los ponderadores asociados
a cada estimador en las columnas de `tray_infl`.
"""
function combination_weights(tray_infl, tray_infl_param)
    # Número de ponderadores, observaciones y simulaciones 
    T, n, K = size(tray_infl)

    # Conformar la matriz de coeficientes
    A = zeros(eltype(tray_infl), n, n)
    Atemp = zeros(eltype(tray_infl), n, n)
    for j in 1:K
        tray = @view tray_infl[:, :, j]
        mul!(Atemp, tray', tray)
        Atemp ./= T
        A += Atemp
    end
    # Promedios en número de realizaciones
    A /= K

    # Interceptos como función del parámetro y las trayectorias a combinar
    b = zeros(eltype(tray_infl), n)
    btemp = zeros(eltype(tray_infl), n)
    for j in 1:K
        tray = @view tray_infl[:, :, j]
        mul!(btemp, tray', tray_infl_param)
        btemp ./= T
        b += btemp
    end
    # Promedios en número de realizaciones
    b /= K

    # Ponderadores de combinación óptima 
    a_optim = A\b
    a_optim 
end