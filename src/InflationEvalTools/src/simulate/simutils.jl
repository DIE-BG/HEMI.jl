# Esta función puede evaluar solo una medida de inflación
"""
    evalsim(data_eval::CountryStructure, config::SimConfig)

Esta función genera la trayectoria paramétrica , las trayectorias de simulación
y las métricas de evaluación utilizando la configuración [`SimConfig`](@ref). 

Genera el error cuadrático medio `mse`, el error estándar de simulación
`std_sim_error`, la raíz del error cuadrático medio `rmse`, el error medio `me`
y el error absoluto medio `mae`, así como un array con las trayectorias de
simulación `tray_infl`.

## Utilización

La función `evalsim` recibe un `CountryStructure` y un `AbstractConfig` del tipo
`SimConfig`.

### Ejemplo

Teniendo una configuración del tipo `SimConfig` y un set de datos `gtdata_eval`

```julia-repl 
julia> config = SimConfig(totalfn, resamplefn, trendfn, 1000)
|─> Función de inflación : InflationTotalCPI
|─> Función de remuestreo: ResampleSBB-36
|─> Función de tendencia : TrendRandomWalk

julia> evalsim(gtdata_eval, configA)
┌ Info: Evaluación de medida de inflación
│   medida = "Variación interanual IPC"
│   remuestreo = "Block bootstrap estacionario con bloque esperado 36"
│   tendencia = "Tendencia de caminata aleatoria"
└   simulaciones = 1000

┌ Info: Métricas de evaluación:
│   mse = 7.518966f0
│   std_sim_error = 0.48772313050091165
│   rmse = 1.9927315f0
│   me = 0.42103088f0
└   mae = 1.9927315f0

(7.518966f0, 0.48772313050091165, 1.9927315f0, 0.42103088f0, 1.9927315f0, Float32[6.043124; 6.0636163; … ; 2.16223; 2.7750611]

Float32[6.7873716; 7.222402; … ; -0.022548437; 2.0638824]

Float32[3.548479; 3.321886; … ; 6.0159087; 5.401492]

...

Float32[5.1038027; 5.1111817; … ; 8.468747; 7.354617]

Float32[6.1980247; 5.1128864; … ; 6.4607024; 5.8743]

Float32[5.035937; 5.7404637; … ; 8.130074; 7.985401])
```
"""
function evalsim(data_eval::CountryStructure, config::SimConfig)
  
    # Obtener la trayectoria paramétrica de inflación 
    param = ParamTotalCPIRebase(config.resamplefn, config.trendfn)
    tray_infl_pob = param(data_eval)

    @info "Evaluación de medida de inflación" medida=measure_name(config.inflfn) remuestreo=method_name(config.resamplefn) tendencia=method_name(config.trendfn) simulaciones=config.nsim 

    # Generar las trayectorias de inflación de simulación 
    tray_infl = pargentrayinfl(config.inflfn, # función de inflación
        config.resamplefn, # función de remuestreo
        config.trendfn, # función de tendencia
        data_eval, # datos de evaluación 
        rndseed = 0, K=config.nsim)
    println()

    # Métricas de evaluación 
    err_dist = tray_infl .- tray_infl_pob
    sq_err_dist = err_dist .^ 2
    mse = mean(sq_err_dist) 
    std_sim_error = std(sq_err_dist) / sqrt(config.nsim)
    rmse = mean(sqrt.(sq_err_dist))
    mae = mean(abs.(err_dist))
    me = mean(err_dist)
    corr = mean(cor.(eachslice(tray_infl, dims=3), Ref(tray_infl_pob)))[1]
    @info "Métricas de evaluación:" mse std_sim_error rmse me mae corr

    # Devolver estos valores
    mse, std_sim_error, rmse, me, mae, corr, tray_infl
end

# Función para obtener diccionario de resultados y trayectorias a partir de un
# AbstractConfig
"""
    makesim(data, config::AbstractConfig)

## Utilización
Esta función utiliza la función `evalsim` para generar un set de simulaciones en
base a un `CountryStructure` y un `AbstractConfig`, y genera un diccionario
`results` con todas las métricas de evaluación y con la información del
`AbstractConfig` utilizado para generarlas. Adicionalmente genera un objeto con
las trayectorias de inflación.

### Ejemplos
`makesim` recibe un `CountryStructure` y un `AbstractConfig`, para trasladarlo a
`evalsim` y generar las simulaciones. Almacena las métricas y los parámetros de
simulación en el diccionario results, y Adicionalmente devuelve las trayectoria
de simulacion.

```julia-repl 
julia> results, tray_infl = makesim(gtdata_eval, configA);
┌ Info: Evaluación de medida de inflación
│   medida = "Variación interanual IPC"
│   remuestreo = "Block bootstrap estacionario con bloque esperado 36"
│   tendencia = "Tendencia de caminata aleatoria"
└   simulaciones = 1000

┌ Info: Métricas de evaluación:
│   mse = 7.518966f0
│   std_sim_error = 0.48772313050091165
│   rmse = 1.9927315f0
│   me = 0.42103088f0
└   mae = 1.9927315f0
```
Exploramos el diccionario `results`:

```julia-repl 
julia> results
Dict{Symbol, Any} with 11 entries:
  :trendfn       => TrendRandomWalk{Float32}(Float32[0.953769, 0.948405, 0.926209, 0.902285, 0.832036, 0.825772, 0.799508, 0.789099, 0.764708, 0.757526  …  1.04656, 1.0…  :params        => (nothing,)
  :measure       => "Variación interanual IPC"
  :resamplefn    => ResampleSBB(36, Distributions.Geometric{Float64}(p=0.0277778))
  :me            => 0.421031
  :mae           => 1.99273
  :nsim          => 1000
  :rmse          => 1.99273
  :inflfn        => InflationTotalCPI()
  :mse           => 7.51897
  :std_sim_error => 0.487723
```
"""
function makesim(data, config::AbstractConfig)
        
     # Ejecutar la simulación y obtener los resultados 
    mse, std_sim_error, rmse, me, mae, corr, tray_infl = evalsim(data, config)

    # Agregar resultados a diccionario 
    results = struct2dict(config)
    results[:mse] = mse
    results[:std_sim_error] = std_sim_error
    results[:rmse] = rmse
    results[:me] = me
    results[:mae] = mae
    results[:corr] = corr
    results[:measure] = CPIDataBase.measure_name(config.inflfn)
    results[:params] = CPIDataBase.params(config.inflfn)

    return results, tray_infl 
end


# Función para ejecutar lote de simulaciones 
"""
    run_batch(data, dict_list_params, savepath; savetrajectories = true)  

La función `run_batch` genera paquetes de simulaciones con base en diccionario
de parámetros de configuración.

## Utilización 
La función recibe un `CountryStructure`, un diccionario con vectores que
contienen parámetros de simulación y un directorio para almacenar archivos con
las métricas de cada una de las evaluaciones generadas.

### Ejemplo
Generamos un diccionario con parámetros de configuración para percentiles
equiponderados, desde el percentil 60 hasta el percentil 80. Esto genera un
diccionario con 21 configuraciones distintas para evaluación.

```julia-repl 
dict_prueba = Dict(
    :inflfn => InflationPercentileEq.(60:80), 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :nsim => 1000) |> dict_list`
``` 
Una vez creado dict_prueba, podemos generar el paquete de simulación utilizando
run_batch.
```julia-repl 
run_batch(gtdata_eval, dict_prueba, savepath)`
```

Una vez generadas todas las simulaciones podemos obtener los datos mediante la
función `collect_results`. Esta función lee los resultados desde `savepath` y
los presenta en un DataFrame.

```julia-repl 
julia> df = collect_results(savepath)
[ Info: Scanning folder `savepath` for result files.
[ Info: Added 21 entries.
21×12 DataFrame
 Row │ inflfn                       measure                       rmse      trendfn
     │ Inflatio…?                   String?                       Float32?  TrendRan…?
─────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
   1 │ InflationPercentileEq(0.6)   Percentil equiponderado 60.0   1.89932  TrendRandomWalk{Float32}(Float32…
   2 │ InflationPercentileEq(0.61)  Percentil equiponderado 61.0   1.77141  TrendRandomWalk{Float32}(Float32…
   3 │ InflationPercentileEq(0.62)  Percentil equiponderado 62.0   1.65418  TrendRandomWalk{Float32}(Float32…
   4 │ InflationPercentileEq(0.63)  Percentil equiponderado 63.0   1.54492  TrendRandomWalk{Float32}(Float32…
   5 │ InflationPercentileEq(0.64)  Percentil equiponderado 64.0   1.44367  TrendRandomWalk{Float32}(Float32…
  ⋮  │              ⋮                            ⋮                   ⋮                      ⋮                  ⋮  ⋮  ⋮  ⋮  ⋮  ⋮  ⋮  ⋮
  18 │ InflationPercentileEq(0.77)  Percentil equiponderado 77.0   2.40816  TrendRandomWalk{Float32}(Float32…
  19 │ InflationPercentileEq(0.78)  Percentil equiponderado 78.0   2.75684  TrendRandomWalk{Float32}(Float32…
  20 │ InflationPercentileEq(0.79)  Percentil equiponderado 79.0   3.154    TrendRandomWalk{Float32}(Float32…
  21 │ InflationPercentileEq(0.8)   Percentil equiponderado 80.0   3.59652  TrendRandomWalk{Float32}(Float32…
                                                                                                         8 columns and 12 rows omitted
```
"""
function run_batch(data, dict_list_params, savepath; savetrajectories = true)

    # Ejecutar lote de simulaciones 
    for (i, dict_params) in enumerate(dict_list_params)
        @info "Ejecutando simulación $i..."
        config = dict_config(dict_params) 
        results, tray_infl = makesim(data, config)

        # Guardar los resultados 
        filename = savename(config, "jld2", connector= " - ", equals=" = ")
        
        # Resultados de evaluación para collect_results 
        wsave(joinpath(savepath, filename), tostringdict(results))
        
        # Guardar trayectorias de inflación, directorio tray_infl de la ruta de guardado
        savetrajectories && wsave(joinpath(savepath, "tray_infl", filename), "tray_infl", tray_infl)
    end

end


# Funciones de ayuda 
"""
    dict_config(params::Dict)

Función para convertir diccionario a `AbstractConfig`.
"""
function dict_config(params::Dict)
    # configD = SimConfig(dict_prueba[:inflfn], dict_prueba[:resamplefn], dict_prueba[:trendfn], dict_prueba[:nsim])
    if length(params) == 4
        config = SimConfig(params[:inflfn], params[:resamplefn], params[:trendfn], params[:nsim])
    else
        config = CrossEvalConfig(params[:inflfn], params[:resamplefn], params[:trendfn], params[:nsim], params[:train_date], params[:eval_size])        
    end
end