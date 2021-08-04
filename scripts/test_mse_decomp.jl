using DrWatson
@quickactivate "HEMI"

using HEMI 
using Plots

# Datos hasta dic-19
gtdata_eval = gtdata[Date(2019, 12)]

## Realizar evaluación de prueba 

using Distributed
addprocs(4, exeflags="--project")
@everywhere using HEMI

resamplefn = ResampleScrambleVarMonths() 
trendfn = TrendRandomWalk() 
paramfn = InflationTotalRebaseCPI(36, 2)

## Forma manual de configuración del parámetro 
legacy_param = InflationParameter(
    InflationTotalRebaseCPI(36, 2), # Cada 36 meses y hasta 2 cambios de base 
    ResampleScrambleVarMonths(),  # función de remuestreo 
    TrendRandomWalk() # función de tendencia
)

# Computar trayectorias de inflación 
tray_infl = pargentrayinfl(InflationTotalCPI(), resamplefn, trendfn, gtdata_eval; K=125_000)

# Computar la trayectoria paramétrica 
tray_infl_param = legacy_param(gtdata_eval)

## Descomposición aditiva del MSE 

err_dist = tray_infl_pksbb .- tray_infl_param
sq_err_dist = err_dist .^ 2

# MSE 
mse_dist = vec(mean(sq_err_dist, dims=1))

# Sesgo^2
me_dist = vec(mean(err_dist, dims=1))
mse_bias_dist = me_dist .^ 2 

# Componente de varianza 
s_param = std(tray_infl_param, corrected=false)
s_tray_infl = vec(std(tray_infl, dims=1, corrected=false))
mse_var_dist = @. (s_tray_infl - s_param) ^ 2

# Componente de correlación 
corr_dist = first.(cor.(eachslice(tray_infl, dims=3), Ref(tray_infl_param)))
mse_cov_dist = @. 2 * (1 - corr_dist) * s_param * s_tray_infl

[(mse_dist[i], mse_bias_dist[i], mse_var_dist[i], mse_dist[i] - mse_bias_dist[i] - mse_var_dist[i], mse_cov_dist[i], 
    mse_bias_dist[i] + mse_var_dist[i] + mse_cov_dist[i]) for i in 1:2]


@time metrics = InflationEvalTools.eval_metrics(tray_infl, tray_infl_param)
# ResampleScrambleVarMonths()
# Dict{Symbol, AbstractFloat} with 11 entries:
#   :mse_bias       => 9.96055
#   :mse_var        => 61.0259
#   :huber          => 1.89814
#   :mse_cov        => 8.35377
#   :mae            => 2.30347
#   :me             => 1.52514
#   :rmse           => 4.18822
#   :mse            => 79.3402
#   :std_sim_error2 => 2.28668
#   :std_sim_error  => 0.683029
#   :corr           => 0.778792

# ResampleSBB(36)
# Dict{Symbol, AbstractFloat} with 11 entries:
#   :mse_bias       => 0.673707
#   :mse_var        => 1.9996
#   :huber          => 1.56801
#   :mse_cov        => 5.23053
#   :mae            => 1.99997
#   :me             => 0.621594
#   :rmse           => 2.76763
#   :mse            => 7.90384
#   :std_sim_error2 => 0.0087674
#   :std_sim_error  => 0.00332471
#   :corr           => 0.721458

#Pk72-scramble
# Dict{Symbol, AbstractFloat} with 11 entries:
#   :mse_bias       => 0.00434479
#   :mse_var        => 0.0601382
#   :huber          => 0.115552
#   :mse_cov        => 0.176897
#   :mae            => 0.356164
#   :me             => -0.0360775
#   :rmse           => 0.488233
#   :mse            => 0.24138
#   :std_sim_error2 => 0.000153141
#   :std_sim_error  => 9.22427e-5
#   :corr           => 0.984255

# Pk72-SBB36
# Dict{Symbol, AbstractFloat} with 11 entries:
#   :mse_bias       => 0.0826002
#   :mse_var        => 0.211546
#   :huber          => 0.810883
#   :mse_cov        => 2.42751
#   :mae            => 1.21016
#   :me             => 0.034138
#   :rmse           => 1.62641
#   :mse            => 2.72166
#   :std_sim_error2 => 0.00251529
#   :std_sim_error  => 0.000947671
#   :corr           => 0.825615


## Comparación distribucion MSE de período completo y error cuadrático 

std(mse_dist), std(sq_err_dist)
mean(mse_dist), mean(sq_err_dist)
maximum(mse_dist), maximum(sq_err_dist)
mean(mse_dist .< 50), mean(sq_err_dist .< 50)

##
p1 = histogram(mse_dist, normalize=:probability, linealpha=0, bins=0:0.05:3, 
    label="Distribución MSE")
p2 = histogram(vec(sq_err_dist), normalize=:probability, bins=0:0.05:3, 
    label="Distribución error cuadrático")

plot(p1, p2, layout=(1,2))
