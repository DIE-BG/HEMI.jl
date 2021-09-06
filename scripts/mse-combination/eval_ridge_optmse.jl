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
#   Evaluación del método de mínimos cuadrados con Ridge, variante A
#   - Se utiliza el período completo para ajuste de los ponderadores
#   ----------------------------------------------------------------------------

λ_range = 0.1:0.1:2
mse_cv_ridge_A = map(λ_range) do λ
    mse_cv = crossvalidate(
        (t,p) -> ridge_combination_weights(t, p, λ), cvdata, 
        show_status=false, 
        print_weights=false)          

    mean(mse_cv)  
end

# Gráfica del MSE de validación cruzada
plot(λ_range, mse_cv_ridge_A, 
    label="Cross-validation MSE", 
    legend=:topleft)
lambda_ridge = λ_range[argmin(mse_cv_ridge_A)]
scatter!([lambda_ridge], [minimum(mse_cv_ridge_A)], label="λ min")

# Evaluación sobre conjunto de prueba 
mse_test_ridge_A, w_A = crossvalidate(
    (t,p) -> ridge_combination_weights(t, p, lambda_ridge), testdata, 
    return_weights = true)

# Obtener la función de inflación asociada 
obsfn_ridge_A = InflationCombination(testconfig.inflfn, w_A, "Óptima MSE Ridge A")
weights_df_ridge_A = DataFrame(
    measure=measure_name(obsfn_ridge_A, return_array=true), 
    weights=w_A)
    
##  ----------------------------------------------------------------------------
#   Evaluación del método de mínimos cuadrados con Ridge, variante B
#   - Se utilizan datos de la base 2010 del IPC para el ajuste de los ponderadores
#   ----------------------------------------------------------------------------

λ_range = 0.1:0.1:10
mse_cv_ridge_B = map(λ_range) do λ
    mse_cv = crossvalidate(
        (t,p) -> ridge_combination_weights(t, p, λ), cvdata, 
        train_start_date = Date(2011, 1))

    mean(mse_cv)  
end

# Gráfica del MSE de validación cruzada
plot(λ_range, mse_cv_ridge_B, 
    label="Cross-validation MSE", 
    legend=:topleft)
lambda_ridge = λ_range[argmin(mse_cv_ridge_B)]
scatter!([lambda_ridge], [minimum(mse_cv_ridge_B)], label="λ min")

# Evaluación sobre conjunto de prueba 
mse_test_ridge_B, w_B = crossvalidate(
    (t,p) -> ridge_combination_weights(t, p, lambda_ridge), testdata, 
    train_start_date = Date(2011, 1),
    return_weights = true)

# Obtener la función de inflación asociada 
obsfn_ridge_B = InflationCombination(testconfig.inflfn, w_B, "Óptima MSE Ridge B")
weights_df_ridge_B = DataFrame(
    measure=measure_name(obsfn_ridge_B, return_array=true), 
    weights=w_B)


##  ----------------------------------------------------------------------------
#   Evaluación del método de mínimos cuadrados con Ridge, variante C
#   - Se utilizan datos de la base 2010 del IPC para el ajuste de los ponderadores
#   - Se agrega un intercepto a la combinación lineal 
#   ----------------------------------------------------------------------------

λ_range = 0.1:0.1:10
mse_cv_ridge_C = map(λ_range) do λ
    mse_cv = crossvalidate(
        (t,p) -> ridge_combination_weights(t, p, λ, penalize_all = false), 
        cvdata, 
        add_intercept = true, 
        train_start_date = Date(2011, 1))

    mean(mse_cv)  
end

# Gráfica del MSE de validación cruzada
plot(λ_range, mse_cv_ridge_C, 
    label="Cross-validation MSE", 
    legend=:topleft)
lambda_ridge = λ_range[argmin(mse_cv_ridge_C)]
scatter!([lambda_ridge], [minimum(mse_cv_ridge_C)], label="λ min")

# Evaluación sobre conjunto de prueba 
mse_test_ridge_C, w_C = crossvalidate(
    (t,p) -> ridge_combination_weights(t, p, lambda_ridge, penalize_all = false), 
    testdata, 
    add_intercept = true, 
    train_start_date = Date(2011, 1),
    return_weights = true)

# Obtener la función de inflación asociada 
obsfn_ridge_C = InflationCombination(
    InflationConstant(), testconfig.inflfn.functions..., w_C, "Óptima MSE Ridge C")
weights_df_ridge_C = DataFrame(
    measure=measure_name(obsfn_ridge_C, return_array=true), 
    weights=w_C)


##  ----------------------------------------------------------------------------
#   Evaluación del método de mínimos cuadrados con Ridge, variante D
#   - Se utilizan datos de la base 2010 del IPC para el ajuste de los ponderadores
#   - Se agrega un intercepto a la combinación lineal 
#   - Se elimina la función de exclusión fija 
#   ----------------------------------------------------------------------------

components_mask = [!(fn isa InflationFixedExclusionCPI) for fn in cvconfig.inflfn.functions]
# components_mask = [(fn isa InflationCoreMai) for fn in cvconfig.inflfn.functions]

λ_range = 0:0.005:0.05 #(0.01)
mse_cv_ridge_D = map(λ_range) do λ
    mse_cv = crossvalidate(
        (t,p) -> ridge_combination_weights(t, p, λ, penalize_all = false), 
        cvdata, 
        show_status = false,
        add_intercept = true, 
        train_start_date = Date(2011, 1), 
        components_mask = [true; components_mask])
    @info "MSE CV" mean(mse_cv)
    mean(mse_cv)  
end

# Gráfica del MSE de validación cruzada
plot(λ_range, mse_cv_ridge_D, 
    label="Cross-validation MSE", 
    legend=:topleft)
lambda_ridge = λ_range[argmin(mse_cv_ridge_D)]
scatter!([lambda_ridge], [minimum(mse_cv_ridge_D)], label="λ min")

# Evaluación sobre conjunto de prueba 
mse_test_ridge_D, w_D = crossvalidate(
    (t,p) -> ridge_combination_weights(t, p, lambda_ridge, penalize_all = false), 
    testdata, 
    add_intercept = true, 
    train_start_date = Date(2011, 1),
    components_mask = [true; components_mask],
    return_weights = true)

# Obtener la función de inflación asociada 
obsfn_ridge_D = InflationCombination(
    InflationConstant(), 
    testconfig.inflfn.functions[components_mask]..., 
    w_D, 
    "Óptima MSE Ridge D")

weights_df_ridge_D = DataFrame(
    measure=measure_name(obsfn_ridge_D, return_array=true), 
    weights=w_D)


##  ----------------------------------------------------------------------------
#   Compilación de resultados 
#   ----------------------------------------------------------------------------

## DataFrames de ponderadores
pretty_table(weights_df_ridge_A, tf=tf_markdown, formatters=ft_round(4))
pretty_table(weights_df_ridge_B, tf=tf_markdown, formatters=ft_round(4))
pretty_table(weights_df_ridge_C, tf=tf_markdown, formatters=ft_round(4))
pretty_table(weights_df_ridge_D, tf=tf_markdown, formatters=ft_round(4))

## Evaluación de CV y prueba 
results = DataFrame( 
    scenario=["A", "B", "C", "D"], 
    mse_cv = map(mean, [mse_cv_ridge_A, mse_cv_ridge_B, mse_cv_ridge_C, mse_cv_ridge_D]),
    mse_test = map(mean, [mse_test_ridge_A, mse_test_ridge_B, mse_test_ridge_C, mse_test_ridge_D])
)

## Gráfica para comparar las variantes de optimización

plot(InflationTotalCPI(), gtdata)
plot!(obsfn_ridge_A, gtdata, alpha = 0.5)
plot!(obsfn_ridge_B, gtdata, alpha = 0.7)
plot!(obsfn_ridge_C, gtdata, alpha = 0.7)
plot!(obsfn_ridge_D, gtdata, linewidth = 3, color = :blue)