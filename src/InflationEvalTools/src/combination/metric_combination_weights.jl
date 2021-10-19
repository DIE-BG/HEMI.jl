function eval_combination(tray_infl::AbstractArray{F, 3}, tray_infl_param, w; metric::Symbol = :corr) where F

    n = size(tray_infl, 2)
    s = metric == :corr ? -1 : 1 # signo para métrica objetivo

    bp = 2 * one(F)
    restp = 5 * one(F)

    penalty = zero(F)
    for i in 1:n 
        if w[i] < 0 
            penalty += bp - 2(w[i])
        end
    end
    if !(abs(sum(w) - 1) < 1e-2) 
        penalty += restp
    end 
    penalty != 0 && return penalty 

    obj = combination_metrics(tray_infl, tray_infl_param, w)[metric]
    s*obj
end

function metric_combination_weights(tray_infl::AbstractArray{F, 3}, tray_infl_param; 
    metric::Symbol = :corr, 
    w_start = nothing, 
    x_abstol::AbstractFloat = 1f-2, 
    f_abstol::AbstractFloat = 1f-4, 
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
    objectivefn = w -> eval_combination(tray_infl, tray_infl_param, w; metric)

    # Optimización iterativa
    optres = Optim.optimize(
        objectivefn, # Función objetivo 
        zeros(F, n), ones(F, n), # Límites
        w0, # Punto inicial
        NelderMead(), # Método
        Optim.Options(
            x_abstol = x_abstol, f_abstol = f_abstol, 
            show_trace = true, extended_trace=true, 
            iterations = max_iterations))

    # Normalización de suma de ponderadores a 1
    wf = Optim.minimizer(optres)
    wf / sum(wf)
end