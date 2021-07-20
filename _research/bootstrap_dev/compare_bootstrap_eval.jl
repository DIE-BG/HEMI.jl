# Script de comparación de evaluación con diferentes métodos de remuestreo 
using DrWatson
@quickactivate "bootstrap_dev"

## Cargar datos 
using HEMI
@load projectdir("..", "..", "data", "guatemala", "gtdata32.jld2") gt00 gt10
gtdata = UniformCountryStructure(gt00, gt10)


# Cargar paquetes de remuestreo y evaluación 
using Dates, CPIDataBase
using InflationEvalTools
using InflationFunctions

# Datos hasta dic-20
gtdata_dic20 = gtdata[Date(2020, 12)]

# Computar medida de inflación total 
totalfn = InflationTotalCPI()

totalfn(gtdata_dic20)

# Función de remuestreo Stationary BB
resample_sbb = ResampleSBB(25)

# Función de remuestreo Generalized Seasonal BB
resample_gsbb = ResampleGSBBMod()

## Prueba de remuestreo de CountryStructure
bootsample = resample_sbb(gtdata_dic20)
tray_infl = totalfn(bootsample)
dates = infl_dates(bootsample)
p1 = plot(dates, tray_infl, label="Resample method SBB")


# Prueba con GSBB modificado 
bootsample = resample_gsbb(gtdata_dic20)
tray_infl = totalfn(bootsample)
dates = infl_dates(bootsample)
p2 = plot(dates, tray_infl, label="Resample method GSBB-II")

plot(p1, p2, layout=(2, 1))


## Comparación de tiempos 

#=
using BenchmarkTools

@btime resample_sbb(gtdata_dic20); 
# 246.600 μs (211 allocations: 1.18 MiB)

@btime resample_gsbb(gtdata_dic20);
# 239.200 μs (55 allocations: 1.14 MiB)
=#

## Obtener parámetro de inflación total

# Se muestran gráficas de la trayectoria paramétrica de inflación y una
# realización de remuestreo con cada metodología 

param_cs = param_sbb(gtdata_dic20)
tray_boot_sbb = resample_sbb(gtdata_dic20) |> totalfn
tray_pob_sbb = totalfn(param_cs)
dates = infl_dates(param_cs)

p1 = plot(dates, [tray_pob_sbb tray_boot_sbb], 
    label=["Parámetro SBB" "Remuestreo SBB"], 
    legend=:topleft, 
    ylim=(-2, 15))


param_cs = param_gsbb_mod(gtdata_dic20)
tray_boot_gsbb = resample_gsbb(gtdata_dic20) |> totalfn
tray_pob_gsbb = totalfn(param_cs)
dates = infl_dates(param_cs)

p2 = plot(dates, [tray_pob_gsbb tray_boot_gsbb], 
    label=["Parámetro GSBB" "Remuestreo GSBB"], 
    legend=:topleft, 
    ylim=(-5, 60))

plot(p1, p2, layout=(2, 1))



## Parámetro de inflación total con cambio de base

totalrebasefn = InflationTotalRebaseCPI()

# Se muestran gráficas de la trayectoria paramétrica de inflación con fórmula
# del IPC y cambios de base sintéticos. Además, se muestra una realización de
# remuestreo con cada metodología 

anim = @animate for j in 1:100
    param_cs = param_sbb(gtdata_dic20)
    tray_boot_sbb = resample_sbb(gtdata_dic20) |> totalfn
    tray_pob_sbb = totalrebasefn(param_cs)
    dates = infl_dates(param_cs)

    p1 = plot(dates, [tray_pob_sbb tray_boot_sbb], 
        label=["Parámetro SBB" "Remuestreo SBB"], 
        legend=:topleft, 
        ylim=(-2, 15))


    param_cs = param_gsbb_mod(gtdata_dic20)
    tray_boot_gsbb = resample_gsbb(gtdata_dic20) |> totalfn
    tray_pob_gsbb = totalrebasefn(param_cs)
    dates = infl_dates(param_cs)

    p2 = plot(dates, [tray_pob_gsbb tray_boot_gsbb], 
        label=["Parámetro GSBB" "Remuestreo GSBB"], 
        legend=:topleft, 
        ylim=(-5, 60))

    plot(p1, p2, layout=(2, 1))

end

params = (param="ipc_cb",)
path = mkpath(plotsdir("bootstrap_methods", "eval_sbb_gsbbmod"))
anim_path = joinpath(path, savename("resample_total_sbb_gsbbmod", params, "gif"))
# mp4(anim, anim_path, fps=10)
gif(anim, anim_path, fps=5)



## Animación de remuestreo utilizando percentil 67

# Función de remuestreo Stationary BB
resample_sbb = ResampleSBB(25)
# Función de inflación para trayectoria paramétrica
totalrebasefn = InflationTotalRebaseCPI()
# Función de inflación de estimador muestral 
percfn = InflationPercentileEq(67)


anim = @animate for j in 1:100
    param_cs = param_sbb(gtdata_dic20)
    tray_boot_sbb = resample_sbb(gtdata_dic20) |> percfn
    tray_pob_sbb = totalrebasefn(param_cs)
    dates = infl_dates(param_cs)

    p1 = plot(dates, [tray_pob_sbb tray_boot_sbb], 
        label=["Parámetro SBB" "Remuestreo SBB"], 
        legend=:topleft, 
        ylim=(-2, 15))


    param_cs = param_gsbb_mod(gtdata_dic20)
    tray_boot_gsbb = resample_gsbb(gtdata_dic20) |> percfn
    tray_pob_gsbb = totalrebasefn(param_cs)
    dates = infl_dates(param_cs)

    p2 = plot(dates, [tray_pob_gsbb tray_boot_gsbb], 
        label=["Parámetro GSBB" "Remuestreo GSBB"], 
        legend=:topright, 
        ylim=(-5, 15))

    plot(p1, p2, layout=(2, 1))

end

params = (param="ipc_cb",)
path = mkpath(plotsdir("bootstrap_methods", "eval_sbb_gsbbmod"))
anim_path = joinpath(path, savename("resample_perc_sbb_gsbbmod", params, "gif"))
# mp4(anim, anim_path, fps=10)
gif(anim, anim_path, fps=5)