using DrWatson
@quickactivate "HEMI"

using Distributed
# Agregar procesos trabajadores
nprocs() < 5 && addprocs(4, exeflags="--project")
# Cargar los paquetes utilizados en todos los procesos
@everywhere using HEMI


data_loadpath = datadir("results", "no_trans", "data", "NOT_data.jld2")
NOT_GTDATA = load(data_loadpath, "NOT_GTDATA")

########################
#### GTDATA_EVAL #######
########################

gtdata_eval = NOT_GTDATA[Date(2021, 12)]

#########################################################################################
############# DEFINIMOS PARAMETROS ######################################################
#########################################################################################

# PARAMETRO HASTA 2021
param = InflationParameter(
    InflationTotalRebaseCPI(36, 2), 
    ResampleScrambleVarMonths(), 
    TrendRandomWalk()
)

# PARAMETRO HASTA 2019 (para evaluacion en periodo de optimizacion de medidas individuales)
param_2019 = InflationParameter(
    InflationTotalRebaseCPI(36, 2), 
    ResampleScrambleVarMonths(), 
    TrendRandomWalk()
)

# TRAYECOTRIAS DE LOS PARAMETROS 
tray_infl_pob      = param(gtdata_eval)
tray_infl_pob_19   = param_2019(gtdata_eval[Date(2019,12)])

#############################################################################
#############################################################################

a = Date(2011,01)
b = Date(2011,11)

c = Date(2015,01)
d = Date(2015,11)

c2 = Date(2018,01)
d2 = Date(2018,11)

perc1 = InflationPercentileEq(72)
perc2 = InflationTrimmedMeanEq(20,95)
perc3 = InflationPercentileEq(78)
perc4 = InflationPercentileEq(70)

f=[perc1,perc2,perc3,perc4]
dates = [[a,b],[c,d], [c2,d2]]
X = CPIDataBase.cpi_dates(gtdata)


F = CPIDataBase.ramp_down(X,dates[1]...)
G = CPIDataBase.ramp_up(X,dates[1]...)
OUT = f[1](gtdata,CPIVarInterm()) .* F + f[2](gtdata,CPIVarInterm()) .* G

for i in 2:length(dates)
F = CPIDataBase.ramp_down(X,dates[i]...)
G = CPIDataBase.ramp_up(X,dates[i]...)
OUT = OUT .* F 
OUT = OUT + f[i+1](gtdata,CPIVarInterm()) .* G
end


W = Splice([perc1, perc2], [(a, b)])


############################################


config = SimConfig(
    inflfn = perc2,
    resamplefn = ResampleScrambleVarMonths(),
    trendfn = TrendRandomWalk(),
    paramfn = InflationTotalRebaseCPI(36, 2),
    nsim = 100,
    traindate = Date(2021,12),
)

results, tray_infl = makesim(gtdata_eval, config)



config = Dict(
    :paramfn => InflationTotalRebaseCPI(36, 2),
    :resamplefn => ResampleScrambleVarMonths(),
    :trendfn => TrendRandomWalk(),
    :traindate => Date(2021, 12),
    :nsim => 100,
    :inflfn => W
)


function run_batch_splice(data, dict_list_params, splice; 
    savetrajectories = true, 
    rndseed = InflationEvalTools.DEFAULT_SEED)
    a = splice.a
    b = splice.b

    X = infl_dates(data)
    F = ff(X,a,b)
    G = ramp_down(X,a,b)

    TRAY = Dict()


    # Ejecutar lote de simulaciones 
    for (i, dict_params) in enumerate(dict_list_params)
        @info "Ejecutando simulación $i de $(length(dict_list_params))..."
        config = dict_config(dict_params)
        results, TRAY[string(i)] = makesim(data, config;
            rndseed = rndseed)
        print("\n\n\n") 
        
        # Guardar los resultados 
        #filename = savename(config, "jld2")
        
        # Resultados de evaluación para collect_results 
        #wsave(joinpath(savepath, filename), tostringdict(results))
        
        # Guardar trayectorias de inflación, directorio tray_infl de la ruta de guardado
        #savetrajectories && wsave(joinpath(savepath, "tray_infl", filename), "tray_infl", tray_infl)
    end

    tray_infl = TRAY["1"] .* F + TRAY["2"] .* G
    tray_infl

end


