# #Pruebas de funciones de media simple y media ponderada

#Carga de paquetes
using DrWatson
@quickactivate "HEMI"
using HEMI

# ##MEDIA MÓVIL
inflfn = InflationExpSmoothing(InflationTotalCPI(), 0.8)
b=inflfn(gtdata)

# names(Main)[4:end]
# varinfo()