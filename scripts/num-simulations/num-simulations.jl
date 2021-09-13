using DrWatson
@quickactivate "HEMI"

using Distributions
using Statistics
using DataFrames, Chain, PrettyTables

## Cargar el módulo de Distributed para computación paralela
using Distributed
nprocs() < 5 && addprocs(4, exeflags="--project")
@everywhere using HEMI


## Configuración de simulación 

# Datos de evaluación 
gtdata_eval = gtdata[Date(2020, 12)]
# Métodos de remuestreo, tendencia y función paramétrica 
# inflfn = InflationTotalCPI() 
inflfn = InflationPercentileEq(71.43) 
resamplefn = ResampleSBB(36)
trendfn = TrendRandomWalk()
paramfn = InflationTotalRebaseCPI(60)

# Generar trayectorias de simulación 
tray_infl = pargentrayinfl(inflfn, resamplefn, trendfn, gtdata_eval; 
    K=125_000)

## Configuración del parámetro de evaluación 
param = InflationParameter(paramfn, resamplefn, trendfn)
tray_infl_pob = param(gtdata_eval)

## Obtención de promedio y desviación estándar

# Errores 
err_dist = tray_infl .- tray_infl_pob

# Error cuadrático promedio general
mse = mean(x -> x^2, err_dist)

# Distribución del error cuadrático promedio por realización 
mse_dist = vec(mean(x -> x^2, err_dist, dims=1))

# Error estándar de simulación del promedio de error cuadrático 
T, n, K = size(err_dist)
# Error estándar de simulación del promedio por realización y período
mse_std_error_period = std(err_dist.^2) / sqrt(T * K)
# Error estándar de simulación del promedio por realización, es decir, tomando
# el promedio del error cuadrático promedio en el período completo de evaluación
mse_std_error_realization = std(mse_dist) / sqrt(K)

# Desviación estándar de la distribución del error cuadrático promedio por
# realización 
mse_std = std(mse_dist)

# Comparación con métricas de evaluación de eval_metrics
# metrics = eval_metrics(tray_infl, tray_infl_pob)


## Cómputo del número de simulaciones 

# epsilon = Máxima distancia permisible en el cómputo de la probabilidad
epsilon = 0.05 * mse
# Probabilidad: gamma_prob = P(|Z- theta| <= epsilon)
gamma_prob = 0.95

# --------------------------------------------------
# Bnormal: Criterio de normalidad en el estadístico de simulación
# BchebyshevCriterio más estricto a través de la desigualdad de Chebyshev
#     B representa el número de simulaciones
#     gamma_prob = probabilidad de que el estadístico no diste más de epsilon de la media de la distribución
#     sigma representa la desviación estándar de la muestra de simulación de estadísticos de error o correlación
# --------------------------------------------------

# Funciones de apoyo para el cómputo del número de simulaciones, DeGroot 4ed. capítulo 12
Φ⁻¹(p) = cdf(Normal(), p)
Bnormal(gamma_prob, sigma, epsilon) = (Φ⁻¹((1 - gamma_prob) / 2) * sigma / epsilon)^2
Bchebyshev(gamma_prob, sigma, epsilon) = (sigma / epsilon)^2 / (1 - gamma_prob)

# Número de simulaciones para el escenario base de evaluación
println("Número de simulaciones por normal: ", Bnormal(gamma_prob, mse_std, epsilon))
println("Número de simulaciones por Chebyshev: ", Bchebyshev(gamma_prob, mse_std, epsilon))

# Menú de variantes en el que se considera ϵ como un porcentaje del promedio. Es
# decir, se computa el número de simulaciones requerido para no alejarse en más
# del porcentaje ϵ = c*mse del promedio 
variants = DataFrame(
    reduce(vcat, [[mse mse_std γ c c*mse] for γ in (0.9, 0.95, 0.99) for c in (0.05, 0.025, 0.01)]), 
    [:mse, :mse_std, :gamma, :c, :epsilon]) 

menusims = @chain variants begin 
    transform(
        [:gamma, :mse_std, :epsilon] => ByRow(Bnormal) => :B_normal, 
        [:gamma, :mse_std, :epsilon] => ByRow(Bchebyshev) => :B_chebyshev)    
end

# Menú de variantes en que se considera ϵ como una desviación absoluta del
# promedio. Este es un criterio más estrico que el menú anterior 
menusims2 = @chain variants begin 
    transform(:gamma => ByRow(x->1-x) => :epsilon) 
    transform(
        [:gamma, :mse_std, :epsilon] => ByRow(Bnormal) => :B_normal, 
        [:gamma, :mse_std, :epsilon] => ByRow(Bchebyshev) => :B_chebyshev)    
end

# Obtener una tabla de Markdown de las variantes
pretty_table(menusims, tf=tf_markdown, formatters=ft_round(4))
pretty_table(menusims2, tf=tf_markdown, formatters=ft_round(4))


## Distancia para las 125_000 simulaciones 

# Obtenemos ϵ si γ = 0.99 y consideramos K simulaciones 
K = 125_000
eps99 = mse_std / sqrt(K*(1-0.99))