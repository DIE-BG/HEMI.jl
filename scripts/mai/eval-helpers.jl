# Función de combinación de trayectorias 
function combination_weights(tray_infl, tray_infl_pob)
    # Número de ponderadores, observaciones y simulaciones 
    n = size(tray_infl, 2)
    T = size(tray_infl, 1)
    K = size(tray_infl, 3)

    # Conformar la matriz de coeficientes
    tray_infl_T = permutedims(tray_infl, [2, 1, 3])
    A = zeros(eltype(tray_infl), n, n, K)
    for j = 1:K
        A[:, :, j] = tray_infl_T[:, :, j] * tray_infl[:, :, j]
    end
    # Promedios en el tiempo y realizaciones
    A = dropdims(mean(A, dims=3), dims=3) / T

    # Interceptos como función del parámetro y las trayectorias a combinar
    b = tray_infl_pob .* tray_infl
    b = mean(b, dims=[1, 3]) |> vec

    # Ponderadores de combinación óptima 
    a_optim = A\b
    a_optim 
end

# Función de estadísticos de evaluación
function eval_metrics(tray_infl, tray_infl_pob)
    err_dist = tray_infl .- tray_infl_pob
    sq_err_dist = err_dist .^ 2
    
    mse = mean(sq_err_dist) 
    std_sim_error = std(sq_err_dist) / sqrt(K)
    
    rmse = mean(sqrt.(sq_err_dist))
    mae = mean(abs.(err_dist))
    me = mean(err_dist)
    corr = mean(cor.(eachslice(tray_infl, dims=3), Ref(tray_infl_pob)))[1]

    Dict(:mse => mse, :std_sim_error => std_sim_error, 
        :rmse => rmse, 
        :mae => mae, 
        :me => me, 
        :corr => corr)
end