using DrWatson
@quickactivate "HEMI"

using HEMI
using StatsBase
using Plots

## Prueba con datos de 64 bits

# gt00_64, gt10_64 = load(datadir("guatemala", "gtdata.jld2"), "gt00", "gt10")
# gtdata_64 = UniformCountryStructure(gt00_64, gt10_64)

## 
# ## Distribuciones fat y gat de un mes particular 
fat = ObservationsDistr(gt00.v[1, :], V)

sum(fat), mean(fat)
fat(0)

gat = WeightsDistr(gt00.v[1, :], gt00.w, V)

sum(gat), mean(gat)
gat(0)


# ## Distribuciones acumuladas FAT y GAT
cfat = cumsum(fat)
cgat = cumsum(gat)

# ## Percentiles equiponderados y ponderados con funciones de Julia
N = 5
p = (0:N) ./ N

quantile(gt00.v[1, :], p)

wp = aweights(gt00.w)
quantile(gt00.v[1, :], wp, p)


# ## Distribuciones de largo plazo 

all_v = vcat(gt00.v[:], gt10.v[1:120, :][:])
flp = ObservationsDistr(all_v, V)

sum(flp), mean(flp)
# mean(all_v)

FLP = cumsum(flp)
FLP(0)

quantile(FLP, p)

# plot(flp.vspace, flp.distr, xlims=(-2, 5))
# plot(FLP.vspace, FLP.(FLP.vspace), xlims=(-2, 5))

all_w = vcat(repeat(gt00.w', 120)[:], repeat(gt10.w', 120)[:])
glp = WeightsDistr(all_v, all_w, V)

sum(glp), mean(glp)
# mean(glp) es equivalente a 
# mpm0 = gt00.v * gt00.w / 100
# mpm1 = gt10.v * gt10.w / 100
# mpm = vcat(mpm0, mpm1)
# mean(mpm)

GLP = cumsum(glp)
GLP(0)

quantile(GLP, p)

# plot(glp.vspace, glp.distr, xlims=(-2, 5))
# plot(GLP.vspace, GLP.(GLP.vspace), xlims=(-2, 5))

# Gráfica con las distribuciones de largo plazo 
plot(GLP.vspace, [FLP.(FLP.vspace), GLP.(GLP.vspace)], xlims=(-2, 5))


# ## Obtener los percentiles de la distribución acumulada

# Comparar los percentiles de las distribuciones empíricas equiponderadas y
# ponderadas 
quantile(gt00.v[1, :], [0, 0.25, 0.5, 0.75, 1.])
quantile(cfat, [0, 0.25, 0.5, 0.75, 1.])

quantile(gt00.v[1, :], wp, [0, 0.25, 0.5, 0.75, 1.])
quantile(cgat, [0, 0.25, 0.5, 0.75, 1.])


# ## Algoritmo MAI-G
##

n = 5
p = (0:n) ./ n

# Distribución gat del mes
gat = WeightsDistr(gt00.v[1, :], gt00.w, V)
sum(gat), mean(gat)

# Verificamos los percentiles de la distribución gat
cgat = cumsum(gat)
pk_g = quantile(cgat, p)
cgat.(pk_g)

# Verificamos los percentiles de la distribución GLP
GLP = cumsum(glp)
pk_glp = quantile(GLP, p)
GLP.(pk_glp)

# Renormalizar distribución 
glpt = renorm_g_glp(cgat, GLP, glp, n)
sum(glpt), mean(glpt) 

# Prueba con gráfica 
cgat = cumsum(gat)
plot(cgat.vspace, cgat.(cgat.vspace), xlims=(-2, 5))
GLP = cumsum(glp)
plot!(GLP.vspace, GLP.(GLP.vspace), xlims=(-2, 5))

cglpt = cumsum(glpt)
plot!(cglpt.vspace, cglpt.(cglpt.vspace), xlims=(-2, 5))
hline!((1:n-1)/n)


## Algoritmo MAI-F

n = 40
p = (0:n) ./ n

# for jt = 1:5
jt = 1

# Distribución fat del mes
fat = ObservationsDistr(gt00.v[jt, :], V)
sum(fat), mean(fat)

cfat = cumsum(fat)

flpt = renorm_f_flp(cfat, FLP, GLP, glp, n)
sum(flpt), mean(flpt) 

println(mean(flpt))
# @enter renorm_f_flp(cfat, FLP, GLP, glp, n)

# end


# ## MAI-G para toda la base 2000
## 
# Obtener distribución de cada período en la base 2000
gdistr00 = cumsum.(WeightsDistr.(eachrow(gt00.v), Ref(gt00.w), Ref(V)))

# Renormalizar las distribuciones 
glpt00 = renorm_g_glp.(gdistr00, Ref(GLP), Ref(glp), n)

# Obtener la variación intermensual 
mai_g = mean.(glpt00)


# ## Instanciar función de inflación 

# maifn = InflationCoreMai(MaiF(4))
# maifn = InflationCoreMai([MaiF(4), MaiG(4), MaiF(5), MaiG(5)])