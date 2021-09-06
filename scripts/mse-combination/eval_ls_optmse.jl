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
cv_savepath = datadir("results", "mse-combination", "Esc-E", "cvdata")
test_savepath = datadir("results", "mse-combination", "Esc-E", "testdata")

##  ----------------------------------------------------------------------------
#   Cargar los datos de validación y prueba producidos con generate_cv_data.jl
#   ----------------------------------------------------------------------------
length(readdir(cv_savepath)) > 1 && 
    @warn "Existen varios archivos en directorio de datos, cargando únicamente el primero"
cvfile = filter(x -> endswith(x, ".jld2"), readdir(cv_savepath))[1]
cvdata = load(joinpath(cv_savepath, cvfile))

length(readdir(test_savepath)) > 1 && 
    @warn "Existen varios archivos en directorio de datos, cargando únicamente el primero"
testfile = filter(x -> endswith(x, ".jld2"), readdir(test_savepath))[1]
testdata = load(joinpath(test_savepath, testfile))

cvconfig = cvdata["config"]
testconfig = testdata["config"]

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


##  ----------------------------------------------------------------------------
#   Evaluación del método de mínimos cuadrados, variante B
#   - Se utilizan datos de la base 2010 del IPC para el ajuste de los ponderadores
#   ----------------------------------------------------------------------------

mse_cv_B = crossvalidate(combination_weights, cvdata, 
    train_start_date = Date(2011, 1))

mse_test_B, w_B = crossvalidate(combination_weights, testdata, 
    train_start_date = Date(2011, 1), 
    return_weights = true)

# Obtener la función de inflación asociada 
obsfn_B = InflationCombination(testconfig.inflfn, w_B, "Óptima MSE B")
weights_df_B = DataFrame(
    measure=measure_name(obsfn_B, return_array=true), 
    weights=w_B)


##  ----------------------------------------------------------------------------
#   Evaluación del método de mínimos cuadrados, variante C
#   - Se utilizan datos de la base 2010 del IPC para el ajuste de los
#     ponderadores
#   - Se agrega un intercepto a la combinación lineal 
#     ----------------------------------------------------------------------------

mse_cv_C = crossvalidate(combination_weights, cvdata, 
    add_intercept = true, 
    train_start_date = Date(2011, 1))

mse_test_C, w_C = crossvalidate(combination_weights, testdata, 
    add_intercept = true, 
    train_start_date = Date(2011, 1), 
    return_weights = true)

# Obtener la función de inflación asociada 
obsfn_C = InflationCombination(
    InflationEnsemble(InflationConstant(), testconfig.inflfn.functions...), 
    w_C, "Óptima MSE C")
weights_df_C = DataFrame(
    measure=measure_name(obsfn_C, return_array=true), 
    weights=w_C)
    

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
    train_start_date = Date(2011, 1))

mse_test_D, w_D = crossvalidate(combination_weights, testdata, 
    add_intercept = true, 
    components_mask = [true; components_mask],
    train_start_date = Date(2011, 1), 
    return_weights = true)

weights_df_D = DataFrame(
    measure=measure_name(obsfn_D, return_array=true), 
    weights=w_D)

# Obtener la función de inflación asociada 
obsfn_D = InflationCombination(
    InflationEnsemble(InflationConstant(), testconfig.inflfn.functions[components_mask]...), 
    w_D, "Óptima MSE D")


##  ----------------------------------------------------------------------------
#   Compilación de resultados 
#   ----------------------------------------------------------------------------


## DataFrames de ponderadores
pretty_table(weights_df_A, tf=tf_markdown, formatters=ft_round(4))
pretty_table(weights_df_B, tf=tf_markdown, formatters=ft_round(4))
pretty_table(weights_df_C, tf=tf_markdown, formatters=ft_round(4))
pretty_table(weights_df_D, tf=tf_markdown, formatters=ft_round(4))

## Evaluación de CV y prueba 
results = DataFrame( 
    scenario=["A", "B", "C", "D"], 
    mse_cv = map(mean, [mse_cv_A, mse_cv_B, mse_cv_C, mse_cv_D]),
    mse_test = map(mean, [mse_test_A, mse_test_B, mse_test_C, mse_test_D])
)

## Gráfica para comparar las variantes de optimización

plot(InflationTotalCPI(), gtdata)
plot!(obsfn_lsA, gtdata, alpha = 0.5)
plot!(obsfn_lsB, gtdata, alpha = 0.7)
plot!(obsfn_lsC, gtdata, alpha = 0.7)
plot!(obsfn_lsD, gtdata, linewidth = 3, color = :blue)

