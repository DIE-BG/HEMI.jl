using DrWatson
@quickactivate :HEMI

using GLMakie
using Optim
using BlackBoxOptim
using Plots

GLMakie.activate!()

## Cargar el módulo de Distributed para computación paralela
using Distributed
nprocs() < 5 && addprocs(4, exeflags="--project")
@everywhere using HEMI

## Elaboración de mapa de pérdida MSE MAI

includet("mai-optim-functions.jl")

optconfig = dict_list(Dict(
    :mainseg => 3,
    :maimethod => MaiF,
    # :resamplefn => ResampleScrambleVarMonths(),
    # :trendfn => TrendRandomWalk(),
    # :paramfn => InflationTotalRebaseCPI(36, 2),
    :resamplefn => ResampleScrambleTrended(0.5),
    :trendfn => TrendIdentity(),
    :paramfn => InflationTotalRebaseCPI(36, 2),
    :nsim => 100,
    :traindate => Date(2018, 12)))

function mai_metric(q, config, data; K=100, metric = :mse, lambda = 0.1)
    # Datos de evaluación 
    dataeval = data[config[:traindate]]
    
    # Configuración de simulación 
    resamplefn = config[:resamplefn]
    trendfn = config[:trendfn]
    paramfn = config[:paramfn]
    
    # Parámetro de inflación 
    param = InflationParameter(paramfn, resamplefn, trendfn)
    tray_infl_param = param(dataeval)
    
    evalmai(q, config[:maimethod], resamplefn, trendfn, dataeval, tray_infl_param; K, metric, lambda)
end

function mai_mse_map(config, data; K=100, lambda = 0.1)
    # Datos de evaluación 
    dataeval = data[config[:traindate]]
    
    # Configuración de simulación 
    resamplefn = config[:resamplefn]
    trendfn = config[:trendfn]
    paramfn = config[:paramfn]
    
    # Parámetro de inflación 
    param = InflationParameter(paramfn, resamplefn, trendfn)
    tray_infl_param = param(dataeval)

    # Grilla de evaluación
    r = 0.05f0 : 0.05f0 : 1f0
    q1 = [x for x in r for y in r]
    q2 = [y for x in r for y in r]
    mse = map(q1, q2) do q1, q2 
        evalmai([q1, q2], 
            config[:maimethod], 
            config[:resamplefn], 
            config[:trendfn], 
            dataeval, 
            tray_infl_param;
            K, metric = :mse, 
            lambda
        )
    end
    
    q1, q2, mse
end

## Datos para generar superficie de error
q1, q2, mse = mai_mse_map(optconfig[1], GTDATA, K=10, lambda=0)
q1_reg, q2_reg, mse_reg = mai_mse_map(optconfig[1], GTDATA, K=10, lambda=0.5)


## Superficie del MSE

fig = Figure(resolution=(1200, 800), fontsize=14)
ax = Axis3(fig[1,1], 
    xlabel = "q1", 
    ylabel = "q2", 
    zlabel = "mse"
)

zmin, zmax = minimum(mse), maximum(mse)
cmap = :heat
f = mse .< 5
sm = GLMakie.surface!(ax, q1[f], q2[f], mse[f]; 
# sm = GLMakie.surface!(ax, q1, q2, mse; 
    colormap = cmap, 
    colorrange = (zmin, zmax),
    transparency = true,
)
Colorbar(fig[1, 2], sm, height = Relative(0.5))

fig


## Regularización vs. no regularización

fig = Figure(resolution=(1200, 800), fontsize=14)
ax1 = Axis3(fig[1,1], 
    xlabel = "q1", 
    ylabel = "q2", 
    zlabel = "mse"
)
ax2 = Axis3(fig[1,3], 
    xlabel = "q1", 
    ylabel = "q2", 
    zlabel = "mse"
)

cmap = :heat

# Gráfica de superficie de MSE sin regularización
f = mse .< 5
zmin, zmax = minimum(mse), maximum(mse)
sm1 = GLMakie.surface!(ax1, q1[f], q2[f], mse[f]; 
# sm = GLMakie.surface!(ax1, q1, q2, mse; 
    colormap = cmap, 
    colorrange = (zmin, zmax),
    transparency = true,
)
Colorbar(fig[1, 2], sm1, height = Relative(0.75))

# Gráfica de superficie de MSE con regularización
f = mse_reg .< 5
zmin, zmax = minimum(mse_reg), maximum(mse_reg)
sm2 = GLMakie.surface!(ax2, q1_reg[f], q2_reg[f], mse_reg[f]; 
# sm = GLMakie.surface!(ax2, q1_reg, q2_reg, mse_reg; 
    colormap = cmap, 
    colorrange = (zmin, zmax),
    transparency = true,
)
Colorbar(fig[1, 4], sm2, height = Relative(0.75))

fig

## Optimizar MAI de prueba 
optres = optimizemai(optconfig[1], GTDATA, 
    K = 10,
    metric = :mse, 
    maxiterations = 250, 
    backend = :BlackBoxOptim,
    lambda = 0.1
)


## Evaluar métrica final 

q_opt = Optim.minimizer(optres)
q_opt = best_candidate(optres)

mai_metric(q_opt, optconfig[1], GTDATA;
    K = 10, 
    metric = :mse, 
    lambda = 0
)

mai_metric(Float32[0.629083, 0.76549, 0.796685, 0.85378], optconfig[1], GTDATA;
    K = 10, 
    metric = :mse, 
    lambda = 0
)


## 
Plots.plot(InflationTotalCPI(), GTDATA)
Plots.plot!(InflationCoreMai(MaiG(Float32[0, q_opt..., 1])), GTDATA)
Plots.plot!(InflationCoreMai(MaiFP(Float32[0, [0.629083, 0.76549, 0.796685, 0.85378]..., 1])), GTDATA)

