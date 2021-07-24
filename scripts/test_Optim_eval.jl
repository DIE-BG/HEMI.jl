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
function evalperc(k, resamplefn, trendfn, evaldata; K = 10_000)

    # Crear configuración de evaluación
    evalconfig = SimConfig(
        inflfn = InflationPercentileEq(k),
        resamplefn = resamplefn, 
        trendfn = trendfn, 
        nsim = K)

    # Evaluar la medida y obtener el MSE
    results, _ = makesim(evaldata, evalconfig)
    mse = results[:mse]
    mse
end

# Prueba de la función de evaluación 
evalperc(69, resamplefn, trendfn, gtdata_eval)


## Algoritmo de optimización iterativo 

using Optim

f = k -> evalperc(first(k), resamplefn, trendfn, gtdata_eval; K = 1000)

# Podemos utilizar el método de Brent para optimización 1D. Para 
optres = optimize(f, 60, 80, Brent())
println(optres)
@info "Resultados de optimización:" min_mse=minimum(optres) minimizer=Optim.minimizer(optres)  iterations=Optim.iterations(optres)