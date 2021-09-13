"""
    grid_batch(data, inflfn, resamplefn, trendfn, N::Int, 
                    l1_range, l2_range, paramfn, traindate::Date;
                    savetrajectories = false, save_dir = "")

Ejecuta `run_batch` de MediaTruncada(l1,l2) ∀ l1 ϵ l1-range,
l2 ϵ l2-range donde l1<l2
# Ejemplo: 
```
grid_batch(gtdata,InflationTrimmedMeanEq, ResampleScrambleVarMonths(), 
    TrendRandomWalk(),10_000, 10:20, 90:99,InflationTotalRebaseCPI(36,2),
    Date(2020,12); 
    save_dir = joinpath("results","InflationTrimmedMeanEq","Esc-B")
    )
```
"""
function grid_batch(data, inflfn, resamplefn, trendfn, N::Int, 
                    l1_range, l2_range, paramfn, traindate::Date;
                    savetrajectories = false, save_dir="")

                    sims = Dict(
                        :inflfn => inflfn.([(x,y) for x in l1_range for y in l2_range if x<y]), 
                        :resamplefn => resamplefn, 
                        :trendfn => trendfn ,
                        :paramfn => paramfn,
                        :traindate => traindate,
                        :nsim => N
                    ) |> dict_list

                    dir_name = join(alias_savepath.([inflfn,resamplefn,trendfn,paramfn,N,traindate]),"_")
                    savepath   = datadir(save_dir, dir_name)

                    run_batch(data, sims, savepath; savetrajectories)
                    println("resultados guardados en:")
                    println(savepath)
end


# Función auxiliar para construir el nombre del directorio donde se guardan las simulaciones
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



