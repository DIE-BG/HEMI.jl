# Función de combinación de trayectorias 

function combination_weights(tray_infl, tray_infl_pob)
    # Número de ponderadores, observaciones y simulaciones 
    T, n, K = size(tray_infl)

    # Conformar la matriz de coeficientes
    tray_infl_T = permutedims(tray_infl, [2, 1, 3])
    A = zeros(eltype(tray_infl), n, n)
    for j = 1:K
        A += (@views tray_infl_T[:, :, j] * tray_infl[:, :, j])
    end
    # Promedios en el tiempo y realizaciones
    A = A / (T * K)

    # Interceptos como función del parámetro y las trayectorias a combinar
    b = vec(mean(tray_infl_pob .* tray_infl, dims=[1, 3]))

    # Ponderadores de combinación óptima 
    a_optim = A\b
    a_optim 
    # A, b
end