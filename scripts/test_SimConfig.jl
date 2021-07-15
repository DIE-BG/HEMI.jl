# # Script de prueba para tipos que especifican variantes de simulación
using DrWatson
@quickactivate "HEMI"

# ## Cargamos paquete de evaluación
using HEMI


## Obtener un ejemplo 
# Parámetros de simulación
totalfn = InflationTotalCPI()
resamplefn = ResampleSBB(36)
trendfn = TrendRandomWalk()
percEq = InflationPercentileEq(80)
ff = Date(2020, 12)
sz = 24
# Exclusión Fija
excOpt00 = [35,30,190,36,37,40,31,104,162,32,33,159,193,161]
excOpt10 = [29,31,116,39,46,40,30,35,186,47,197,41,22,48,185,34,184]
fxEx = InflationFixedExclusionCPI(excOpt00, excOpt10)

## Crear una configuración de pruebaa 
configA = SimConfig(totalfn, resamplefn, trendfn, 10000)
configB = CrossEvalConfig(totalfn, resamplefn, trendfn, 1000, ff, sz)
configC = SimConfig(fxEx, resamplefn, trendfn, 10000)
configD = SimConfig(percEq, resamplefn, trendfn, 10000)
## Mostrar el nombre generado por la configuración 
savename(configA, connector=" | ", equals=" = ")
savename(configB, connector=" | ", equals=" = ")
savename(configC, connector=" | ", equals=" = ")

## Conversión de AbstractConfig a Diccionario

dic_a = struct2dict(configA)
dic_b = struct2dict(configB)
dic_c = struct2dict(configC)

# Datos hasta diciembre 2020
gtdata_eval = gtdata[Date(2020, 12)]

evalsim(gtdata_eval, configA)

## Convertir de Diccionario a AbstractConfig

dict_prueba = Dict(
    :inflfn => InflationPercentileEq.(60), 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :nsim => 1000) |> dict_list

dict_pruebaB = Dict(
    :inflfn => totalfn, 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :nsim => 10_000,
    :train_date => ff,
    :eval_size => sz) |> dict_list

dict_pruebaC = Dict(
        :inflfn => fxEx, 
        :resamplefn => resamplefn, 
        :trendfn => trendfn,
        :nsim => 1000) |> dict_list

sims = vcat(dict_prueba, dict_pruebaC)

# Función dict_config para pasar de Diccionario a AbstractConfig
    configD_a = dict_config(dict_prueba)
    configC_a = dict_config(dict_pruebaC)
    configE = dict_config(dict_pruebaB)

# Función MakeSim recibe un AbstractConfig
    dict_out, tray_inflacion = makesim(gtdata_eval, dict_config(dict_prueba))
    dict_out


## Pruebas para run_batch
sims = vcat(dict_prueba, dict_pruebaC)
savepath = "C:\\Users\\MJGM\\Desktop\\prueba"
savepath2 = "C:\\Users\\MJGM\\Desktop\\prueba2"
## recibe sims

## Estructura para run_batch
for (i, params) in enumerate(sims)
    @info "Ejecutando simulación $i..."
    config = dict_config(params) 
    dict_out, tray_infl = makesim(gtdata_eval, config)

    # Guardar los resultados 
    filename = savename(config, "jld2", connector=" - ", equals=" = ")
    # Results para collect_results 
    wsave(joinpath(savepath, filename), tostringdict(dict_out))
    # Trayectorias de inflación (ojo con la carpeta)
    #wsave(joinpath(savepath2, filename), struct2dict(tray_infl))
    wsave(joinpath(savepath2, filename),"tray_infl", tray_infl)


end 

df = collect_results(savepath)
#df2 = collect_results(savepath2)