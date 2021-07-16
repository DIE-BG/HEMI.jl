## Funciones para renormalización y cómputo de MAI

# Renormalización de distribución g con distribución glp utilizando n segmentos
function renorm_g_glp(G, GLP, glp, n)

    # Percentiles con n segmentos y precisión
    p = (0:n) ./ n
    ε = step(glp.vspace)
    
    # Obtener distribuciones acumuladas
    # G = cumsum(g)
    # GLP = cumsum(glp)
    # Obtener los percentiles de los n segmentos
    q_g = quantile(G, p)
    q_glp = quantile(GLP, p)

    # Obtener lista de segmentos para renormalizar
    segments = get_segments(q_g, q_glp, n)
    @debug "Percentiles y segmentos" q_g q_glp ε segments

    # Crear una copia de la distribución glp 
    glpₜ = deepcopy(glp)

    # Renormalizar cada segmento
    for i in 2:length(segments)
        k = segments[i]
        t = segments[i-1]

        # Renormalizar el segmento 
        v1 = i == 2 ? min(q_g[t], q_glp[t]) : q_g[t]
        vl = i == length(segments) ? max(q_g[k], q_glp[k]) : q_g[k]
        norm_c = (G(vl) - G(v1)) / (GLP(vl) - GLP(v1))

        isnan(norm_c)&& continue # error("Error en normalización")
        # @debug "Renormalizando segmento $i" t k q_g[t] q_g[k] norm_c

        # Si es el primer segmento, incluir el límite inferior.
        # De lo contrario, renormalizar a partir de la siguiente posición en la
        # grilla
        if i == 2
            renormalize!(glpₜ, v1, vl, norm_c)
        else
            renormalize!(glpₜ, v1 + ε, vl, norm_c)
        end
    end

    # Devolver la distribución renormalizada
    glpₜ
end

# Función para renormalizar segmento dado entre dos variaciones intermensuales a y b
# por el valor k
function renormalize!(tdistr::TransversalDistr, a, b, k)
    # Obtener índices de variaciones a y b en vspace
    ia = vposition(a, tdistr.vspace)
    ib = vposition(b, tdistr.vspace)

    # Renormalizar el vector de distribución subyacente 
    @views tdistr.distr[ia:ib] .*= k
    nothing
end

# Función para obtener segmento especial de renormalización 
function get_segments(q_cp, q_lp, n)
    # Obtener número de percentiles que conforman segmento especial en la
    # disribución de largo plazo
    k̄ = findfirst(q_lp .> 0)
    k̲ = findlast(q_lp .< 0)
    
    # Obtener número de percentiles que conforman segmento especial en la
    # disribución del mes o ventana
    s̄ = findfirst(q_cp .> 0)
    s̲ = findlast(q_cp .< 0)
    
    # Obtener los números comunes
    r̲ = min(k̲, s̲)
    r̄ = max(k̄, s̄)
    
    # Devolver lista de segmentos para renormalizar
    union(1:r̲, r̄:n+1)
end