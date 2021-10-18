##  ----------------------------------------------------------------------------
#   Evaluación de variantes de combinación de óptimas del escenario E (hasta
#   diciembre de 2018), utilizando los ponderadores de mínimos cuadrados
#   ----------------------------------------------------------------------------
using DrWatson
@quickactivate "HEMI" 

using HEMI 
using Plots
using DataFrames, Chain, PrettyTables

## Directorios de resultados 
config_savepath = datadir("results", "mse-combination", "Esc-E-Scramble-OptMAI")
cv_savepath = datadir("results", "mse-combination", "Esc-E-Scramble-OptMAI", "cvdata")
test_savepath = datadir("results", "mse-combination", "Esc-E-Scramble-OptMAI", "testdata")
results_path = datadir("results", "mse-combination", "Esc-E-Scramble-OptMAI", "results")
plots_path = mkpath(plotsdir("mse-combination", "Esc-E-Scramble-OptMAI", "ls"))

##  ----------------------------------------------------------------------------
#   Cargar los datos de validación y prueba producidos con generate_cv_data.jl
#   ----------------------------------------------------------------------------
cvconfig, testconfig = wload(
    joinpath(config_savepath, "cv_test_config.jld2"), 
    "cvconfig", "testconfig"
)
    
testdata = wload(joinpath(test_savepath, savename(testconfig)))
tray_infl = testdata["infl_20"]
tray_param = testdata["param_20"]


## Función de combinación para correlación 

using Optim 

function evalcombination(tray_infl::AbstractArray{F, 3}, tray_infl_param, w; metric::Symbol = :corr) where F

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

    # Cerradura de función a optimizar
    objectivefn = w -> evalcombination(tray_infl, tray_infl_param, w; metric)

    # Optimización
    optres = optimize(
        objectivefn, # Función objetivo 
        zeros(F, n), ones(F, n), # Límites
        w0, # Punto inicial
        NelderMead(), # Método
        Optim.Options(
            x_abstol = x_abstol, f_abstol = f_abstol, 
            show_trace = true, extended_trace=true, 
            iterations = max_iterations))

    # Normalización de ponderadores a 1
    wf = Optim.minimizer(optres)
    wf / sum(wf)

end

gtdata_20 = gtdata[Date(2020, 12)]
weights_period = GT_EVAL_B10
periods_mask = eval_periods(gtdata_20, weights_period)
mask = [!(fn isa InflationFixedExclusionCPI) for fn in testconfig.inflfn.functions]

# Ponderadores de correlación 
t1 = metric_combination_weights(tray_infl[periods_mask, mask, :], tray_param[periods_mask], max_iterations = 250, metric = :corr)
t2 = metric_combination_weights(tray_infl[periods_mask, :, :], tray_param[periods_mask], max_iterations = 250, metric = :corr)

combination_metrics(tray_infl[periods_mask, mask, :], tray_param[periods_mask], t1)[:corr]
combination_metrics(tray_infl[periods_mask, :, :], tray_param[periods_mask], t2)[:corr]


## Ponderadores de absme
t1 = metric_combination_weights(tray_infl[periods_mask, mask, :], tray_param[periods_mask], max_iterations = 250, metric = :absme)
t2 = metric_combination_weights(tray_infl[periods_mask, :, :], tray_param[periods_mask], max_iterations = 250, metric = :absme)

combination_metrics(tray_infl[periods_mask, mask, :], tray_param[periods_mask], t1)[:absme]
combination_metrics(tray_infl[periods_mask, :, :], tray_param[periods_mask], t2)[:absme]

t1 = metric_combination_weights(tray_infl[periods_mask, mask, :], tray_param[periods_mask], metric = :absme)
