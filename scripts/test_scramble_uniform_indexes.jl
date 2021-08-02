using DrWatson
@quickactivate "HEMI"

using Distributed
addprocs(4, exeflags="--project")
@everywhere using HEMI

## Ejemplo para revisar función de remuestreo 
t = repeat(1:120, 1, 218)
dates = Date(2000, 12) : Month(1) : Date(2000,12) + Month(120-1)
fictbase = VarCPIBase(convert.(Float32, t), rand(Float32, 218), dates, 100f0)
fictdata = UniformCountryStructure(fictbase)

# Función de remuestreo 
resamplefn = ResampleScrambleVarMonths() 

# Función de inflación ficticia para obtener índices de remuestreo
@everywhere begin 

    struct FictInflationIndexes <: InflationFunction end 

    function (::FictInflationIndexes)(cs::CountryStructure) 
        # Retornar los índices remuestreados 
        first(cs.base).v[1:109]
    end
end 

idsinflfn = FictInflationIndexes()

## Obtener distribución de índices de remuestreo 

K = 10000
bootids = pargentrayinfl(idsinflfn, resamplefn, TrendIdentity(), fictdata, K=10000)


## Analizar la distribución de índices del primer período 

using Plots
using StatsBase 
using Distributions 

period1 = convert.(Int, bootids[109, :, :]) |> vec
catdata = @. (period1 - mod(period1, 12)) / 12 

countids = countmap(period1)
ids = [keys(countids)...] |> sort
phat = [countids[ids[i]] / K for i in 1:10]

b1 = bar(ids, phat, label=false)    
display(b1)

p0 = ones(10) / 10

n = K
Tn = n*sum(((phat - p0) .^ 2) ./ p0) # ~ Chisq(9) 
pval = 1 - cdf(Chisq(9), Tn)

## Realizar una prueba de hipótesis Chi-cuadrada contra la distribución uniforme

chisquare_uniform_test(bootids, 109) 

## Realizar la prueba en todos los períodos 

pvals = map(i -> chisquare_uniform_test(bootids, i), 1:109) 

mean(pvals .< 0.05) 

plot(pvals, label="Valores p, prueba Chi-cuadrada", xlabel="Período")



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
