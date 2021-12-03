# Función de apoyo para evaluar la métrica de la combinación lineal
function eval_combination(tray_infl::AbstractArray{F, 3}, tray_infl_param, w; 
    metric::Symbol = :corr, 
    sum_abstol::AbstractFloat = 1f-2) where F

    n = size(tray_infl, 2)
    s = metric == :corr ? -1 : 1 # signo para métrica objetivo

    bp = 2 * one(F) # penalización base sobre signos
    restp = 5 * one(F) # penalización sobre la restricción de suma

    penalty = zero(F)
    for i in 1:n 
        if w[i] < 0 
            penalty += bp - 2(w[i])
        end
    end
    if !(abs(sum(w) - 1) < sum_abstol) 
        penalty += restp + 2 * abs(sum(w) - 1)
    end 
    penalty != 0 && return penalty 

    # Computar la métrica y retornar su valor
    obj = combination_metrics(tray_infl, tray_infl_param, w)[metric]
    s*obj
end


"""
    metric_combination_weights(tray_infl::AbstractArray{F, 3}, tray_infl_param; 
        metric::Symbol = :corr, 
        w_start = nothing, 
        x_abstol::AbstractFloat = 1f-2, 
        f_abstol::AbstractFloat = 1f-4, 
        max_iterations::Int = 1000) where F

Obtiene ponderadores óptimos de combinación para la métrica `metric` a través de
una aproximación iterativa al problema de optimización de dicha métrica de la
combinación lineal de estimadores de inflación en `tray_infl` utilizando la
trayectoria de inflación paramétrica `tray_infl_param`.

Los parámetros opcionales son: 
- `metric::Symbol = :corr`: métrica a optimizar. Si se trata de la correlación
  lineal, la métrica es maximizada. El resto de métricas son minimizadas. Véase
  también [`eval_metrics`](@ref).
- `w_start = nothing`: ponderadores iniciales de búsqueda. Típicamente, un
  vector de valores flotantes.
- `x_abstol::AbstractFloat = 1f-2`: desviación absoluta máxima de los
  ponderadores. 
- `f_abstol::AbstractFloat = 1f-4`: desviación absoluta máxima en la función de
  costo.
- `sum_abstol::AbstractFloat = 1f-2`: desviación absoluta permisible máxima en
  la suma de ponderadores, respecto de la unidad.
- `max_iterations::Int = 1000`: número máximo de iteraciones. 

Devuelve un vector con los ponderadores asociados a cada estimador en las
columnas de `tray_infl`.

Ver también: [`combination_weights`](@ref), [`ridge_combination_weights`](@ref),
[`share_combination_weights`](@ref), [`elastic_combination_weights`](@ref).
"""
function metric_combination_weights(tray_infl::AbstractArray{F, 3}, tray_infl_param; 
    metric::Symbol = :corr, 
    w_start = nothing, 
    x_abstol::AbstractFloat = 1f-2, 
    f_abstol::AbstractFloat = 1f-4, 
    sum_abstol::AbstractFloat = 1f-4, 
    max_iterations::Int = 1000) where F

    # Número de ponderadores 
    n = size(tray_infl, 2)

    # Punto inicial
    if isnothing(w_start)
        w0 = ones(F, n) / n
    else
        w0 = w_start
    end

    # Cerradura de función objetivo
    objectivefn = w -> eval_combination(tray_infl, tray_infl_param, w; metric, sum_abstol)

    # Optimización iterativa
    optres = Optim.optimize(
        objectivefn, # Función objetivo 
        zeros(F, n), ones(F, n), # Límites
        w0, # Punto inicial de búsqueda 
        Optim.NelderMead(), # Método de optimización 
        Optim.Options(
            x_abstol = x_abstol, f_abstol = f_abstol, 
            show_trace = true, extended_trace=true, 
            iterations = max_iterations))

    # Obtener los ponderadores
    wf = Optim.minimizer(optres)
    wf
end