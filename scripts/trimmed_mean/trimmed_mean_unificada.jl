using Base: parameter_upper_bound
using DrWatson
@quickactivate "HEMI"

## Cargar el módulo de Distributed para computación paralela
using Distributed
# Agregar procesos trabajadores
addprocs(4, exeflags="--project")

# Cargar los paquetes utilizados en todos los procesos
@everywhere using HEMI

gtdata_eval         = gtdata[Date(2020, 12)]
gtdata_eval_legacy  = gtdata[Date(2019, 12)]
Dates_gtdata        = Date("2001-12-01"):Month(1):Date("2021-06-01")
Dates_eval          = Date("2001-12-01"):Month(1):Date("2020-12-01")
Dates_legacy        = Date("2001-12-01"):Month(1):Date("2019-12-01")
N_iter_1 = 10_000
N_iter_2 = 125_000
trendfn = TrendRandomWalk()


LIST = [[gtdata_eval, InflationTrimmedMeanEq, ResampleSBB(36), N_iter_1, ParamTotalCPIRebase, LinRange(20,60,41), LinRange(60,100,41)],
        [gtdata_eval, InflationTrimmedMeanEq, ResampleScrambleVarMonths(), N_iter_1, ParamTotalCPIRebase, LinRange(30,70,41), LinRange(60,100,41)],
        [gtdata_eval, InflationTrimmedMeanWeighted, ResampleSBB(36), N_iter_1, ParamTotalCPIRebase, LinRange(18,58,41), LinRange(60,100,41)],
        [gtdata_eval, InflationTrimmedMeanEq, ResampleScrambleVarMonths(), N_iter_1, ParamTotalCPIRebase, LinRange(0,40,41), LinRange(60,100,41)],
        [gtdata_eval_legacy, InflationTrimmedMeanEq, ResampleScrambleVarMonths(), N_iter_1, ParamTotalCPILegacyRebase, LinRange(30,70,41), LinRange(60,100,41)],
        [gtdata_eval_legacy, InflationTrimmedMeanWeighted, ResampleScrambleVarMonths(), N_iter_1, ParamTotalCPILegacyRebase,  LinRange(0,40,41), LinRange(60,100,41)]
]

using Plots
using Optim
using LaTeXStrings
using CSV

function evalperc(k, inflationfunction,resamplefn, trendfn, evaldata; K = 10_000, lb=[0.0,0.0],ub=[100.0,100.0])
    # Crear configuración de evaluación
    if lb[1]<k[1]<ub[1] && lb[2]<k[2]<ub[2]
    evalconfig = SimConfig(
        inflfn = inflationfunction(k),
        resamplefn = resamplefn, 
        trendfn = trendfn, 
        nsim = K)

    # Evaluar la medida y obtener el MSE
    results, _ = makesim(evaldata, evalconfig, rndseed=0)
    mse = results[:mse]
    return mse
    end
    return 1_000_000_000
end

OUT = Dict()
for k in 1:length(LIST)
     dataeval   = LIST[k][1]
     resamplefn = LIST[k][3]
     savepath   = datadir("Trimmed_Mean",string(LIST[k][2]),string(LIST[k][3]),string(LIST[k][4]),string(LIST[k][5]))
     plotname   = string(LIST[k][2])*"_"*string(LIST[k][3])*"_"*string(LIST[k][4])*"_"*string(LIST[k][5])*".png"
     plotname2  = string(LIST[k][2])*"_"*string(LIST[k][3])*"_N="*string(LIST[k][4])*"_"*string(LIST[k][5])*".svg"
     plottitle  = string(LIST[k][2])*", "*string(LIST[k][3])*"\n N="*string(LIST[k][4])*", "*string(LIST[k][5])
     
     sims = Vector{Dict{Symbol,Any}}()
     rango_inf = LIST[k][6]
     rango_sup = LIST[k][7]
     ARRAY = []
     for i in rango_inf
         for j in rango_sup
            if j>i
             inflfn  = LIST[k][2](i,j)
             config  = SimConfig(inflfn, resamplefn, trendfn, N_iter_1)
             #dict    = struct2dict(config) 
             #push!(sims,dict)
             z = evalsim(dataeval, config; param_constructor_fn=LIST[k][5], rndseed = 0)[1][:mse]
             push!(ARRAY,(i,j,z))
            else
                push!(ARRAY,(i,j,NaN))   
            end
         end
     end

     #run_batch(dataeval, sims, savepath; savetrajectories=false, 
     #           param_constructor_fn=LIST[k][5], rndseed = 0)
    
    #df          = collect_results(savepath)
    #sorted_df   = sort(df, "mse")
    #X = [x[1] for x in df[!,:params]]
    #Y = [x[2] for x in df[!,:params]]
    #Z = [x for x in df[!,:mse]]

    #ARRAY = collect(zip(X,Y,Z))
    sort!(ARRAY,by=x->x[2])
    sort!(ARRAY,by=x->x[1])
    ARRAY2 = reshape(ARRAY,length(rango_sup),length(rango_inf)) 
    MATRIX = [x[3] for x in ARRAY2]
    ARRAY3 = sort(ARRAY, by=x->x[3])
    
    plot1 = heatmap(rango_inf,
            rango_sup, 
            1 ./ MATRIX, 
            title  = "1/MSE"*"\n"*plottitle,
            xlabel = L"\ell_1", 
            ylabel = L"\ell_2",
            size   = (600,400),
            titlefontsize = 10
            )
    scatter!((ARRAY3[1][1],ARRAY3[1][2]),
            label="Optimo = ("*string(Float64(ARRAY3[1][1]))
                    *", "*string(Float64(ARRAY3[1][2]))
                    *")\n MSE="*string(ARRAY3[1][3]),
            legend = :bottomleft)
    savefig(plot1, plotsdir("Trimmed_Mean", plotname))
    savefig(plot1, plotsdir("Trimmed_Mean", plotname2))

initial_params = [ARRAY3[1][1], ARRAY3[1][2]]
lower_b = [max(initial_params[1]-10,0.0f0), max(initial_params[2]-10,0.0f0)]
upper_b = [min(initial_params[1]+10,100.0f0), min(initial_params[2]+10,100.0f0)]

f = x -> evalperc(x, LIST[k][2], resamplefn, trendfn, gtdata_eval; K = N_iter_2, lb=lower_b, ub=upper_b)
optres = optimize(f, lower_b, upper_b, initial_params, NelderMead(), Optim.Options(iterations=100, g_tol=1.0e-3))
min_mse = optres.minimum
min_params = optres.minimizer
nombre = measure_name(LIST[k][2](min_params))
OUT[nombre]=min_mse
CSV.write(datadir("Trimmed_Mean","Resultados.csv"),OUT)
end

