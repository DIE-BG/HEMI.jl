# En este script se realiza un ejercicio de remuestreo de índices para analizar
# la uniformidad del muestreo de la función ResampleScrambleVarMonths. 

# Se determinó que la primera versión implementada no generaba de manera
# uniforme el muestreo de índices, asignando mayor probabilidad de ocurrencia a
# los últimos mismos meses en cada muestreo. Después de modificar apropiadamente
# el método scramblevar de la función ResampleScrambleVarMonths, se corrigió
# este "bug estadístico". 

using DrWatson
@quickactivate "HEMI"

using Distributed
addprocs(4, exeflags="--project")
@everywhere using HEMI

## Otras librerías 
using Plots
using StatsBase 
using Distributions 

## Ejemplo para revisar función de remuestreo 
# Se crean datos artificiales que representan los números de índices para remuestrearse.
t = repeat(1:120, 1, 218)
dates = Date(2000, 12) : Month(1) : Date(2000,12) + Month(120-1)
fictbase = VarCPIBase(convert.(Float32, t), rand(Float32, 218), dates, 100f0)
fictdata = UniformCountryStructure(fictbase)

# Función de remuestreo 
resamplefn = ResampleScrambleVarMonths() 

# Función de inflación ficticia para obtener índices de remuestreo: se define
# esta función de inflación ficticia, que devuelve únicamente los índices
# remuestreados, para detectar la uniformidad a lo largo de la serie de tiempo.
# En lugar de devolver la trayectoria de inflación, devuelve los datos de la
# primera columna 

@everywhere begin 

    struct FictInflationIndexes <: InflationFunction end 

    function (::FictInflationIndexes)(cs::CountryStructure) 
        # Retornar los índices remuestreados 
        first(cs.base).v[1:109]
    end
end 

idsinflfn = FictInflationIndexes()

## Obtener distribución de índices de remuestreo 
# Se obtienen los índices de remuestreo con la función ficticia. Se obtienen K
# realizaciones y posteriormente se analiza la frecuencia de remuestreo de cada
# uno de los posibles índices 

K = 10000
bootids = pargentrayinfl(idsinflfn, resamplefn, TrendIdentity(), fictdata, K=K)

## Analizar la distribución de índices del primer período 

# Se obtienen los índices de remuestreo del período indicado 
period1 = convert.(Int, bootids[109, :, :]) |> vec
# Se convierten al número de mes remuestreado (de 0 a 9)
catdata = @. (period1 - mod(period1, 12)) / 12 

# Se obtienen las cuentas de cada número de mes para ver la frecuencia de los índices 
countids = countmap(period1)
ids = [keys(countids)...] |> sort
phat = [countids[ids[i]] / K for i in 1:10]

# Graficar 
b1 = bar(ids, phat, xticks=ids, label=false)    
display(b1)

# Distribución uniforme 
p0 = ones(10) / 10

# Prueba Chi-cuadrada para ver si los datos vienen de una uniforme
n = K
Tn = n*sum(((phat - p0) .^ 2) ./ p0) # ~ Chisq(9) 
pval = 1 - cdf(Chisq(9), Tn)

## Realizar una prueba de hipótesis Chi-cuadrada contra la distribución uniforme

# Se hace una función de ayuda en la parte inferior del script. Este resultado
# debe ser el mismo que el de la sección anterior
chisquare_uniform_test(bootids, 109) 

## Realizar la prueba en todos los períodos 

# Obtenemos el valor p para todos los períodos
pvals = map(i -> chisquare_uniform_test(bootids, i), 1:109) 

# Vemos el porcentaje de períodos en los cuales se rechaza la hipótesis nula,
# con el nivel de significancia dado 
mean(pvals .< 0.01) 

plot(pvals, label="Valores p, prueba Chi-cuadrada", xlabel="Período")
hline!([0.05], label=:false)



## Función para obtener valores p de la prueba de bondad de ajuste
# Chi-cuadrada 
# H0: los datos se distribuyen con la uniforme 
# H1: no se distribuyen uniformemente
function chisquare_uniform_test(bootids, i) 
    perioddata = vec(convert.(Int, bootids[i, :, :]))
    
    offset = mod(perioddata[1], 12)
    catdata = @. (perioddata - offset) ÷ 12
    ncat = length(unique(catdata))

    # Proporciones estimadads en la muestra
    nsample = size(bootids, 3)
    countids = countmap(perioddata)
    ids = [keys(countids)...] |> sort
    phat = [countids[ids[i]] / K for i in 1:ncat]
    
    # distribución uniforme
    p0 = ones(ncat) / ncat
    
    # Estadístico de prueba 
    Tn = nsample * sum(((phat - p0) .^ 2) ./ p0) # ~ Chisq(ncat-1) 
    
    pval = 1 - cdf(Chisq(ncat-1), Tn)
    pval
end 
