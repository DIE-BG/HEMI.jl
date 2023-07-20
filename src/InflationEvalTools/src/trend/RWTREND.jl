# Directorio donde se encuentran almacenadas las trayectorias de caminata aleatoria.
RWTREND_DIR = joinpath(@__DIR__, "..", "..", "data", "RWTREND")

# Vector con todas las trayectorias disponibles.
avaible_rwtrend = map(readdir(RWTREND_DIR)) do x
    @chain x begin
        match(r"\s(.*)\.jld2", _).captures[1]
        Date(_)
    end
end

# Se elige la más reciente para ser añadida al a la tendencia estocásica.
last_avaible_rwtrend = last(sort(avaible_rwtrend))
delog_rwtrend = load(joinpath(RWTREND_DIR, "RWTREND $(last_avaible_rwtrend).jld2"))["RWTREND"]

"""
    RWTREND
Trayectoria de caminata aleatoria precalibrada para 292 períodos.
"""
const RWTREND = @. convert(Float32, exp(delog_rwtrend))