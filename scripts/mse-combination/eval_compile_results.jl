##  ----------------------------------------------------------------------------
#   Evaluación de variantes de combinación de esetimadores óptimos de inflación
#   utilizando metodología de evaluación hasta diciembre de 2018. En la
#   combinación lineal de estimadores, se utilizan los ponderadores de mínimos
#   cuadrados y sus variantes con regularización y restricciones 
#   ----------------------------------------------------------------------------
using DrWatson
@quickactivate "HEMI" 

using HEMI 
using Plots
using DataFrames, Chain, PrettyTables

# Rutas de datos y resultados 
test_savepath = datadir("results", "mse-combination", "Esc-E", "testdata")
results_path = datadir("results", "mse-combination", "Esc-E", "results")
plots_path = mkpath(plotsdir("mse-combination", "Esc-E", "compilation-results"))

includet(scriptsdir("mse-combination", "results_helpers.jl"))

fmtoptions = Dict(:tf => tf_markdown, :formatters => ft_round(4))

# Métricas de evaluación se obtienen en el período de la base 2010 (sin la
# transición)
metrics_config = Dict(:date_start => Date(2011, 12))

##  ----------------------------------------------------------------------------
#   Cargar datos y configuración de prueba 
#   ----------------------------------------------------------------------------

length(readdir(test_savepath)) > 1 && 
    @warn "Existen varios archivos en directorio de datos, cargando únicamente el primero"
testfile = filter(x -> endswith(x, ".jld2"), readdir(test_savepath))[1]
testdata = load(joinpath(test_savepath, testfile))
testconfig = testdata["config"]

tray_infl = testdata["infl_20"]
tray_param = testdata["param_20"]
dates = testdata["dates_20"]


##  ----------------------------------------------------------------------------
#   Resumen de resultados de validación cruzada y período de prueba 
#   ----------------------------------------------------------------------------

## Carga de resultados 
df = collect_results(results_path)

## Resultados de mínimos cuadrados 

ls_results = @chain df begin 
    filter(r -> r.method == "ls", _)
    select(:scenario, 
        :mse_cv => ByRow(mean) => :cv, 
        :mse_test => ByRow(mean) => :test,
        :combfn)
    sort(:test)
end

# Graficar trayectorias observadas, menor test en azul
plot_trajectories(ls_results, plots_path, "ls_combination.svg")
pretty_table(select(ls_results, Not(:combfn)); fmtoptions...)
pretty_table(get_components(ls_results); fmtoptions...)

# Métricas de evaluación 
ls_metrics = get_metrics(ls_results, testconfig, testdata; metrics_config...)

# Resultados del escenario B - ajuste ponderadores en periodo base 2010
# pretty_table(get_components(ls_results, "B"); fmtoptions...)


## Resultados de ridge 

ridge_results = @chain df begin 
    filter(r -> r.method == "ridge", _)
    select(:scenario, 
        :opthyperparams => :lambda, 
        :mse_cv => ByRow(minimum) => :cv, 
        :mse_test => ByRow(mean) => :test,
        :combfn)
        sort(:test)
end

# Graficar trayectorias observadas, menor test en azul
plot_trajectories(ridge_results, plots_path, "ridge_combination.svg")
pretty_table(select(ridge_results, Not(:combfn)); fmtoptions...)
pretty_table(get_components(ridge_results); fmtoptions...)

# Métricas de evaluación 
ridge_metrics = get_metrics(ridge_results, testconfig, testdata; metrics_config...)


## Resultados de Lasso 

lasso_results = @chain df begin 
    filter(r -> r.method == "lasso", _)
    select(:scenario, 
        :opthyperparams => :lambda, 
        :mse_cv => ByRow(minimum) => :cv,
        :mse_test => ByRow(mean) => :test,  
        :combfn)
    sort(:test)
end

# Graficar trayectorias observadas, menor test en azul
plot_trajectories(lasso_results, plots_path, "lasso_combination.svg")
pretty_table(select(lasso_results, Not(:combfn)); fmtoptions...)
pretty_table(get_components(lasso_results); fmtoptions...)

# Métricas de evaluación 
lasso_metrics = get_metrics(lasso_results, testconfig, testdata; metrics_config...)


## Optimización de míminos cuadrados restringida (share)  

share_results = @chain df begin 
    filter(r -> r.method == "share", _)
    select(:scenario, 
        :mse_cv => ByRow(mean) => :cv,
        :mse_test => ByRow(mean) => :test, 
        :combfn)
    sort(:test)
end

# Graficar trayectorias observadas, menor test en azul
plot_trajectories(share_results, plots_path, "share_combination.svg")
pretty_table(select(share_results, Not(:combfn)); fmtoptions...)
pretty_table(get_components(share_results); fmtoptions...)

# Métricas de evaluación 
share_metrics = get_metrics(share_results, testconfig, testdata; metrics_config...)



## Resultados de Elastic Net

elasticnet_results = @chain df begin 
    filter(r -> r.method == "elasticnet", _)
    select(:scenario, 
        :opthyperparams => [:lambda, :gamma], 
        :mse_cv => ByRow(minimum) => :cv, 
        :mse_test => ByRow(mean) => :test, 
        :combfn)
    sort(:test)
end

# Graficar trayectorias observadas, menor test en azul
plot_trajectories(elasticnet_results, plots_path, "elasticnet_combination.svg")
pretty_table(select(elasticnet_results, Not(:combfn)); fmtoptions...)
pretty_table(get_components(elasticnet_results); fmtoptions...)

# Métricas de evaluación 
elasticnet_metrics = get_metrics(elasticnet_results, testconfig, testdata; metrics_config...)


##  ----------------------------------------------------------------------------
#   Métricas de evaluación de las combinaciones lineales 
#   ----------------------------------------------------------------------------

# Lista de DataFrames de resultados 
ls_results[!, :method] .= "LS"
ridge_results[!, :method] .= "Ridge"
lasso_results[!, :method] .= "Lasso"
share_results[!, :method] .= "Share"
elasticnet_results[!, :method] .= "Elastic Net"

all_results = [
    ls_results, 
    ridge_results, 
    lasso_results, 
    share_results, 
    elasticnet_results
]

# Mejores escenarios de cada método 
scenarios = map(all_results) do results 
    results.scenario[1]
end

# Combinar las métricas 
all_metrics = mapreduce(DataFrame, vcat, 
    [ls_metrics, ridge_metrics, lasso_metrics, share_metrics, elasticnet_metrics])

all_metrics[!, :method] = ["LS", "Ridge", "Lasso", "Share", "Elastic Net"]
all_metrics[!, :scenario] = scenarios
all_metrics

final_metrics = @chain all_metrics begin 
    select(:method, :scenario, :mse, :huber, :me, :corr)
end


# Métodos de combinación y resultados de validación cruzada 
cv_results = mapreduce(vcat, all_results) do results 
    select(results, :method, :scenario, :cv, :test)
end

@chain cv_results begin 
    sort(:test)
end
