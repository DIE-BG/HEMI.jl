using DrWatson
@quickactivate "HEMI"

## TODO 
# Replicación de resultados para percentiles o una medida sencilla 
# Generación de slicing de fechas para CountryStructure

## Configuración de procesos
using Distributed
addprocs(4, exeflags="--project")

@everywhere begin 
    using Dates, CPIDataBase
    using InflationFunctions
    using InflationEvalTools
end

# Carga de librerías 
using JLD2

# Carga de datos
@load datadir("guatemala", "gtdata32.jld2") gt00 gt10
gtdata = UniformCountryStructure(gt00, gt10)

T = 108
gt10s = VarCPIBase(gt10.v[1:T, :], gt10.w, gt10.fechas[1:T], gt10.baseindex)
gtdata = UniformCountryStructure(gt00, gt10s)

# Computar inflación de Guatemala
totalfn = TotalCPI()
perk70 = Percentil(0.72)
totalfneval = TotalEvalCPI()

## Carga parámetro

@load datadir("param", "gt_param_ipc_cb.jld2") tray_infl_pob
tray_infl_pob = tray_infl_pob[1:120+108-11]

## Trayectorias y MSE

using Statistics

tray_infl = pargentrayinfl(perk70, gtdata; rndseed = 161803, K=250_000);

mse_dist = mean((tray_infl .- tray_infl_pob) .^ 2; dims=1) |> vec 
mse = mean( (tray_infl .- tray_infl_pob) .^ 2 )
rmse = sqrt(mse)

me = mean((tray_infl .- tray_infl_pob))

std(mse_dist)
std(mse_dist) / 125_000

## Gráfica de trayectorias promedio 
using Plots

m_tray_infl = mean(tray_infl; dims=3) |> vec 
plot(Date(2001, 12):Month(1):Date(2019, 12), 
    m_tray_infl, label = "Trayectoria promedio")
plot!(Date(2001, 12):Month(1):Date(2019, 12), 
    tray_infl_pob, label = "Trayectoria paramétrica")