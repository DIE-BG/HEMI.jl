# # Optimización

using Optim
using DrWatson
using DataFrames

@quickactivate "HEMI"

# Cargar el módulo de Distributed para computación paralela
using Distributed

# Agregar procesos trabajadores
addprocs(4, exeflags="--project")

# Cargar los paquetes utilizados en todos los procesos
@everywhere using HEMI

# ## Parámetros globales

# Datos para la evaluación de tipo ``CountryStructure``.
DATA = gtdata

# Tipo de función a evaluar.
INFLATION_FUNCTION_TYPE = InflationDynamicExclusion

# Directorio para el almacenamiento de resultados.
SAVEPATH = datadir("results", "dynamic-exclusion", "optimization")

# Límites de caja para restricción de optimización.
LOWER_B = [0f0, 0f0]
UPPER_B = [3f0, 3f0]

# Valor inicial para la optimización.
PARAM_0 = [0.42424244f0, 1.5151515f0]

# Tolerancia en la optimización.
F_TOL = 1e-4

# ## Variantes de optimización

# En esta sección se definen todas las variantes para la optimización. Notar que el campo ``:inflfn`` corresponde a una función anónima, por lo que estas variantes no pueden ser evaluadas de forma inmediata.

optim_variants = Dict(
    :inflfn => vecParameters -> INFLATION_FUNCTION_TYPE(vecParameters),
    :resamplefn => [ResampleScrambleVarMonths(), ResampleSBB(36)], 
    :trendfn => TrendRandomWalk(),
    :paramfn => [InflationTotalRebaseCPI(36, 2), InflationTotalRebaseCPI(60)],
    :nsim => 125_000,
    :traindate => [Date(2019, 12), Date(2020, 12)]
) |> dict_list

# ## Optimización de variantes

# El loop recorre todas las posibles variantes dentro del diccionario creado en la sección anterior.

for variant in optim_variants

    # Pre-computo de parámetro de inflación

    param = InflationParameter(
        variant[:paramfn], 
        variant[:resamplefn], 
        variant[:trendfn]
    )

    tray_infl_param = param(DATA[variant[:traindate]])

    function mse_variant(vecParameters)

        # Evalua la medida y obtiene el MSE. Se deja una condición par promover la optimización dentro de la región delimitada por los límites superiores e inferiores. 
        if all(LOWER_B .< vecParameters .< UPPER_B)
            mse = eval_mse_online(
                variant[:inflfn](vecParameters),
                variant[:resamplefn], 
                variant[:trendfn],
                DATA[variant[:traindate]], 
                tray_infl_param; 
                K = variant[:nsim]
            )
        else
            mse = 1_000_000
        end
        
        return mse
    end

    # Optimización
    optres = optimize(
        mse_variant, # Función
        LOWER_B, UPPER_B, # Límites
        PARAM_0, # Punto inicial
        NelderMead(), # Método
        Optim.Options(
            f_tol = F_TOL,
            show_trace = true
        )
    )

    println(optres)
    @info "Resultados de optimización:" min_mse=minimum(optres) minimizer=Optim.minimizer(optres)  iterations=Optim.iterations(optres)

    # Guardar los resultados. Se evalúa la función anónima con el punto óptimo para el almacenamiento del resultado.
    variant[:inflfn] = variant[:inflfn](Optim.minimizer(optres))
    filename = savename(dict_config(variant), "jld2")
            
    # Guardar los resultados como un diccionario para su fácil exploración.

    optres = @chain Dict(
        :lower_factor => optres.minimizer[1],
        :upper_factor => optres.minimizer[2],
        :mse => optres.minimum
    ) begin
        merge(_, variant)
    end

    # Resultados de evaluación para collect_results 
    wsave(joinpath(SAVEPATH, filename), tostringdict(optres))
end
