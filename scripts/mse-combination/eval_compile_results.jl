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

# Resultados del escenario B - ajuste ponderadores en periodo base 2010
pretty_table(get_components(ls_results, "B"); fmtoptions...)


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


##  ----------------------------------------------------------------------------
#   Métricas de evaluación de las combinaciones lineales 
#   ----------------------------------------------------------------------------

# Cargar datos y configuración de prueba 
length(readdir(test_savepath)) > 1 && 
    @warn "Existen varios archivos en directorio de datos, cargando únicamente el primero"
testfile = filter(x -> endswith(x, ".jld2"), readdir(test_savepath))[1]
testdata = load(joinpath(test_savepath, testfile))
testconfig = testdata["config"]

tray_infl = testdata["infl_20"]
tray_param = testdata["param_20"]
dates = testdata["dates_20"]

# Métricas de combinación lineal en la base 2010
f = dates .>= Date(2011, 1)
wr = ridge_results.combfn[1].weights
mask = [!(fn isa InflationFixedExclusionCPI) for fn in testconfig.inflfn.functions]
components = @views add_ones(tray_infl[f, mask, :])
metrics = @views combination_metrics(components, tray_param[f], wr)

# Trayectoria promedio de simulación y parámetro en la base 2010
combination = sum(components .* wr', dims=2)
m_tray_infl = mean(combination, dims=3) |> vec
plot(dates[f], [m_tray_infl tray_param[f]], 
    label=["Trayectoria promedio" "Paramétrica"]
)