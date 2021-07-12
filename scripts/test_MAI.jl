using DrWatson
@quickactivate "HEMI"

using HEMI
using StatsBase
using Plots

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
N = 4
p = (1:N-1) ./ N

quantile(gt00.v[1, :], [0, 0.25, 0.5, 0.75, 1.])

wp = aweights(gt00.w)
quantile(gt00.v[1, :], wp, [0, 0.25, 0.5, 0.75, 1.])


# ## Distribuciones de largo plazo 

all_v = vcat(gt00.v[:], gt10.v[:])
flp = ObservationsDistr(all_v, V)

sum(flp), mean(flp)
# mean(all_v)

FLP = cumsum(flp)
FLP(0)

# plot(flp.vspace, flp.distr, xlims=(-2, 5))
# plot(FLP.vspace, FLP.(FLP.vspace), xlims=(-2, 5))

all_w = vcat(repeat(gt00.w', 120)[:], repeat(gt10.w', 122)[:])
glp = WeightsDistr(all_v, all_w, V)

sum(glp), mean(glp)

# mean(glp) es equivalente a 
# mpm0 = gt00.v * gt00.w / 100
# mpm1 = gt10.v * gt10.w / 100
# mpm = vcat(mpm0, mpm1)
# mean(mpm)

GLP = cumsum(glp)
GLP(0)

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


# ## Algoritmo MAI 

n = 40

# Distribución gat del mes
gat = WeightsDistr(gt00.v[4, :], gt00.w, V)

# Renormalizar distribución 
glpt = renorm_g_glp(gat, glp, n)

sum(glpt), mean(glpt) 
# Me quedé arreglando esta suma, que se aleja de 1 supongo que porque estoy incluyendo en la renormalización ambos límites, debo de cuidar que se sume epsilon al límite inferior o algo así, para no incluir doble... ?

# Prueba con gráfica 
cgat = cumsum(gat)
plot(cgat.vspace, cgat.(cgat.vspace), xlims=(-2, 5))
GLP = cumsum(glp)
plot!(GLP.vspace, GLP.(GLP.vspace), xlims=(-2, 5))

cglpt = cumsum(glpt)
plot!(cglpt.vspace, cglpt.(cglpt.vspace), xlims=(-2, 5))
hline!((1:n-1)/n)

# renormalize!(glpt, -2, 0.5, 0.75)