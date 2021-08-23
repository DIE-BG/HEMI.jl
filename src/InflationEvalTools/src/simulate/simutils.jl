# Esta función puede evaluar solo una medida de inflación
"""
    evalsim(data_eval::CountryStructure, config::SimConfig; 
        rndseed = DEFAULT_SEED, 
        short = false) -> (Dict, Array{<:AbstractFloat, 3})

Esta función genera la trayectoria paramétrica, las trayectorias de simulación
y las métricas de evaluación utilizando la configuración [`SimConfig`](@ref).
Devuelve `(metrics, tray_infl)`.

Las métricas de evaluación se devuelven en el diccionario `metrics`. Si
`short=true`, el diccionario contiene únicamente la llave `:mse`. Este
diccionario corto es útil para optimización iterativa. Por defecto, se computa
el diccionario completo de métricas, pero este proceso es más intensivo en
memoria. Ver también [`eval_metrics`](@ref).

Las trayectorias de inflación simuladas son devueltas en `tray_infl` como un
arreglo tridimensional de dimensión `(T, 1, K)`, en donde `T` corresponde a los
períodos de inflación computados y `K` representa el número de realizaciones de
la simulación. La dimensión unitaria `1` sirve para concatenar posteriormente
los resultados de simulación. Por ejemplo, en el cómputo de una medida de
promedio ponderado óptima. 

## Utilización

La función `evalsim` recibe un [`CountryStructure`](@ref) y un `AbstractConfig`
del tipo [`SimConfig`](@ref).

### Ejemplo

Teniendo una configuración de tipo `SimConfig` y un conjunto de datos
`gtdata_eval`

```jldoctest evalsimconf
julia> config = SimConfig(
        InflationPercentileEq(69),
        ResampleScrambleVarMonths(),
        TrendRandomWalk(),
        InflationTotalRebaseCPI(36, 2), 10_000, Date(2019,12))
SimConfig{InflationPercentileEq, ResampleScrambleVarMonths, TrendRandomWalk{Float32}}
|─> Función de inflación            : Percentil equiponderado 69.0
|─> Función de remuestreo           : Bootstrap IID por meses de ocurrencia
|─> Función de tendencia            : Tendencia de caminata aleatoria
|─> Método de inflación paramétrica : Variación interanual IPC con cambios de base sintéticos (36, 2)
|─> Número de simulaciones          : 10000
|─> Fin set de entrenamiento        : Dec-19
|─> Períodos de evaluación          : Período completo, gt_b00:Dec-01-Dec-10, gt_t0010:Jan-11-Nov-11 y gt_b10:Dec-11-Dec-20
```

podemos ejecutar una simulación con los parámetros de `config` con: 

```julia-repl
julia> results, tray_infl = evalsim(gtdata, config)
┌ Info: Evaluación de medida de inflación
│   medida = "Percentil equiponderado 69.0"
│   remuestreo = "Bootstrap IID por meses de ocurrencia"
│   tendencia = "Tendencia de caminata aleatoria"
│   evaluación = "Variación interanual IPC con cambios de base sintéticos (36, 2)"
│   simulaciones = 10000
│   traindate = 2019-12-01
└   periodos = (Período completo, gt_b00:Dec-01-Dec-10, gt_t0010:Jan-11-Nov-11, gt_b10:Dec-11-Dec-20)
... (barra de progreso)
┌ Info: Métricas de evaluación:
│   mse = ...
└   ... (otras métricas)
```
"""
function evalsim(data::CountryStructure, config::SimConfig; 
    rndseed = DEFAULT_SEED, 
    short = false)
  
    # Obtener datos hasta la fecha de configuración 
    data_eval = data[config.traindate]

    # Obtener la trayectoria paramétrica de inflación 
    param = InflationParameter(config.paramfn, config.resamplefn, config.trendfn)
    tray_infl_pob = param(data_eval)

    @info "Evaluación de medida de inflación" medida=measure_name(config.inflfn) remuestreo=method_name(config.resamplefn) tendencia=method_name(config.trendfn) evaluación=measure_name(config.paramfn) simulaciones=config.nsim traindate=config.traindate periodos=config.evalperiods

    # Generar las trayectorias de inflación de simulación 
    tray_infl = pargentrayinfl(config.inflfn, # función de inflación
        config.resamplefn, # función de remuestreo
        config.trendfn, # función de tendencia
        data_eval, # datos de evaluación 
        rndseed = rndseed, K=config.nsim)
    println()

    # Métricas de evaluación en cada subperíodo de config 
    metrics = mapreduce(merge, config.evalperiods) do period 
        mask = eval_periods(data_eval, period)
        prefix = period_tag(period)
        metrics = @views eval_metrics(tray_infl[mask, :, :], tray_infl_pob[mask]; short, prefix)
        metrics 
    end 
    # Se filtran métricas que empiecen con gt_. Las métricas de CompletePeriod()
    # no contienen prefijo y son las que se muestran por defecto. 
    @info "Métricas de evaluación:" filter(t -> !contains(string(t), "gt_"), metrics)...

    # Devolver estos valores
    metrics, tray_infl
end

# Función para obtener diccionario de resultados y trayectorias a partir de un
# AbstractConfig
"""
    makesim(data, config::AbstractConfig; 
        rndseed = DEFAULT_SEED
        short = false) -> (Dict, Array{<:AbstractFloat, 3})

## Utilización
Esta función utiliza la función `evalsim` para generar un set de simulaciones en
base a un `CountryStructure` y un `AbstractConfig`, y genera un diccionario
`results` con todas las métricas de evaluación y con la información del
`AbstractConfig` utilizado para generarlas. Adicionalmente genera un objeto con
las trayectorias de inflación. Devuelve `(metrics, tray_infl)`.

### Ejemplos
`makesim` recibe un `CountryStructure` y un `AbstractConfig`, para trasladarlo a
`evalsim` y generar las simulaciones. Almacena las métricas y los parámetros de
simulación en el diccionario results, y Adicionalmente devuelve las trayectoria
de simulacion.

```julia-repl 
julia> results, tray_infl = makesim(gtdata, config)
┌ Info: Evaluación de medida de inflación
│   medida = "Percentil equiponderado 69.0"
│   remuestreo = "Bootstrap IID por meses de ocurrencia"
│   tendencia = "Tendencia de caminata aleatoria"
│   evaluación = "Variación interanual IPC con cambios de base sintéticos (36, 2)"
│   simulaciones = 10000
│   traindate = 2019-12-01
└   periodos = (Período completo, gt_b00:Dec-01-Dec-10, gt_t0010:Jan-11-Nov-11, gt_b10:Dec-11-Dec-20)
... (barra de progreso)
┌ Info: Métricas de evaluación:
│   mse = ...
└   ... (otras métricas)
```
"""
function makesim(data, config::AbstractConfig; 
    rndseed = DEFAULT_SEED, 
    short = false)
        
     # Ejecutar la simulación y obtener los resultados 
    metrics, tray_infl = evalsim(data, config; rndseed, short)

    # Agregar resultados a diccionario 
    results = merge(struct2dict(config), metrics)
    results[:measure] = CPIDataBase.measure_name(config.inflfn)
    results[:params] = CPIDataBase.params(config.inflfn)

    return results, tray_infl 
end


# Función para ejecutar lote de simulaciones 
"""
    run_batch(data, dict_list_params, savepath; 
        savetrajectories = true, 
        rndseed = DEFAULT_SEED)

La función `run_batch` genera paquetes de simulaciones con base en el
diccionario de parámetros de configuración.

## Utilización 
La función recibe un `CountryStructure`, un diccionario con vectores que
contienen parámetros de simulación y un directorio para almacenar archivos con
las métricas de cada una de las evaluaciones generadas.

### Ejemplo
Generamos un diccionario con parámetros de configuración para percentiles
equiponderados, desde el percentil 60 hasta el percentil 80. Esto genera un
diccionario con 21 configuraciones distintas para evaluación.

```julia-repl 
config_dict = Dict(
    :inflfn => InflationPercentileWeighted.(50:80), 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :paramfn => paramfn, 
    :traindate => Date(2019, 12),
    :nsim => 1000) |> dict_list`
``` 

Una vez creado `config_dict`, podemos generar el paquete de simulación utilizando
`run_batch`.

```julia-repl 
julia> run_batch(gtdata_eval, config_dict, savepath)
... (progreso de evaluación)
```

Una vez generadas todas las simulaciones podemos obtener los datos mediante la
función `collect_results`. Esta función lee los resultados desde `savepath` y
los presenta en un `DataFrame`.

```julia-repl 
julia> df = collect_results(savepath)
[ Info: Scanning folder `<savepath>` for result files.
[ Info: Added 31 entries.
...
```
"""
function run_batch(data, dict_list_params, savepath; 
    savetrajectories = true, 
    rndseed = DEFAULT_SEED)

    # Ejecutar lote de simulaciones 
    for (i, dict_params) in enumerate(dict_list_params)
        @info "Ejecutando simulación $i de $(length(dict_list_params))..."
        config = dict_config(dict_params)
        results, tray_infl = makesim(data, config;
            rndseed = rndseed)
        print("\n\n\n") 
        
        # Guardar los resultados 
        filename = savename(config, "jld2")
        
        # Resultados de evaluación para collect_results 
        wsave(joinpath(savepath, filename), tostringdict(results))
        
        # Guardar trayectorias de inflación, directorio tray_infl de la ruta de guardado
        savetrajectories && wsave(joinpath(savepath, "tray_infl", filename), "tray_infl", tray_infl)
    end

end


# Funciones de ayuda 

"""
    dict_config(params::Dict)

Función para convertir diccionario de parámetros a `SimConfig` o `CrossEvalConfig`.
"""
function dict_config(params::Dict)
    # CrossEvalConfig contiene el campo de períodos de evaluación 
    if !(:eval_size in keys(params))
        config = SimConfig(params[:inflfn], params[:resamplefn], params[:trendfn], params[:paramfn], params[:nsim], params[:traindate])
    else
        config = CrossEvalConfig(params[:inflfn], params[:resamplefn], params[:trendfn], params[:paramfn], params[:nsim], params[:traindate], params[:eval_size])        
    end
    config 
end

# Método opcional para lista de configuraciones
dict_config(params::AbstractVector) = dict_config.(params)