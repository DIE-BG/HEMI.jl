using Optim
# # Script de prueba para tipos que especifican variantes de simulación
using DrWatson
@quickactivate "HEMI"

## Cargar el módulo de Distributed para computación paralela
using Distributed
# Agregar procesos trabajadores
addprocs(4, exeflags="--project")

# Cargar los paquetes utilizados en todos los procesos
@everywhere using HEMI

## Obtener datos para evaluación 
# CountryStructure con datos hasta diciembre de 2020

gtdata_eval = gtdata[Date(2019, 12)]
# Funciones de remuestreo y tendencia a utilizar para evaluación 
resamplefn = ResampleScrambleVarMonths()
trendfn = TrendRandomWalk()
# Función de ayuda para construcción automática en InflationEvalTools
legacy_param = ParamTotalCPILegacyRebase#function(resamplefn, trendfn)
#    InflationParameter(
 #   InflationTotalRebaseCPI(36, 2), # Cada 36 meses y hasta 2 cambios de base 
  #  resamplefn, 
   # trendfn
#)
#end

## Función de evaluación para optimizador 
function evalDynEx(factors_vec, evaldata,
    resamplefn, trendfn,param_constructor_fn;
     K = 125_000    
)
    # Crear configuración de evaluación
    evalconfig = SimConfig(
        inflfn = InflationDynamicExclusion(factors_vec),
        resamplefn = resamplefn, 
        trendfn = trendfn, 
        nsim = K)

    # Evaluar la medida y obtener el MSE
    results, _ = makesim(evaldata, evalconfig, rndseed = 314159,
    param_constructor_fn=param_constructor_fn)
    mse = results[:mse]
    mse
end

# Prueba de la función de evaluación 
evalDynEx(
    [2, 2], 
    gtdata_eval, 
    resamplefn,
    trendfn,
    legacy_param,#ParamTotalCPILegacyRebase,
    K = 125_000)


## Algoritmo de optimización iterativo 

using Optim

lower_b = [0f0, 0f0]
upper_b = [3f0, 3f0]

initial_params = [0.3322f0, 1.7283f0] #mse 0.88526547


f = factors_vec -> evalDynEx(
    factors_vec, 
    gtdata_eval, 
    resamplefn,
    trendfn,
    legacy_param,
    K = 125_000)


optres = optimize(f, lower_b, upper_b, initial_params, NelderMead())
println(optres)
@info "Resultados de optimización:" min_mse=minimum(optres) minimizer=Optim.minimizer(optres)  iterations=Optim.iterations(optres)

savepath = datadir("results", "dynamic-exclusion", "optimization")

save(
    datadir(savepath, "optres_dynEx_SVM_2019.jld2"),
    Dict("optres" => optres)
)