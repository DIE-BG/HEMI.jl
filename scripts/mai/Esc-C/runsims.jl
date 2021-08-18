# Escenario C: Evaluación de criterios básicos con cambio de parámetro de evaluación

# Variantes MAI F, G y FP con [3, 4, 5, 8, 10, 20, 40] segmentos 
include("eval-CoreMai.jl")

# Optimización de cuantiles con datos hasta 2019 
include("C19/optim-CoreMai.jl")

# Optimización de cuantiles con datos hasta 2020
include("C20/optim-CoreMai.jl")