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

## Funciones de apoyo 
include(scriptsdir("mse-combination-2019", "optmse2019.jl"))

##  ----------------------------------------------------------------------------
#   Cargar los datos de validación y prueba producidos con generate_cv_data.jl
#   ----------------------------------------------------------------------------
cvconfig, testconfig = wload(
    joinpath(config_savepath, "cv_test_config.jld2"), 
    "cvconfig", "testconfig"
)
    
cvdata = wload(joinpath(cv_savepath, savename(cvconfig)))
testdata = wload(joinpath(test_savepath, savename(testconfig)))
    
##  ----------------------------------------------------------------------------
#   Configuración fecha inicial de ajuste de ponderadores escenarios B-E
#   ----------------------------------------------------------------------------
TRAIN_START_DATE = Date(2011, 12)

##  ----------------------------------------------------------------------------
#   Evaluación del método de mínimos cuadrados, variante A
#   - Se utiliza el período completo para ajuste de los ponderadores
#   ----------------------------------------------------------------------------

mse_cv_A = crossvalidate(combination_weights, cvdata)

mse_test_A, w_A = crossvalidate(combination_weights, testdata, 
    return_weights = true)

# Obtener la función de inflación asociada 
obsfn_A = InflationCombination(testconfig.inflfn, w_A, "Óptima MSE A")
weights_df_A = DataFrame(
    measure=measure_name(obsfn_A, return_array=true), 
    weights=w_A)

# Guardar resultados
res_A = (
    method="ls", 
    scenario="A", 
    mse_cv = mse_cv_A, 
    mse_test = mse_test_A, 
    combfn = obsfn_A
)
dict_res_A = tostringdict(struct2dict(res_A))
wsave(joinpath(results_path, savename(dict_res_A, "jld2")), dict_res_A)

##  ----------------------------------------------------------------------------
#   Evaluación del método de mínimos cuadrados, variante B
#   - Se utilizan datos de la base 2010 del IPC para el ajuste de los ponderadores
#   ----------------------------------------------------------------------------

mse_cv_B = crossvalidate(combination_weights, cvdata, 
    train_start_date = TRAIN_START_DATE)

mse_test_B, w_B = crossvalidate(combination_weights, testdata, 
    train_start_date = TRAIN_START_DATE, 
    return_weights = true)

# Obtener la función de inflación asociada 
obsfn_B = InflationCombination(testconfig.inflfn, w_B, "Óptima MSE B")
weights_df_B = DataFrame(
    measure=measure_name(obsfn_B, return_array=true), 
    weights=w_B)

# Guardar resultados
res_B = (
    method="ls", 
    scenario="B", 
    mse_cv = mse_cv_B, 
    mse_test = mse_test_B, 
    combfn = obsfn_B
)
dict_res_B = tostringdict(struct2dict(res_B))
wsave(joinpath(results_path, savename(dict_res_B, "jld2")), dict_res_B)


##  ----------------------------------------------------------------------------
#   Evaluación del método de mínimos cuadrados, variante C
#   - Se utilizan datos de la base 2010 del IPC para el ajuste de los
#     ponderadores
#   - Se agrega un intercepto a la combinación lineal 
#     ----------------------------------------------------------------------------

mse_cv_C = crossvalidate(combination_weights, cvdata, 
    add_intercept = true, 
    train_start_date = TRAIN_START_DATE)

mse_test_C, w_C = crossvalidate(combination_weights, testdata, 
    add_intercept = true, 
    train_start_date = TRAIN_START_DATE, 
    return_weights = true)

# Obtener la función de inflación asociada 
obsfn_C = InflationCombination(
    InflationEnsemble(InflationConstant(), testconfig.inflfn.functions...), 
    w_C, "Óptima MSE C")
weights_df_C = DataFrame(
    measure=measure_name(obsfn_C, return_array=true), 
    weights=w_C)

# Guardar resultados
res_C = (
    method="ls", 
    scenario="C", 
    mse_cv = mse_cv_C, 
    mse_test = mse_test_C, 
    combfn = obsfn_C
)
dict_res_C = tostringdict(struct2dict(res_C))
wsave(joinpath(results_path, savename(dict_res_C, "jld2")), dict_res_C)

##  ----------------------------------------------------------------------------
#   Evaluación del método de mínimos cuadrados, variante D
#   - Se utilizan datos de la base 2010 del IPC para el ajuste de los
#     ponderadores
#   - Se agrega un intercepto a la combinación lineal 
#   - Se elimina la función de exclusión fija 
#     ----------------------------------------------------------------------------

components_mask = [!(fn isa InflationFixedExclusionCPI) for fn in cvconfig.inflfn.functions]

mse_cv_D = crossvalidate(combination_weights, cvdata, 
    add_intercept = true, 
    components_mask = [true; components_mask],
    train_start_date = TRAIN_START_DATE)

mse_test_D, w_D = crossvalidate(combination_weights, testdata, 
    add_intercept = true, 
    components_mask = [true; components_mask],
    train_start_date = TRAIN_START_DATE, 
    return_weights = true)

    
# Obtener la función de inflación asociada 
obsfn_D = InflationCombination(
    InflationConstant(), 
    testconfig.inflfn.functions[components_mask]..., 
    w_D, "Óptima MSE D")
weights_df_D = DataFrame(
    measure=measure_name(obsfn_D, return_array=true), 
    weights=w_D)

# Guardar resultados
res_D = (
    method="ls", 
    scenario="D", 
    mse_cv = mse_cv_D, 
    mse_test = mse_test_D, 
    combfn = obsfn_D
)
dict_res_D = tostringdict(struct2dict(res_D))
wsave(joinpath(results_path, savename(dict_res_D, "jld2")), dict_res_D)

##  ----------------------------------------------------------------------------
#   Evaluación del método de mínimos cuadrados, variante E
#   - Se utilizan datos de la base 2010 del IPC para el ajuste de los ponderadores
#   - Se elimina la función de exclusión fija 
#   ----------------------------------------------------------------------------

components_mask = [!(fn isa InflationFixedExclusionCPI) for fn in cvconfig.inflfn.functions]

mse_cv_E = crossvalidate(combination_weights, cvdata, 
    components_mask = components_mask,
    train_start_date = TRAIN_START_DATE)

mse_test_E, w_E = crossvalidate(combination_weights, testdata, 
    train_start_date = TRAIN_START_DATE, 
    components_mask = components_mask,
    return_weights = true)

# Obtener la función de inflación asociada 
obsfn_E = InflationCombination(
    testconfig.inflfn.functions[components_mask]..., w_E, "Óptima MSE E")
weights_df_E = DataFrame(
    measure=measure_name(obsfn_E, return_array=true), 
    weights=w_E)

# Guardar resultados
res_E = (
    method="ls", 
    scenario="E", 
    mse_cv = mse_cv_E, 
    mse_test = mse_test_E, 
    combfn = obsfn_E
)
dict_res_E = tostringdict(struct2dict(res_E))
wsave(joinpath(results_path, savename(dict_res_E, "jld2")), dict_res_E)

##  ----------------------------------------------------------------------------
#   Compilación de resultados 
#   ----------------------------------------------------------------------------


## DataFrames de ponderadores
pretty_table(weights_df_A, tf=tf_markdown, formatters=ft_round(4))
pretty_table(weights_df_B, tf=tf_markdown, formatters=ft_round(4))
pretty_table(weights_df_C, tf=tf_markdown, formatters=ft_round(4))
pretty_table(weights_df_D, tf=tf_markdown, formatters=ft_round(4))
pretty_table(weights_df_E, tf=tf_markdown, formatters=ft_round(4))

## Evaluación de CV y prueba 
ls_results = DataFrame( 
    scenario=["A", "B", "C", "D", "E"], 
    mse_cv = map(mean, [mse_cv_A, mse_cv_B, mse_cv_C, mse_cv_D, mse_cv_E]),
    mse_test = map(mean, [mse_test_A, mse_test_B, mse_test_C, mse_test_D, mse_test_E])
)

## Gráfica para comparar las variantes de optimización

plotly()
dates = Date(2001, 12):Year(1):Date(2020, 12)

plot(InflationTotalCPI(), gtdata,
    xticks = (dates, Dates.format.(dates, dateformat"u-yy")),
    xrotation = 45
)
plot!(obsfn_B, gtdata, alpha = 0.7)
plot!(obsfn_C, gtdata, alpha = 0.7)
plot!(obsfn_D, gtdata, alpha = 0.7)
plot!(obsfn_E, gtdata, linewidth = 2, color = :red)
plot!(obsfn_A, gtdata, linewidth = 3, color = :blue)
plot!(optmse2019, gtdata, linewidth = 3, color = :black)
hline!([3], alpha=0.5, color = :gray, label=false)
savefig(joinpath(plots_path, "trajectories.html"))