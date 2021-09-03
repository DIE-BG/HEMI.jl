## Función para obtener error de validación cruzada utilizando CrossEvalConfig 

"""
    crossvalidate(crossvaldata::Dict{String}, config::CrossEvalConfig, weightsfunction::Function; 
        show_status::Bool = true,
        print_weights::Bool = true, 
        return_weights::Bool = false,
        metrics::Vector{Symbol} = [:mse], 
        train_start_date::Date = Date(2000, 12), 
        components_mask = Colon(), 
        add_intercept::Bool = false) -> (cv_results::Matrix [, weights::Vector]) 

Lleva a cabo un proceso de combinación lineal de medidas de inflación y
evaluación de validación sobre subperíodos futuros. Las medidas de inflación a
combinarse son generadas con la configuración `config` de tipo
[`CrossEvalConfig`](@ref), así como los parámetros de simulación y los períodos
de evaluación.

El diccionario `crossvaldata` contiene las trayectorias de inflación, la
trayectoria paramétrica y las fechas de cada período de combinación y
evaluación. El diccionario `crossvaldata` es producido por [`makesim`](@ref)
para un `CrossEvalConfig`. Se hace de esta forma para que las trayectorias de
inflación estén precomputadas, ya que sería muy costoso generarlas al vuelo. 

La función `weightsfunction` recibe una tupla `(tray_infl, tray_param)` y
obtiene ponderaciones de combinación para las medidas en `tray_infl`. Por
ejemplo, se puede utilizar directamente la función
[`combination_weights`](@ref), o una función anónima construida con
[`ridge_combination_weights`](@ref) o [`lasso_combination_weights`](@ref).

Los parámetros opcionales son:  
- `show_status::Bool = true`: muestra información sobre cada período de ajuste
  de ponderadores (subperíodo de entrenamiento) y resultados de las métricas en
  los subperíodos de validación.
- `print_weights::Bool = true`: indica si se deben imprimir los vectores de
  ponderaciones obtenidos en cada iteración de entrenamiento y evaluación.
- `return_weights::Bool = false`: indica si se devuelve el vector de ponderación
  del último período.
- `metrics::Vector{Symbol} = [:mse]`: vector de métricas a reportar en cada
  iteración de entrenamiento y evaluación. Las métricas son obtenidas por
  [`eval_metrics`](@ref).
- `train_start_date::Date = Date(2000, 12)`: fecha de inicio para el subperíodo
  de los datos de entrenamiento sobre el cual se obtienen los ponderadores de
  combinación.
- `components_mask = (:)`: máscara a aplicar sobre las columnas de `tray_infl`
  en la combinación y evaluación. Utilizado para excluir una o más medidas del
  proceso de evaluación.
- `add_intercept::Bool = false`: indica si se debe agregar una columna de unos
  en las trayectorias de inflación a combinar. Si el `ensemblefn` de `config`
  contiene una [`InflationConstant`](@ref) como primera entrada, este argumento
  no es necesario. Utilizado para obtener un intercepto en la combinación lineal
  de trayectorias de inflación y que los ponderadores obtenidos de la
  combinación representen variaciones alrededor de este intercepto.
"""
function crossvalidate(
    crossvaldata::Dict{String}, config::CrossEvalConfig, weightsfunction::Function; 
    show_status::Bool = true,
    print_weights::Bool = true, 
    return_weights::Bool = false,
    metrics::Vector{Symbol} = [:mse], 
    train_start_date::Date = Date(2000, 12), 
    components_mask = Colon(), 
    add_intercept::Bool = false) 

    local w
    folds = length(config.evalperiods)
    cv_results = zeros(Float32, folds, length(metrics))

    # Obtener parámetro de inflación 
    for (i, evalperiod) in enumerate(config.evalperiods)
    
        @debug "Ejecutando iteración $i de validación cruzada" evalperiod 

        # Obtener los datos de entrenamiento y validación 
        traindate = evalperiod.startdate - Month(1)
        cvdate = evalperiod.finaldate
        
        train_tray_infl = crossvaldata[_getkey("infl", traindate)]
        train_tray_infl_param = crossvaldata[_getkey("param", traindate)]
        train_dates = crossvaldata[_getkey("dates", traindate)]
        cv_tray_infl = crossvaldata[_getkey("infl", cvdate)]
        cv_tray_infl_param = crossvaldata[_getkey("param", cvdate)]
        cv_dates = crossvaldata[_getkey("dates", cvdate)]

        # Si se agrega intercepto, agregar 1's a las trayectorias. Esto puede
        # alterar el significado de components_mask
        if add_intercept
            train_tray_infl = _add_ones(train_tray_infl)
            cv_tray_infl = _add_ones(cv_tray_infl)
        end

        # Máscara de períodos para ajustar los ponderadores. Los ponderadores se
        # ajustan a partir de train_start_date
        weights_train_mask = train_dates .>= train_start_date

        # Obtener ponderadores de combinación lineal con weightsfunction 
        w = @views weightsfunction(
            train_tray_infl[weights_train_mask, components_mask, :], 
            train_tray_infl_param[weights_train_mask])

        # Máscara de períodos de evaluación 
        mask = evalperiod.startdate .<= cv_dates .<= evalperiod.finaldate

        # Obtener métrica de evaluación en subperíodo de CV 
        cv_metrics = @views combination_metrics(
            cv_tray_infl[mask, components_mask, :], 
            cv_tray_infl_param[mask], 
            w)
        cv_results[i, :] = get.(Ref(cv_metrics), metrics, 0)

        show_status && @info "Evaluación ($i/$folds):" train_start_date evalperiod traindate cv_results[i]
        print_weights && println(w)
    
    end

    # Retornar ponderaciones si es seleccionado 
    return_weights && return cv_results, w
    # Retornar métricas de validación cruzada
    cv_results
end


function _getkey(prefix, date) 
    fmt = dateformat"yy" 
    prefix * "_" * Dates.format(date, fmt)
end

# Agrega intercepto al cubo de trayectorias en la primera columna 
function _add_ones(tray_infl)
    T, _, K = size(tray_infl)
    hcat(ones(eltype(tray_infl), T, 1, K), tray_infl)
end