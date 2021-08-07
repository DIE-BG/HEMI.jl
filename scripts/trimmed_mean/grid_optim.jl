using Base: parameter_upper_bound
using DrWatson
@quickactivate "HEMI"
using Distributed
addprocs(4, exeflags="--project")
@everywhere using HEMI
using Optim
using DataFrames

dir_list    = ["MTEq_SBB36_RW_N10000_Rebase(60)_2020-12",
               "MTEq_SVM_RW_N10000_Rebase(60)_2020-12",
               "MTW_SBB36_RW_N10000_Rebase(60)_2020-12",
               "MTW_SVM_RW_N10000_Rebase(60)_2020-12",
               "MTEq_SVM_RW_N10000_Rebase(36,2)_2019-12",
               "MTW_SVM_RW_N10000_Rebase(36,2)_2019-12",
]

dir = "MTEq_SVM_RW_Rebase36_N999_2019-12"

function grid_optim(dir_name, data, N::Int64, radius, measure=:mse)
                savepath    = datadir("Trimmed_Mean", dir_name)
                df          = collect_results(savepath)
                condition   =  measure==:corr   
                sorted_df   = sort(df,measure, rev=condition)
                min_params  = sorted_df[1,:params]
                inflfn      = typeof(sorted_df[1,:inflfn])
                resamplefn  = sorted_df[1,:resamplefn]
                trendfn     = sorted_df[1,:trendfn]
                paramfn     = sorted_df[1,:paramfn]
                traindate   = sorted_df[1,:traindate]
                initial_params = [min_params[1], min_params[2]]
                lower_b     = [max(initial_params[1]-radius,0.0f0), max(initial_params[2]-radius,0.0f0)]
                upper_b     = [min(initial_params[1]+radius,100.0f0), min(initial_params[2]+radius,100.0f0)]
                f = x -> evalperc(x, inflfn, resamplefn, trendfn, data, paramfn, traindate; K = N, measure,lb=lower_b, ub=upper_b)
                optres = optimize(f, lower_b, upper_b, initial_params, NelderMead(), Optim.Options(iterations=100, g_tol=1.0e-3))
                min_measure = optres.minimum
                min_params = optres.minimizer
                return [inflfn, min_params, min_measure*(-1)^Int(condition), resamplefn,trendfn , paramfn, N, traindate, measure]

end


function evalperc(k, inflfn ,resamplefn, trendfn, evaldata, paramfn , traindate ; K = 10_000, measure=:mse,lb=[0.0,0.0],ub=[100.0,100.0])
    # Crear configuración de evaluación
    if k[1]< k[2]
        if lb[1]<k[1]<ub[1] && lb[2]<k[2]<ub[2]
        evalconfig = SimConfig(
            inflfn = inflfn(k),
            resamplefn = resamplefn, 
            trendfn = trendfn, 
            paramfn = paramfn,
            nsim = K,
            traindate = traindate)

        # Evaluar la medida y obtener el MSE
        results, _ = makesim(evaldata, evalconfig)
        out = results[measure]
        return out*(-1)^Int(measure==:corr)
        end
    end
    return 1.0e5
end



#Ejemplo

#grid_optim(dir, gtdata,10000,4, :mse)

#g = x -> grid_optim(x, gtdata,1000,4, :mse)
#g.(dir_list)