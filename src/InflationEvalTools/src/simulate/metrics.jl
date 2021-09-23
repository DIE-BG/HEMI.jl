"""
    eval_metrics(tray_infl, tray_infl_pob; short=false) -> Dict

Función para obtener un diccionario con estadísticos de evaluación de las
realizaciones de las medidas de inflación en `tray_infl` utilizando el parámetro
`tray_infl_pob`. 

Si `short=true`, devuelve un diccionario únicamente con el error cuadrático medio (MSE) de evaluación. Útil para realizar optimización iterativa en la búsqueda de parámetros. 
"""
function eval_metrics(tray_infl, tray_infl_pob; short=false, prefix="")
    _prefix = prefix == "" ? "" : prefix * "_"
    T = size(tray_infl, 1)
    K = size(tray_infl, 3)
    
    # MSE 
    mse = _mse(tray_infl, tray_infl_pob)
    short && return Dict(Symbol(_prefix, "mse") => mse) # solo MSE si short=true
    
    # Distribuciones de error 
    err_dist = tray_infl .- tray_infl_pob
    # Distribución de error cuadrático 
    mse_dist = vec(mean(x -> x^2, err_dist, dims=1))
    sq_err_dist = err_dist .^ 2
    # Desviación estándar de la distribución de MSE del período completo
    std_mse_dist = std(mse_dist, mean=mse) 
    
    # Error estándar de simulación del valor promedio obtenido 
    mse_std_error = std_mse_dist / sqrt(K)
    # mse_std_error = std(sq_err_dist, mean=mse) / sqrt(T * K)
    
    # Desviación estándar del error cuadrático ~ todos los períodos y realizaciones 
    std_sqerr_dist = std(sq_err_dist, mean=mse)
    
    # RMSE, MAE, ME
    rmse = mean(sqrt, mse_dist)
    mae = mean(abs, err_dist)
    me = mean(err_dist)
    
    # Pérdida de Huber ~ combina las propiedades del MSE y del MAE
    huber = mean(huber_loss, err_dist)

    # Correlación 
    corr_dist = first.(cor.(eachslice(tray_infl, dims=3), Ref(tray_infl_pob)))
    corr = mean(corr_dist) 

    ## Descomposición aditiva del MSE

    # Sesgo^2
    me_dist = vec(mean(err_dist, dims=1))
    mse_bias = mean(x -> x^2, me_dist)

    # Componente de varianza   
    s_param = std(tray_infl_pob, corrected=false)
    s_tray_infl = vec(std(tray_infl, dims=1, corrected=false))
    mse_var = mean(s -> (s - s_param)^2, s_tray_infl)

    # Componente de correlación 
    mse_cov_dist = @. 2 * (1 - corr_dist) * s_param * s_tray_infl
    mse_cov = mean(mse_cov_dist)

    # Diccionario de métricas a devolver
    Dict(
        Symbol(_prefix, "mse") => mse, 
        Symbol(_prefix, "mse_std_error") => mse_std_error, 
        Symbol(_prefix, "std_mse_dist") => std_mse_dist, 
        Symbol(_prefix, "std_sqerr_dist") => std_sqerr_dist, 
        Symbol(_prefix, "rmse") => rmse, 
        Symbol(_prefix, "mae") => mae, 
        Symbol(_prefix, "me") => me, 
        Symbol(_prefix, "absme") => abs(me), 
        Symbol(_prefix, "corr") => corr, 
        Symbol(_prefix, "huber") => huber,
        Symbol(_prefix, "mse_bias") => mse_bias, 
        Symbol(_prefix, "mse_var") => mse_var, 
        Symbol(_prefix, "mse_cov") => mse_cov,
        Symbol(_prefix, "T") => T
    )
end


# Pérdida de Huber 
function huber_loss(x::Real; a=1)
    if abs(x) <= a 
        return x^2 / 2
    else 
        return a*(abs(x) - a/2)
    end
end


# Error cuadrático medio - MSE: promedio a través del tiempo y número de
# realizaciones de los errores entre las trayectorias de inflación tray_infl y
# la trayectoria paramétrica de inflación tray_pob
function _mse(tray_infl, tray_infl_pob)
    mean(x -> x^2, tray_infl .- tray_infl_pob)
end


# Métricas para combinaciones lineales de estimadores 
"""
    combination_metrics(tray_infl, tray_infl_param, w; kwargs...) 

Métricas para medidas de combinación lineal. Se combinan las trayectorias en
`tray_infl` con las ponderaciones `w` y se computan las métricas de evaluación
utilizando la trayectoria paramétrica `tray_infl_param`. 

Los argumentos opcionales (`kwargs...`) son pasados a la función
[`eval_metrics`](@ref).
"""
function combination_metrics(tray_infl, tray_infl_param, w; kwargs...) 
    tray_infl_comb = sum(tray_infl .* w', dims=2)
    eval_metrics(tray_infl_comb, tray_infl_param; kwargs...)
end