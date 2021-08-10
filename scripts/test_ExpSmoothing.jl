# #Pruebas de funciones de media simple y media ponderada

#Carga de paquetes
using DrWatson
@quickactivate "HEMI"
using HEMI

# ##MEDIA MÓVIL
inflfn = InflationExpSmoothing(InflationTotalCPI(), 0.8)
b=inflfn(gtdata)

# Diferentes parámetros de suavizamiento exponencial 

alphas = 0:0.1:1
tray_infl = mapreduce(hcat, alphas) do alpha 
    inflfn = InflationExpSmoothing(InflationTotalCPI(), alpha)
    inflfn(gtdata) 
end 

# Gráfica de ejemplo 
using Plots

plot(infl_dates(gtdata), tray_infl, label = alphas')
