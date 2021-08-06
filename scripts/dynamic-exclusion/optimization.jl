# # Optimización

using Optim
using DrWatson

@quickactivate "HEMI"

# Cargar el módulo de Distributed para computación paralela
using Distributed

# Agregar procesos trabajadores
addprocs(4, exeflags="--project")

# Cargar los paquetes utilizados en todos los procesos
@everywhere using HEMI

# ## Parametros globales

DATA = gtdata

LOWER_B = [0f0, 0f0]
UPPER_B = [3f0, 3f0]

PARAM_0 = [0.42424244f0, 1.5151515f0]

F_TOL = 1e-6

SAVEPATH = datadir("results", "dynamic-exclusion", "optimization")

# ## Variantes de optimización

optim_variants = Dict(
    :inflfn => vecParameters -> InflationDynamicExclusion(vecParameters),
    :resamplefn => [ResampleScrambleVarMonths(), ResampleSBB(36)], 
    :trendfn => TrendRandomWalk(),
    :paramfn => [InflationTotalRebaseCPI(36, 2), InflationWeightedMean()],
    :nsim => 100,
    :traindate => [Date(2019, 12), Date(2020, 12)]
) |> dict_list

# ## Optimización de variantes
for variant in optim_variants

    function mse_variant(vecParameters)

        # Crea configuración de evaluación
        sim_config = SimConfig(
            inflfn = variant[:inflfn](vecParameters),
            resamplefn = variant[:resamplefn], 
            trendfn = variant[:trendfn], 
            paramfn = variant[:paramfn],
            nsim = variant[:nsim],
            traindate = variant[:traindate]
        )

        # Evalua la medida y obtiene el MSE
        if all(LOWER_B .< vecParameters .< UPPER_B)
            results, _ = makesim(DATA, sim_config)
            mse = results[:mse]
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
            f_tol = F_TOL
        )
    )

    println(optres)
    @info "Resultados de optimización:" min_mse=minimum(optres) minimizer=Optim.minimizer(optres)  iterations=Optim.iterations(optres)

    # Guardar los resultados 
    variant[:inflfn] = variant[:inflfn](Optim.minimizer(optres))
    filename = savename(dict_config(variant), "jld2")
            
    # Resultados de evaluación para collect_results 
    save(joinpath(SAVEPATH, filename), Dict("optres" => optres))

end




