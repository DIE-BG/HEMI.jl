using MarketTechnicals
using Printf
using UnicodePlots

# Directorio donde se guardarán las trayectorias de camianta aleatoria utilizadas.
RWTREND_DIR = joinpath(@__DIR__,"..", "data", "RWTREND")

@chain RWTREND_DIR !isdir(_) && mkdir(_)

#----- Cómputo de las diferencias en variaciones intermensuales -----

inflfn = InflationTotalCPI()

# Cómputo de las diferencias
dif_interm_00 = diff(inflfn(UniformCountryStructure(GT00), CPIVarInterm()))

dif_interm_10 = diff(inflfn(UniformCountryStructure(GT10), CPIVarInterm()))

#----- Calcular las medias móviles de 12 meses -----

ma_dif_interm_00 = sma(dif_interm_00, 12)
ma_dif_interm_10 = sma(dif_interm_10, 12)

#----- Calibración de varianza con medias móviles ------

# Varianza período base 2000
sigma_eps_00 = sqrt(var(ma_dif_interm_00))
@printf "Varianza periodo base 2000, σ_ϵ^2 = %.6f\n" sigma_eps_00

sigma_eps_10 = sqrt(var(ma_dif_interm_10))
@printf "Varianza periodo base 2010, σ_ϵ^2 = %.6f\n" sigma_eps_10

# Varianza período completo
sigma_eps_completo = sqrt(var([ma_dif_interm_00; ma_dif_interm_10]))
@printf "Varianza periodo completo, σ_ϵ^2 = %.6f\n" sigma_eps_completo

#----- Generar el proceso aditivo de tedencia -----
function crear_ruido_blanco(
    n,
    sigma_eps,
    desired_mean=0,
    desired_mean_threshold=0.1,
    min_threshold=-0.5,
    max_threshold=2,
    append_most_recent=true,
)
    #crear_ruido_blanco(n, sigma_eps) 
    #  n:  largo del vector de ruido
    #  sigma_eps:  desviación estándar del ruido blanco normal
    #  desired_mean: valor alrededor del cual oscila la señal de ruido blanco
    #  desired_mean_threshold: tolerancia permisible en el valor de la media
    #  min_threshold: valor mínimo permisible en la señal de ruido blanco
    #  max_threshold: valor máximo permisible en la señal de ruido blanco

    rb = zeros(n, 1)
    media = 1
    while abs(media - desired_mean) > desired_mean_threshold ||
              min(rb...) < min_threshold ||
              max(rb...) > max_threshold
        y = sigma_eps .* randn(n, 1)
        if append_most_recent
            rb = vec(cumsum([InflationEvalTools.delog_rwtrend[end]; y]; dims=1))
            rb = [
                InflationEvalTools.delog_rwtrend[1:(end - 1)]
                rb
            ]
        else
            rb = vec(cumsum(y; dims=1))
        end
        media = mean(rb)
    end
    return (rb)
end

#----- Generar el proceso aditivo de tendencia -----
T = 24
# Ruido blanco con la varianza del período base 2000 inicialmente
ruido_blanco_base00 = crear_ruido_blanco(T, sigma_eps_00)

# Ruido blanco con la varianza del período completo
# Se buscan trayectorias cuyo valor promedio sea cercano a cero

is_acceptable = "n"

while is_acceptable == "n"
    global ruido_blanco_0010 = crear_ruido_blanco(T, sigma_eps_completo)
    display(lineplot(ruido_blanco_0010; title="Caminata Aleatoria para Tendencia"))
    println(
        "Escriba 'y' si es aceptable la trayectoria.\nPara generar otra trayectoria presione enter...",
    )
    global is_acceptable = readline() == "y" ? break : "n"
end

# ----- Guardar el resultado en la carpeta data -----

save(joinpath(RWTREND_DIR, "RWTREND $(today()).jld2"), "RWTREND", ruido_blanco_0010)

@info "Se ha guardado una nueva trayectoria de caminata aleatoria."

@warn "Inicie de nuevo el proyecto para que la nueva trayectoria sea utilizada."