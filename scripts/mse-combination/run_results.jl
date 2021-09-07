using DrWatson
@quickactivate "HEMI" 

# Resultados mínimos cuadrados
include("eval_ls_optmse.jl")

# Resultados mínimos cuadrados restringidos 
include("eval_share_optmse.jl")

# Resultados combinación Ridge 
include("eval_ridge_optmse.jl")

# Resultados combinación Lasso 
include("eval_lasso_optmse.jl")

# Resultados combinación ElasticNet
include("eval_elastic_optmse.jl")

