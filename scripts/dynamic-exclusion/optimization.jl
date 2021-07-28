using Optim: lower_bound
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
gtdata_eval = gtdata[Date(2020, 12)]

# Funciones de remuestreo y tendencia a utilizar para evaluación 
resamplefn = ResampleSBB(36)
trendfn = TrendRandomWalk()


## Función de evaluación para optimizador 
function evalDynEx(factors_vec, evaldata;
    resamplefn = ResampleSBB(36), trendfn = TrendRandomWalk(), K = 125_000
)
    # Crear configuración de evaluación
    evalconfig = SimConfig(
        inflfn = InflationDynamicExclusion(factors_vec),
        resamplefn = resamplefn, 
        trendfn = trendfn, 
        nsim = K)

    # Evaluar la medida y obtener el MSE
    results, _ = makesim(evaldata, evalconfig)
    mse = results[:mse]
    mse
end

# Prueba de la función de evaluación 
evalDynEx([2, 2], gtdata_eval)


## Algoritmo de optimización iterativo 

using Optim

lower_b = [0f0, 0f0]
upper_b = [3f0, 3f0]

initial_params = [0.42424244f0, 1.5151515f0] # mse = 2.9163475f0


f = factors_vec -> evalDynEx(factors_vec, gtdata_eval)


optres = optimize(f, lower_b, upper_b, initial_params, NelderMead())
println(optres)
@info "Resultados de optimización:" min_mse=minimum(optres) minimizer=Optim.minimizer(optres)  iterations=Optim.iterations(optres)

#min_mse = 2.8991117f0
#[0.43126786f0, 1.4843221f0]

savepath = datadir("results", "dynamic-exclusion", "optimization")

save(
    datadir(savepath, "optres_dynEx.jld2"),
    Dict("optres" => optres)
)