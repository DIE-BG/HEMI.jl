using Base: parameter_upper_bound
using DrWatson
@quickactivate "HEMI"

## Cargar el módulo de Distributed para computación paralela
using Distributed
# Agregar procesos trabajadores
addprocs(4, exeflags="--project")

# Cargar los paquetes utilizados en todos los procesos
@everywhere using HEMI

function grid_batch(data, inflfn, resamplefn, trendfn, N::Int, 
                    l1_range, l2_range, paramfn, traindate::Date;
                    savetrajectories = false)

                    sims = Dict(
                        :inflfn => inflfn.([(x,y) for x in l1_range for y in l2_range if x<y]), 
                        :resamplefn => resamplefn, 
                        :trendfn => trendfn ,
                        :paramfn => paramfn,
                        :traindate => traindate,
                        :nsim => N
                    ) |> dict_list

                    dir_name = join(alias_savepath.([inflfn,resamplefn,trendfn,paramfn,N,traindate]),"_")
                    savepath   = datadir("Trimmed_Mean", dir_name)

                    run_batch(data, sims, savepath; savetrajectories)
end


function alias_savepath(x)
    if x == InflationTrimmedMeanEq
        return "MTEq"
    elseif x == InflationTrimmedMeanWeighted
        return "MTW"
    elseif x == ResampleSBB(36)
        return "SBB36"
    elseif x== ResampleScrambleVarMonths()
        return "SVM"
    elseif x== TrendRandomWalk()
        return "RW"
    elseif x== InflationTotalRebaseCPI(60)
        return "Rebase60"
    elseif x== InflationTotalRebaseCPI(36,2)
        return "Rebase36"
    elseif typeof(x)==Int
        return "N$x"
    elseif typeof(x)==Date
        return string(x)[1:end-3]
    else 
        return string(x)
    end
end


# EJEMPLO: 
#grid_batch(gtdata,InflationTrimmedMeanEq, ResampleSBB(36), TrendRandomWalk(),499, 10:20, 97:99,InflationTotalRebaseCPI(36,2),Date(2020,12))


