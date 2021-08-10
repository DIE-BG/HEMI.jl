## Funciones para obtención de ponderadores de la combinación lineal de trayectorias 
using LinearAlgebra

## Método de solución analítica de ponderadores de la combinación lineal óptima del MSE 
function combination_weights(tray_infl, tray_infl_pob)
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
        mul!(btemp, tray', tray_infl_pob)
        btemp ./= T
        b += btemp
    end
    # Promedios en número de realizaciones
    b /= K

    # Ponderadores de combinación óptima 
    a_optim = A\b
    a_optim 
end


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