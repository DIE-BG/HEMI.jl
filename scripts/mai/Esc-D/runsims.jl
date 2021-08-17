# Escenario C: Evaluación de criterios básicos con cambio de parámetro de evaluación

# Variantes MAI F, G y FP con [3, 4, 5, 8, 10, 20, 40] segmentos 
include("D19-36/eval-CoreMai.jl")
include("D19-60/eval-CoreMai.jl")
include("D20-36/eval-CoreMai.jl")
include("D20-60/eval-CoreMai.jl")

# Optimización de cuantiles con datos hasta 2019 
include("D19-36/optim-CoreMai.jl")
include("D19-60/optim-CoreMai.jl")

# Optimización de cuantiles con datos hasta 2020
include("D20-36/optim-CoreMai.jl")
include("D20-60/optim-CoreMai.jl")