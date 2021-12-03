##  ----------------------------------------------------------------------------
#   Evaluación de variantes de combinación de óptimas del escenario E (hasta
#   diciembre de 2018), utilizando los ponderadores de elastic net
#   ----------------------------------------------------------------------------
using DrWatson
@quickactivate "HEMI" 

using HEMI 
using Plots
using DataFrames, Chain, PrettyTables

## Directorios de resultados 
cv_savepath = datadir("results", "mse-combination", "Esc-E", "cvdata")
test_savepath = datadir("results", "mse-combination", "Esc-E", "testdata")
results_path = datadir("results", "mse-combination", "Esc-E", "results")
plots_path = mkpath(plotsdir("mse-combination", "Esc-E", "elasticnet"))

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
#   Evaluación del método de mínimos cuadrados con ElasticNet, variante A
#   - Se utiliza el período completo para ajuste de los ponderadores
#   ----------------------------------------------------------------------------

λ_range = 0.1:0.1:4
γ_range = 0.5:0.1:0.8
hyperparam_space_A = Base.product(λ_range, γ_range)
mse_cv_elastic_A = map(hyperparam_space_A) do hyperparams
    λ, γ = hyperparams
    mse_cv = crossvalidate(
        (t,p) -> elastic_combination_weights(t, p, λ, γ), 
        cvdata, 
        show_status=false, 
        print_weights=false)          
    mean(mse_cv)
end

# Gráfica del MSE de validación cruzada
coords_params_A = argmin(mse_cv_elastic_A)
hyperparams_elastic_A = collect(hyperparam_space_A)[argmin(mse_cv_elastic_A)]

plot(λ_range, mse_cv_elastic_A[:, coords_params_A[2]], 
    label="Cross-validation MSE", 
    legend=:topright)
scatter!([hyperparams_elastic_A[1]], [minimum(mse_cv_elastic_A)], label="λ min")
savefig(joinpath(plots_path, 
    savename(
        "hyperparams", 
        (@strdict method="elasticnet" scenario="A" lambda=hyperparams_elastic_A[1] gamma=hyperparams_elastic_A[2]), 
        "svg")))

# Evaluación sobre conjunto de prueba 
mse_test_elastic_A, w_A = crossvalidate(
    (t,p) -> elastic_combination_weights(t, p, hyperparams_elastic_A...), 
    testdata, 
    return_weights = true)

# Obtener la función de inflación asociada 
obsfn_elastic_A = InflationCombination(testconfig.inflfn, w_A, "Óptima MSE ElasticNet A")
weights_df_elastic_A = DataFrame(
    measure=measure_name(obsfn_elastic_A, return_array=true), 
    weights=w_A)

# Guardar resultados
res_A = (
    method="elasticnet", 
    scenario="A", 
    hyperparams_space = hyperparam_space_A,
    opthyperparams = hyperparams_elastic_A, 
    mse_cv = mse_cv_elastic_A, 
    mse_test = mse_test_elastic_A, 
    combfn = obsfn_elastic_A
)
dict_res_A = tostringdict(struct2dict(res_A))
wsave(joinpath(results_path, savename(dict_res_A, "jld2")), dict_res_A)

##  ----------------------------------------------------------------------------
#   Evaluación del método de mínimos cuadrados con ElasticNet, variante B
#   - Se utilizan datos de la base 2010 del IPC para el ajuste de los
#     ponderadores
#   ----------------------------------------------------------------------------

λ_range = 0.1:0.1:4
γ_range = 0.5:0.1:0.8
hyperparam_space_B = Base.product(λ_range, γ_range)
mse_cv_elastic_B = map(hyperparam_space_B) do hyperparams
    λ, γ = hyperparams
    mse_cv = crossvalidate(
        (t,p) -> elastic_combination_weights(t, p, λ, γ), 
        cvdata, 
        train_start_date = Date(2011, 1),
        show_status=false, 
        print_weights=false)          
    mean(mse_cv)  
end

# Gráfica del MSE de validación cruzada
coords_params_B = argmin(mse_cv_elastic_B)
hyperparams_elastic_B = collect(hyperparam_space_B)[argmin(mse_cv_elastic_B)]

plot(λ_range, mse_cv_elastic_B[:, coords_params_B[2]], 
    label="Cross-validation MSE", 
    legend=:topright)
scatter!([hyperparams_elastic_B[1]], [minimum(mse_cv_elastic_B)], label="λ min")
savefig(joinpath(plots_path, 
    savename(
        "hyperparams", 
        (@strdict method="elasticnet" scenario="B" lambda=hyperparams_elastic_B[1] gamma=hyperparams_elastic_B[2]), 
        "svg")))

# Evaluación sobre conjunto de prueba 
mse_test_elastic_B, w_B = crossvalidate(
    (t,p) -> elastic_combination_weights(t, p, hyperparams_elastic_B...), 
    testdata, 
    train_start_date = Date(2011, 1),
    return_weights = true)

# Obtener la función de inflación asociada 
obsfn_elastic_B = InflationCombination(testconfig.inflfn, w_B, "Óptima MSE ElasticNet B")
weights_df_elastic_B = DataFrame(
    measure=measure_name(obsfn_elastic_B, return_array=true), 
    weights=w_B)

# Guardar resultados
res_B = (
    method="elasticnet", 
    scenario="B", 
    hyperparams_space = hyperparam_space_B,
    opthyperparams = hyperparams_elastic_B, 
    mse_cv = mse_cv_elastic_B, 
    mse_test = mse_test_elastic_B, 
    combfn = obsfn_elastic_B
)
dict_res_B = tostringdict(struct2dict(res_B))
wsave(joinpath(results_path, savename(dict_res_B, "jld2")), dict_res_B)

##  ----------------------------------------------------------------------------
#   Evaluación del método de mínimos cuadrados con ElasticNet, variante C
#   - Se utilizan datos de la base 2010 del IPC para el ajuste de los ponderadores
#   - Se agrega un intercepto a la combinación lineal 
#   ----------------------------------------------------------------------------

λ_range = 0.1:0.1:4
γ_range = 0.5:0.1:0.8
hyperparam_space_C = Base.product(λ_range, γ_range)
mse_cv_elastic_C = map(hyperparam_space_C) do hyperparams
    λ, γ = hyperparams
    mse_cv = crossvalidate(
        (t,p) -> elastic_combination_weights(t, p, λ, γ, penalize_all = false), 
        cvdata, 
        train_start_date = Date(2011, 1),
        add_intercept = true, 
        show_status=false, 
        print_weights=false)          
    mean(mse_cv)  
end

# Gráfica del MSE de validación cruzada
coords_params_C = argmin(mse_cv_elastic_C)
hyperparams_elastic_C = collect(hyperparam_space_C)[argmin(mse_cv_elastic_C)]

plot(λ_range, mse_cv_elastic_C[:, coords_params_C[2]], 
    label="Cross-validation MSE", 
    legend=:topright)
scatter!([hyperparams_elastic_C[1]], [minimum(mse_cv_elastic_C)], label="λ min")
savefig(joinpath(plots_path, 
    savename(
        "hyperparams", 
        (@strdict method="elasticnet" scenario="C" lambda=hyperparams_elastic_C[1] gamma=hyperparams_elastic_C[2]), 
        "svg")))

# Evaluación sobre conjunto de prueba 
mse_test_elastic_C, w_C = crossvalidate(
    (t,p) -> elastic_combination_weights(t, p, hyperparams_elastic_C..., penalize_all = false), 
    testdata, 
    train_start_date = Date(2011, 1),
    add_intercept = true, 
    return_weights = true)

# Obtener la función de inflación asociada 
obsfn_elastic_C = InflationCombination(
    InflationConstant(), 
    testconfig.inflfn.functions..., 
    w_C, "Óptima MSE ElasticNet C")
weights_df_elastic_C = DataFrame(
    measure=measure_name(obsfn_elastic_C, return_array=true), 
    weights=w_C)

# Guardar resultados
res_C = (
    method="elasticnet", 
    scenario="C", 
    hyperparams_space = hyperparam_space_C,
    opthyperparams = hyperparams_elastic_C, 
    mse_cv = mse_cv_elastic_C, 
    mse_test = mse_test_elastic_C, 
    combfn = obsfn_elastic_C
)
dict_res_C = tostringdict(struct2dict(res_C))
wsave(joinpath(results_path, savename(dict_res_C, "jld2")), dict_res_C)

##  ----------------------------------------------------------------------------
#   Evaluación del método de mínimos cuadrados con ElasticNet, variante D
#   - Se utilizan datos de la base 2010 del IPC para el ajuste de los ponderadores
#   - Se agrega un intercepto a la combinación lineal 
#   - Se elimina la función de exclusión fija 
#   ----------------------------------------------------------------------------

components_mask = [!(fn isa InflationFixedExclusionCPI) for fn in cvconfig.inflfn.functions]

λ_range = 0.1:0.1:4
γ_range = 0.6:0.05:0.8
hyperparam_space_D = Base.product(λ_range, γ_range)
mse_cv_elastic_D = map(hyperparam_space_D) do hyperparams
    λ, γ = hyperparams
    mse_cv = crossvalidate(
        (t,p) -> elastic_combination_weights(t, p, λ, γ, penalize_all = false), 
        cvdata, 
        train_start_date = Date(2011, 1),
        add_intercept = true, 
        components_mask = [true; components_mask], 
        show_status=false, 
        print_weights=false)          
    mean(mse_cv)  
end

# Gráfica del MSE de validación cruzada
coords_params_D = argmin(mse_cv_elastic_D)
hyperparams_elastic_D = collect(hyperparam_space_D)[argmin(mse_cv_elastic_D)]

plot(λ_range, mse_cv_elastic_D[:, coords_params_D[2]], 
    label="Cross-validation MSE", 
    legend=:topright)
scatter!([hyperparams_elastic_D[1]], [minimum(mse_cv_elastic_D)], label="λ min")
savefig(joinpath(plots_path, 
    savename(
        "hyperparams", 
        (@strdict method="elasticnet" scenario="D" lambda=hyperparams_elastic_D[1] gamma=hyperparams_elastic_D[2]), 
        "svg")))

# Evaluación sobre conjunto de prueba 
mse_test_elastic_D, w_D = crossvalidate(
    (t,p) -> elastic_combination_weights(t, p, hyperparams_elastic_D..., penalize_all = false), 
    testdata, 
    train_start_date = Date(2011, 1),
    add_intercept = true, 
    components_mask = [true; components_mask], 
    return_weights = true)

# Obtener la función de inflación asociada 
obsfn_elastic_D = InflationCombination(
    InflationConstant(), 
    testconfig.inflfn.functions[components_mask]..., 
    w_D, "Óptima MSE ElasticNet D")
weights_df_elastic_D = DataFrame(
    measure=measure_name(obsfn_elastic_D, return_array=true), 
    weights=w_D)

# Guardar resultados
res_D = (
    method="elasticnet", 
    scenario="D", 
    hyperparams_space = hyperparam_space_D,
    opthyperparams = hyperparams_elastic_D, 
    mse_cv = mse_cv_elastic_D, 
    mse_test = mse_test_elastic_D, 
    combfn = obsfn_elastic_D
)
dict_res_D = tostringdict(struct2dict(res_D))
wsave(joinpath(results_path, savename(dict_res_D, "jld2")), dict_res_D)

##  ----------------------------------------------------------------------------
#   Evaluación del método de mínimos cuadrados con ElasticNet, variante E
#   - Se utilizan datos de la base 2010 del IPC para el ajuste de los ponderadores
#   - Se elimina la función de exclusión fija 
#   ----------------------------------------------------------------------------

components_mask = [!(fn isa InflationFixedExclusionCPI) for fn in cvconfig.inflfn.functions]

λ_range = 0.1:0.1:4
γ_range = 0.5:0.1:0.8
hyperparam_space_E = Base.product(λ_range, γ_range)
mse_cv_elastic_E = map(hyperparam_space_E) do hyperparams
    λ, γ = hyperparams
    mse_cv = crossvalidate(
        (t,p) -> elastic_combination_weights(t, p, λ, γ, penalize_all = false), 
        cvdata, 
        train_start_date = Date(2011, 1),
        components_mask = components_mask, 
        show_status=false, 
        print_weights=false)          
    mean(mse_cv)  
end

# Gráfica del MSE de validación cruzada
coords_params_E = argmin(mse_cv_elastic_E)
hyperparams_elastic_E = collect(hyperparam_space_E)[argmin(mse_cv_elastic_E)]

plot(λ_range, mse_cv_elastic_E[:, coords_params_E[2]], 
    label="Cross-validation MSE", 
    legend=:topright)
scatter!([hyperparams_elastic_E[1]], [minimum(mse_cv_elastic_E)], label="λ min")
savefig(joinpath(plots_path, 
    savename(
        "hyperparams", 
        (@strdict method="elasticnet" scenario="E" lambda=hyperparams_elastic_E[1] gamma=hyperparams_elastic_E[2]), 
        "svg")))

# Evaluación sobre conjunto de prueba 
mse_test_elastic_E, w_E = crossvalidate(
    (t,p) -> elastic_combination_weights(t, p, hyperparams_elastic_E..., penalize_all = false), 
    testdata, 
    train_start_date = Date(2011, 1),
    components_mask = components_mask, 
    return_weights = true)

# Obtener la función de inflación asociada 
obsfn_elastic_E = InflationCombination(
    testconfig.inflfn.functions[components_mask]..., 
    w_E, "Óptima MSE ElasticNet E")
weights_df_elastic_E = DataFrame(
    measure=measure_name(obsfn_elastic_E, return_array=true), 
    weights=w_E)
    res_E = (

# Guardar resultados
    method="elasticnet", 
    scenario="E", 
    hyperparams_space = hyperparam_space_E,
    opthyperparams = hyperparams_elastic_E, 
    mse_cv = mse_cv_elastic_E, 
    mse_test = mse_test_elastic_E, 
    combfn = obsfn_elastic_E
)
dict_res_E = tostringdict(struct2dict(res_E))
wsave(joinpath(results_path, savename(dict_res_E, "jld2")), dict_res_E)

##  ----------------------------------------------------------------------------
#   Compilación de resultados 
#   ----------------------------------------------------------------------------

## DataFrames de ponderadores
pretty_table(weights_df_elastic_A, tf=tf_markdown, formatters=ft_round(4))
pretty_table(weights_df_elastic_B, tf=tf_markdown, formatters=ft_round(4))
pretty_table(weights_df_elastic_C, tf=tf_markdown, formatters=ft_round(4))
pretty_table(weights_df_elastic_D, tf=tf_markdown, formatters=ft_round(4))
pretty_table(weights_df_elastic_E, tf=tf_markdown, formatters=ft_round(4))

## Evaluación de CV y prueba 
results = DataFrame( 
    scenario=["A", "B", "C", "D", "E"], 
    mse_cv = map(minimum, [
        mse_cv_elastic_A, 
        mse_cv_elastic_B, 
        mse_cv_elastic_C, 
        mse_cv_elastic_D, 
        mse_cv_elastic_E]),
    mse_test = map(mean, [
        mse_test_elastic_A, 
        mse_test_elastic_B, 
        mse_test_elastic_C, 
        mse_test_elastic_D, 
        mse_test_elastic_E])
)

## Gráfica para comparar las variantes de optimización

plot(InflationTotalCPI(), gtdata)
plot!(obsfn_elastic_A, gtdata, alpha = 0.7)
plot!(obsfn_elastic_C, gtdata, alpha = 0.7)
plot!(obsfn_elastic_E, gtdata, alpha = 0.7)
plot!(obsfn_elastic_D, gtdata, linewidth = 2, color = :red)
plot!(obsfn_elastic_B, gtdata, linewidth = 3, color = :blue)
savefig(joinpath(plots_path, "trajectories.svg"))