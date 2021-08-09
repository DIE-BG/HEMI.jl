# # Script de evaluación de variantes de inflación subyacente MAI
using DrWatson
@quickactivate "HEMI"
using HEMI 
using Optim 

## Datos de evaluación 
const EVALDATE = Date(2019,12)
gtdata_eval = gtdata[EVALDATE]

## Cargar el módulo de Distributed para computación paralela
using Distributed
# Agregar procesos trabajadores
addprocs(4, exeflags="--project")
# Cargar los paquetes utilizados en todos los procesos
@everywhere using HEMI


## Configuración para simulaciones
# Funciones de remuestreo y tendencia
paramfn = InflationTotalRebaseCPI(36, 2)
resamplefn = ResampleScrambleVarMonths() 
trendfn = TrendRandomWalk()

## Trayectoria paramétrica
param = InflationParameter(paramfn, resamplefn, trendfn)
tray_infl_param = param(gtdata_eval)

## Función de evaluación para optimizador 
function evalmai(q, 
    maimethod, resamplefn, trendfn, evaldata, tray_infl_param; 
    K = 10_000)

    bp = 10f0

    # Penalización para vector en el interior de [0, 1]
    all(0 .< q .< 1) || return bp + 2*sum(q .< 0) + 2*sum(q .> 1)

    # Imponer restricciones de orden con penalización 
    penalty = 0f0
    for i in 1:length(q)-1
        if q[i] > q[i+1] 
            penalty += bp + 2(q[i] - q[i+1])
        end
    end 
    penalty != 0 && return penalty 

    # @info q

    # Crear configuración de evaluación
    inflfn = InflationCoreMai(maimethod(Float64[0, q..., 1]))

    # Evaluar la medida y obtener el MSE
    mse = eval_mse_online(inflfn, resamplefn, trendfn, evaldata, 
        tray_infl_param; K)
    mse + penalty 
end

# Prueba de la función 
# evalmai([0.3, 0.74], 
#     MaiFP, resamplefn, trendfn, gtdata_eval, 
#     tray_infl_param; 
#     K = 100) 
# 0.2228

# evalmai([0.1, 0.5, 0.7], 
#     MaiFP, resamplefn, trendfn, gtdata_eval, 
#     tray_infl_param; 
#     K = 100) 
# 0.4122982f0

## Configuración de búsqueda con Optim 

function optimizemai(n, method, resamplefn, trendfn, dataeval, tray_infl_param; 
    savepath,
    K = 10_000)

    # Puntos iniciales
    q0 = collect(1/n:1/n:(n-1)/n) 
    # Se dejan los límites entre 0 y 1 y las restricciones de orden e
    # interioridad se delegan a evalmai
    qinf, qsup = zeros(n), ones(n)

    # Función cerradura 
    maimse = q -> evalmai(q, method, resamplefn, trendfn, dataeval, 
        tray_infl_param; K)
        
    # Optimización
    optres = optimize(
        maimse, # Función objetivo 
        qinf, qsup, # Límites
        q0, # Punto inicial
        NelderMead(), # Método
        Optim.Options(x_abstol = 1e-4, f_abstol = 1e-4, show_trace = true, extended_trace=true))

    println(optres)
    @info "Resultados de optimización:" min_mse=minimum(optres) minimizer=Optim.minimizer(optres)  iterations=Optim.iterations(optres)
    
    # Guardar resultados
    results = Dict(
        "method" => string(method), 
        "n" => n, 
        "q" => Optim.minimizer(optres), 
        "mse" => minimum(optres),
        "K" => K,
        "optres" => optres
    )

    # Guardar los resultados 
    filename = savename(results, "jld2", allowedtypes=(Real, String), digits=6)
        
    # Resultados de evaluación para collect_results 
    wsave(joinpath(savepath, filename), tostringdict(results))
end

# optimizemai(3, MaiFP, resamplefn, trendfn, gtdata_eval, tray_infl_param, K=100)

## Generar optimización de variantes 

savepath = datadir("results", "CoreMai", "Esc-A", "Optim")
K = 10_000

## Optimización de métodos MAI

# Optimización de métodos MAI-F
optimizemai(3, MaiF, resamplefn, trendfn, gtdata_eval, tray_infl_param; K, savepath)
optimizemai(4, MaiF, resamplefn, trendfn, gtdata_eval, tray_infl_param; K, savepath)
optimizemai(5, MaiF, resamplefn, trendfn, gtdata_eval, tray_infl_param; K, savepath)
optimizemai(10, MaiF, resamplefn, trendfn, gtdata_eval, tray_infl_param; K, savepath)

# Optimización de métodos MAI-G
optimizemai(3, MaiG, resamplefn, trendfn, gtdata_eval, tray_infl_param; K, savepath)
optimizemai(4, MaiG, resamplefn, trendfn, gtdata_eval, tray_infl_param; K, savepath)
optimizemai(5, MaiG, resamplefn, trendfn, gtdata_eval, tray_infl_param; K, savepath)
optimizemai(10, MaiG, resamplefn, trendfn, gtdata_eval, tray_infl_param; K, savepath)

# Optimización de métodos MAI-FP
optimizemai(3, MaiFP, resamplefn, trendfn, gtdata_eval, tray_infl_param; K, savepath)
optimizemai(4, MaiFP, resamplefn, trendfn, gtdata_eval, tray_infl_param; K, savepath)
optimizemai(5, MaiFP, resamplefn, trendfn, gtdata_eval, tray_infl_param; K, savepath)
optimizemai(10, MaiFP, resamplefn, trendfn, gtdata_eval, tray_infl_param; K, savepath)