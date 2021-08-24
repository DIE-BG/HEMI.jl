## Scripts para generar evaluación y optimización de variantes MAI
# Escenario C: Evaluación de criterios básicos con cambio de parámetro de evaluación

SIMSPATH = scriptsdir("mai", "Esc-C")

# Variantes MAI F, G y FP con [3, 4, 5, 8, 10, 20, 40] segmentos 
include(joinpath(SIMSPATH, "eval-CoreMai.jl"))

# Optimización de cuantiles con datos hasta 2019 
include(joinpath(SIMSPATH, "C19", "optim-CoreMai.jl"))

# Optimización de cuantiles con datos hasta 2020
include(joinpath(SIMSPATH, "C20", "optim-CoreMai.jl"))