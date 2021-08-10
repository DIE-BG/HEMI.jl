## Funciones para optimización iterativa optimización para la combinación lineal 

# Esta función computa el MSE y su gradiente, al proveer los ponderadores
# para combinar las trayectorias tray_infl y evaluar con el parámetro
# especificado en tray_infl_pob
function msefn!(F, G, w, tray_infl, tray_infl_pob) 
    # Trayectoria promedio ponderado entre las medidas a combinar
    tray_infl_comb = sum(tray_infl .* w', dims=2)

    # Definición del error como función de los ponderadores
    err_t_k =  tray_infl_comb .- tray_infl_pob

    # Cómputo de gradientes
    if G !== nothing 
        mse_grad = 2 * vec(mean(err_t_k .* tray_infl, dims=[1, 3]))
        for i in eachindex(G)
            G[i] = mse_grad[i]
        end
    end
    
    # Función objetivo
    if F !== nothing 
        # Definición del MSE promedio en función de los ponderadores
        mse_prom = mean(err_t_k .^ 2)
        return mse_prom
    end
end


# Esta función computa el MSE y el gradiente respecto del vector de
# ponderaciones w. Es similar a msefn!, pero se guarda para propósitos de
# depuración
function msefn(w, tray_infl, tray_infl_pob) 
    # Trayectoria promedio ponderado entre las medidas a combinar
    tray_infl_comb = sum(tray_infl .* w', dims=2)

    # Definición del error como función de los ponderadores
    err_t_k =  tray_infl_comb .- tray_infl_pob

    # Función objetivo
    # Definición del MSE promedio en función de los ponderadores
    mse_prom = mean(err_t_k .^ 2)
    
    # Cómputo de gradientes
    mse_grad = 2 * vec(mean(err_t_k .* tray_infl, dims=[1, 3]))

    mse_prom, mse_grad
end

## Prueba con funciones sin utilización de inplace 
#=
function mseonly(w, tray_infl, tray_infl_pob) 
    # Trayectoria promedio ponderado entre las medidas a combinar
    tray_infl_comb = sum(tray_infl .* w', dims=2)

    # Definición del error como función de los ponderadores
    err_t_k =  tray_infl_comb .- tray_infl_pob

    # Función objetivo
    # Definición del MSE promedio en función de los ponderadores
    mse_prom = mean(err_t_k .^ 2)
    mse_prom
end

function gradonly(w, tray_infl, tray_infl_pob) 
    # Trayectoria promedio ponderado entre las medidas a combinar
    tray_infl_comb = sum(tray_infl .* w', dims=2)

    # Definición del error como función de los ponderadores
    err_t_k =  tray_infl_comb .- tray_infl_pob

    # Cómputo de gradientes
    mse_grad = 2 * vec(mean(err_t_k .* tray_infl, dims=[1, 3]))
    mse_grad
end

# optres = optimize(
#     a -> mseonly(a, tray_infl_mai, tray_infl_pob), 
#     a -> gradonly(a, tray_infl_mai, tray_infl_pob), 
#     ones(Float32, 10) / 10; 
#     inplace = false, show_trace = true)
=#


## Funciones de evaluación de variantes MAI para optimización de cuantiles del algoritmo de renormalización 

using CSV, DataFrames

## Función de evaluación para optimizador 
function evalmai(q, 
    maimethod, resamplefn, trendfn, evaldata, tray_infl_param; 
    K = 10_000)

    # Penalización base 
    bp = 10 * one(eltype(q))

    # Penalización para que el vector de cuantiles se encuentre en el interior
    # de [0, 1]
    all(0 .< q .< 1) || return bp + 2*sum(q .< 0) + 2*sum(q .> 1)

    # Imponer restricciones de orden con penalizaciones si se viola el orden de
    # los cuantiles 
    penalty = zero(eltype(q)) 
    for i in 1:length(q)-1
        if q[i] > q[i+1] 
            penalty += bp + 2(q[i] - q[i+1])
        end
    end 
    penalty != 0 && return penalty 

    # Crear configuración de evaluación
    inflfn = InflationCoreMai(maimethod(Float64[0, q..., 1]))

    # Evaluar la medida y obtener el MSE
    mse = eval_mse_online(inflfn, resamplefn, trendfn, evaldata, 
        tray_infl_param; K)
    mse + penalty 
end

# Prueba de la función 
# evalmai([0.3, 0.74], 
#     MaiFP, resamplefn, trendfn, gtdata_eval, 
#     tray_infl_param; 
#     K = 100) 
# 0.2228

# evalmai([0.1, 0.5, 0.7], 
#     MaiFP, resamplefn, trendfn, gtdata_eval, 
#     tray_infl_param; 
#     K = 100) 
# 0.4122982f0


# Función para optimización de método en `method` con n segmentos 
function optimizemai(n, method, resamplefn, trendfn, dataeval, tray_infl_param; 
    savepath, # Ruta de guardado de resultados de optimización 
    K = 10_000, # Número de simulaciones por defecto 
    qstart = nothing, # Puntos iniciales, por defecto distribución uniforme 
    x_abstol = 1e-4, 
    f_abstol = 1e-4, 
    maxiterations = 100
    )

    # Puntos iniciales de búsqueda 
    if isnothing(qstart)
        q0 = collect(1/n:1/n:(n-1)/n) 
    else
        q0 = qstart
    end

    # Se dejan los límites entre 0 y 1 y las restricciones de orden e
    # interioridad se delegan a evalmai
    qinf, qsup = zeros(n), ones(n)

    # Función cerradura 
    maimse = q -> evalmai(q, method, resamplefn, trendfn, dataeval, 
        tray_infl_param; K)
        
    # Optimización
    optres = optimize(
        maimse, # Función objetivo 
        qinf, qsup, # Límites
        q0, # Punto inicial
        NelderMead(), # Método
        Optim.Options(
            x_abstol = x_abstol, f_abstol = f_abstol, 
            show_trace = true, extended_trace=true, 
            iterations = maxiterations))

    println(optres)
    @info "Resultados de optimización:" min_mse=minimum(optres) minimizer=Optim.minimizer(optres)  iterations=Optim.iterations(optres)
    
    # Guardar resultados
    results = Dict(
        "method" => string(method), 
        "n" => n, 
        "q" => Optim.minimizer(optres), 
        "mse" => minimum(optres),
        "K" => K,
        "optres" => optres
    )

    # Guardar los resultados 
    if Sys.iswindows() && Sys.windows_version() < v"10"
        # Guardar resultados en CSV para optimización en equipo servidor 
        filename = savename(results, "csv", allowedtypes=(Real, String), digits=6)
        CSV.write(filename, DataFrame(results))
    else 
        # Resultados de evaluación para collect_results 
        filename = savename(results, "jld2", allowedtypes=(Real, String), digits=6)
        wsave(joinpath(savepath, filename), tostringdict(results))
    end

    optres 
end

# optimizemai(3, MaiFP, resamplefn, trendfn, gtdata_eval, tray_infl_param, K=100)