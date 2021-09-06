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
#   Evaluación del método de mínimos cuadrados con Lasso, variante A
#   - Se utiliza el período completo para ajuste de los ponderadores
#   ----------------------------------------------------------------------------

λ_range = 0.1:0.1:4
mse_cv_lasso_A = map(λ_range) do λ
    mse_cv = crossvalidate(
        (t,p) -> lasso_combination_weights(t, p, λ, alpha=0.001), 
        cvdata, 
        show_status=false, 
        print_weights=false)          

    mean(mse_cv)  
end

# Gráfica del MSE de validación cruzada
plot(λ_range, mse_cv_lasso_A, 
    label="Cross-validation MSE", 
    legend=:topleft)
lambda_lasso = λ_range[argmin(mse_cv_lasso_A)]
scatter!([lambda_lasso], [minimum(mse_cv_lasso_A)], label="λ min")

# Evaluación sobre conjunto de prueba 
mse_test_lasso_A, w_A = crossvalidate(
    (t,p) -> lasso_combination_weights(t, p, lambda_lasso, alpha=0.001), 
    testdata, 
    return_weights = true)

# Obtener la función de inflación asociada 
obsfn_lasso_A = InflationCombination(testconfig.inflfn, w_A, "Óptima MSE Lasso A")
weights_df_lasso_A = DataFrame(
    measure=measure_name(obsfn_lasso_A, return_array=true), 
    weights=w_A)
    
##  ----------------------------------------------------------------------------
#   Evaluación del método de mínimos cuadrados con Lasso, variante B
#   - Se utilizan datos de la base 2010 del IPC para el ajuste de los ponderadores
#   ----------------------------------------------------------------------------

λ_range = 0.1:0.1:5
mse_cv_lasso_B = map(λ_range) do λ
    mse_cv = crossvalidate(
        (t,p) -> lasso_combination_weights(t, p, λ, alpha = 0.001), 
        cvdata, 
        train_start_date = Date(2011, 1))

    mean(mse_cv)  
end

# Gráfica del MSE de validación cruzada
plot(λ_range, mse_cv_lasso_B, 
    label="Cross-validation MSE", 
    legend=:topleft)
lambda_lasso = λ_range[argmin(mse_cv_lasso_B)]
scatter!([lambda_lasso], [minimum(mse_cv_lasso_B)], label="λ min")

# Evaluación sobre conjunto de prueba 
mse_test_lasso_B, w_B = crossvalidate(
    (t,p) -> lasso_combination_weights(t, p, lambda_lasso, alpha = 0.001), 
    testdata, 
    train_start_date = Date(2011, 1),
    return_weights = true)

# Obtener la función de inflación asociada 
obsfn_lasso_B = InflationCombination(testconfig.inflfn, w_B, "Óptima MSE Lasso B")
weights_df_lasso_B = DataFrame(
    measure=measure_name(obsfn_lasso_B, return_array=true), 
    weights=w_B)


##  ----------------------------------------------------------------------------
#   Evaluación del método de mínimos cuadrados con Lasso, variante C
#   - Se utilizan datos de la base 2010 del IPC para el ajuste de los ponderadores
#   - Se agrega un intercepto a la combinación lineal 
#   ----------------------------------------------------------------------------

λ_range = 0.1:0.1:5
mse_cv_lasso_C = map(λ_range) do λ
    mse_cv = crossvalidate(
        (t,p) -> lasso_combination_weights(t, p, λ, alpha=0.001, penalize_all = false), 
        cvdata, 
        add_intercept = true, 
        train_start_date = Date(2011, 1))

    mean(mse_cv)  
end

# Gráfica del MSE de validación cruzada
plot(λ_range, mse_cv_lasso_C, 
    label="Cross-validation MSE", 
    legend=:topleft)
lambda_lasso = λ_range[argmin(mse_cv_lasso_C)]
scatter!([lambda_lasso], [minimum(mse_cv_lasso_C)], label="λ min")

# Evaluación sobre conjunto de prueba 
mse_test_lasso_C, w_C = crossvalidate(
    (t,p) -> lasso_combination_weights(t, p, lambda_lasso, alpha=0.001, penalize_all = false), 
    testdata, 
    add_intercept = true, 
    train_start_date = Date(2011, 1),
    return_weights = true)

# Obtener la función de inflación asociada 
obsfn_lasso_C = InflationCombination(
    InflationConstant(), testconfig.inflfn.functions..., w_C, "Óptima MSE Lasso C")
weights_df_lasso_C = DataFrame(
    measure=measure_name(obsfn_lasso_C, return_array=true), 
    weights=w_C)


##  ----------------------------------------------------------------------------
#   Evaluación del método de mínimos cuadrados con Lasso, variante D
#   - Se utilizan datos de la base 2010 del IPC para el ajuste de los ponderadores
#   - Se agrega un intercepto a la combinación lineal 
#   - Se elimina la función de exclusión fija 
#   ----------------------------------------------------------------------------

components_mask = [!(fn isa InflationFixedExclusionCPI) for fn in cvconfig.inflfn.functions]

λ_range = 0.1:0.1:5
mse_cv_lasso_D = map(λ_range) do λ
    mse_cv = crossvalidate(
        (t,p) -> lasso_combination_weights(t, p, λ, alpha=0.001, penalize_all = false), 
        cvdata, 
        show_status = false,
        add_intercept = true, 
        train_start_date = Date(2011, 1), 
        components_mask = [true; components_mask])
    @info "MSE CV" mean(mse_cv)
    mean(mse_cv)  
end

# Gráfica del MSE de validación cruzada
plot(λ_range, mse_cv_lasso_D, 
    label="Cross-validation MSE", 
    legend=:topleft)
lambda_lasso = λ_range[argmin(mse_cv_lasso_D)]
scatter!([lambda_lasso], [minimum(mse_cv_lasso_D)], label="λ min")

# Evaluación sobre conjunto de prueba 
mse_test_lasso_D, w_D = crossvalidate(
    (t,p) -> lasso_combination_weights(t, p, lambda_lasso, alpha=0.001, penalize_all = false), 
    testdata, 
    add_intercept = true, 
    train_start_date = Date(2011, 1),
    components_mask = [true; components_mask],
    return_weights = true)

# Obtener la función de inflación asociada 
obsfn_lasso_D = InflationCombination(
    InflationConstant(), 
    testconfig.inflfn.functions[components_mask]..., 
    w_D, 
    "Óptima MSE Lasso D")

weights_df_lasso_D = DataFrame(
    measure=measure_name(obsfn_lasso_D, return_array=true), 
    weights=w_D)


##  ----------------------------------------------------------------------------
#   Compilación de resultados 
#   ----------------------------------------------------------------------------

## DataFrames de ponderadores
pretty_table(weights_df_lasso_A, tf=tf_markdown, formatters=ft_round(4))
pretty_table(weights_df_lasso_B, tf=tf_markdown, formatters=ft_round(4))
pretty_table(weights_df_lasso_C, tf=tf_markdown, formatters=ft_round(4))
pretty_table(weights_df_lasso_D, tf=tf_markdown, formatters=ft_round(4))

## Evaluación de CV y prueba 
results = DataFrame( 
    scenario=["A", "B", "C", "D"], 
    mse_cv = map(minimum, [mse_cv_lasso_A, mse_cv_lasso_B, mse_cv_lasso_C, mse_cv_lasso_D]),
    mse_test = map(mean, [mse_test_lasso_A, mse_test_lasso_B, mse_test_lasso_C, mse_test_lasso_D])
)

## Gráfica para comparar las variantes de optimización

plot(InflationTotalCPI(), gtdata)
plot!(obsfn_lasso_A, gtdata, linewidth = 3, color = :blue)
plot!(obsfn_lasso_B, gtdata, alpha = 0.7)
plot!(obsfn_lasso_C, gtdata, alpha = 0.7)
plot!(obsfn_lasso_D, gtdata, alpha = 0.7)