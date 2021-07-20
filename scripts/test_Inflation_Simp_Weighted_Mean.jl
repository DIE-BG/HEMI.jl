# #Pruebas de funciones de media simple y media ponderada

#Carga de paquetes
using DrWatson
@quickactivate :HEMI
using InflationFunctions

# ##MEDIA SIMPLE

simplemeanfn = InflationSimpleMean()
simplemeanfn(gtdata)

# ##MEDIA PONDERADA 

weightedmeanfn = InflationWeightedMean()
a=weightedmeanfn(gt10)
t = weightedmeanfn(gtdata)

