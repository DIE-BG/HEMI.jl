##  ----------------------------------------------------------------------------
#   Evaluación de variantes de combinación de óptimas del escenario E (hasta
#   diciembre de 2018), utilizando los ponderadores de mínimos cuadrados
#   ----------------------------------------------------------------------------
using DrWatson
@quickactivate "HEMI" 

using HEMI 
using Plots
using DataFrames, Chain, PrettyTables


results_path = datadir("results", "mse-combination", "Esc-E", "results")

df = collect_results(results_path)

@chain df begin 
    select(:method, :scenario, :mse_cv, 
        :mse_cv => ByRow(t -> map(f -> f(t), [mean, minimum, maximum])) => 
        [:mse_cv_mean, :min, :max]
    )
end

ridge_results = @chain df begin 
    filter(r -> r.method == "ridge", _)
    select(:scenario, 
        :mse_cv => ByRow(minimum) => :min_cv, 
        :opthyperparams => :lambda, 
        :combfn)
    sort(:min_cv)
end

lasso_results = @chain df begin 
    filter(r -> r.method == "lasso", _)
    select(:scenario, 
        :mse_cv => ByRow(minimum) => :min_cv, 
        :opthyperparams => :lambda, 
        :combfn)
    sort(:min_cv)
end

share_results = @chain df begin 
    filter(r -> r.method == "share", _)
    select(:scenario, 
        :mse_cv => ByRow(mean) => :mean_cv, 
        :combfn)
    sort(:mean_cv)
end


ls_results = @chain df begin 
    filter(r -> r.method == "ls", _)
    select(:scenario, 
        :mse_cv => ByRow(mean) => :mean_cv, 
        :mse_test => ByRow(mean) => :mean_cv_test,
        :combfn)
    sort(:mean_cv)
end



elasticnet_results = @chain df begin 
    filter(r -> r.method == "elasticnet", _)
    select(:scenario, 
        :mse_cv => ByRow(minimum) => :min_cv, 
        :opthyperparams => [:lambda, :gamma], 
        :mse_test => ByRow(mean), 
        :combfn)
    sort(:min_cv)
end