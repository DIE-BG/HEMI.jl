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
test_savepath = datadir("results", "mse-combination", "Esc-E-Scramble", "testdata")
results_path = datadir("results", "mse-combination", "Esc-E-Scramble", "results")
compilation_path = datadir("results", "mse-combination", "Esc-E-Scramble", "compilation")
plots_path = mkpath(plotsdir("mse-combination", "Esc-E-Scramble", "compilation-results"))

includet(scriptsdir("mse-combination", "results_helpers.jl"))

fmtoptions = Dict(:tf => tf_markdown, :formatters => ft_round(4))

# Métricas de evaluación se obtienen en el período de la base 2010 (sin la
# transición)
metrics_config = Dict(:date_start => Date(2011, 12))

##  ----------------------------------------------------------------------------
#   Cargar datos y configuración de prueba 
#   ----------------------------------------------------------------------------

cvconfig, testconfig = wload(
    joinpath(config_savepath, "cv_test_config.jld2"), 
    "cvconfig", "testconfig"
)

testdata = wload(joinpath(test_savepath, savename(testconfig)))


##  ----------------------------------------------------------------------------
#   Resumen de resultados de validación cruzada y período de prueba 
#   ----------------------------------------------------------------------------

# Carga de resultados 
df = collect_results(results_path)

# Selección backend para gráficas 
# plotly()
gr()

## Resultados de mínimos cuadrados 

ls_results = @chain df begin 
    filter(r -> r.method == "ls", _)
    select(:method, :scenario, 
        :mse_cv => ByRow(mean) => :cv, 
        :mse_test => ByRow(mean) => :test,
        :combfn)
    sort(:test)
end

# Graficar trayectorias observadas, menor test en azul
plot_trajectories(ls_results, plots_path, "ls_combination")
pretty_table(select(ls_results, Not([:method, :combfn])); fmtoptions...)
pretty_table(get_components(ls_results); fmtoptions...)

# Métricas de evaluación 
ls_metrics = get_metrics(ls_results, testconfig, testdata; metrics_config...)

# Resultados del escenario B - ajuste ponderadores en periodo base 2010
# pretty_table(get_components(ls_results, "B"); fmtoptions...)


## Resultados de ridge 

ridge_results = @chain df begin 
    filter(r -> r.method == "ridge", _)
    select(:method, :scenario, 
        :opthyperparams => :lambda, 
        :mse_cv => ByRow(minimum) => :cv, 
        :mse_test => ByRow(mean) => :test,
        :combfn)
        sort(:test)
end

# Graficar trayectorias observadas, menor test en azul
plot_trajectories(ridge_results, plots_path, "ridge_combination")
pretty_table(select(ridge_results, Not([:method, :combfn])); fmtoptions...)
pretty_table(get_components(ridge_results); fmtoptions...)

# Métricas de evaluación 
ridge_metrics = get_metrics(ridge_results, testconfig, testdata; metrics_config...)


## Resultados de Lasso 
#=
lasso_results = @chain df begin 
    filter(r -> r.method == "lasso", _)
    select(:method, :scenario, 
        :opthyperparams => :lambda, 
        :mse_cv => ByRow(minimum) => :cv,
        :mse_test => ByRow(mean) => :test,  
        :combfn)
    sort(:test)
end

# Graficar trayectorias observadas, menor test en azul
plot_trajectories(lasso_results, plots_path, "lasso_combination")
pretty_table(select(lasso_results, Not([:method, :combfn])); fmtoptions...)
pretty_table(get_components(lasso_results); fmtoptions...)

# Métricas de evaluación 
lasso_metrics = get_metrics(lasso_results, testconfig, testdata; metrics_config...)

=#
## Optimización de míminos cuadrados restringida (share)  

share_results = @chain df begin 
    filter(r -> r.method == "share", _)
    select(:method, :scenario, 
        :mse_cv => ByRow(mean) => :cv,
        :mse_test => ByRow(mean) => :test, 
        :combfn)
    sort(:test)
end

# Graficar trayectorias observadas, menor test en azul
plot_trajectories(share_results, plots_path, "share_combination")
pretty_table(select(share_results, Not([:method, :combfn])); fmtoptions...)
pretty_table(get_components(share_results); fmtoptions...)

# Métricas de evaluación 
share_metrics = get_metrics(share_results, testconfig, testdata; metrics_config...)



## Resultados de Elastic Net
#=
elasticnet_results = @chain df begin 
    filter(r -> r.method == "elasticnet", _)
    select(:method, :scenario, 
        :opthyperparams => [:lambda, :gamma], 
        :mse_cv => ByRow(minimum) => :cv, 
        :mse_test => ByRow(mean) => :test, 
        :combfn)
    sort(:test)
end

# Graficar trayectorias observadas, menor test en azul
plot_trajectories(elasticnet_results, plots_path, "elasticnet_combination")
pretty_table(select(elasticnet_results, Not([:method, :combfn])); fmtoptions...)
pretty_table(get_components(elasticnet_results); fmtoptions...)

# Métricas de evaluación 
elasticnet_metrics = get_metrics(elasticnet_results, testconfig, testdata; metrics_config...)

=#
##  ----------------------------------------------------------------------------
#   Métricas de evaluación de las combinaciones lineales 
#   ----------------------------------------------------------------------------

# Lista de DataFrames de resultados 
all_results = [
    ls_results, 
    ridge_results, 
    # lasso_results, 
    share_results, 
    # elasticnet_results
]

# Se seleccionan métricas comunes entre métodos de combinación 
# Métodos de combinación y resultados de validación cruzada 
cv_results = mapreduce(vcat, all_results) do results 
    select(results, :method, :scenario, :cv, :test, :combfn)
end

# Combinar las métricas de evaluación en período extendido 
all_metrics = mapreduce(DataFrame, vcat, [
    ls_metrics, 
    ridge_metrics, 
    # lasso_metrics, 
    share_metrics, 
    # elasticnet_metrics
])

final_metrics = @chain all_metrics begin 
    select(:method, :scenario, :mse, :huber, :me, :corr)
end

# Combinar resultados de CV con métricas de evaluación de período extendido
compilation_results = leftjoin(cv_results, all_metrics, on=[:method, :scenario])

# Guardar los resultados
wsave(joinpath(compilation_path, "compilation_results.jld2"), 
    "compilation_results", compilation_results)

compilation_results = wload(joinpath(compilation_path, "compilation_results.jld2"), 
    "compilation_results")

# Revisión de resultados ...
select(compilation_results, Not(:combfn))

# Resultados de MSE intramuestra de todos los escenarios de acuerdo con metrics_config
@chain compilation_results begin 
    select(Not(:combfn))
    sort(:test)
    select(:method, :scenario, :cv, :test, :mse, :mse_std_error)
    pretty_table(_; fmtoptions...)
end

# Otras métricas 
@chain compilation_results begin 
    select(Not(:combfn))
    sort(:test)
    select(:method, :scenario, :cv, :test, :rmse, :me, :mae, :huber, :corr)
    pretty_table(_; fmtoptions...)
end

# Ordenar resultados por valor absoluto de error medio 
@chain compilation_results begin 
    select(Not(:combfn))
    transform(:me => ByRow(abs) => :absme)
    sort(:absme)
end 