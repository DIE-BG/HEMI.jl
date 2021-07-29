## Funciones para renormalización y cómputo de MAI

## Algoritmos de renormalización de MAI-G

# Función para propósitos ilustrativos. Se utiliza en el cuaderno introductorio de la medida de inflación subyacente MAI. Para realizar el cómputo en InflationCoreMai se utiliza renorm_g_glp_perf. 

# Renormalización de distribución g con distribución glp utilizando n segmentos
# Esta función devuelve la distribución glpₜ (tiene menor desempeño)
function renorm_g_glp(G, GLP, glp, n)

    # Percentiles con n segmentos y precisión
    p = (0:n) ./ n
    ε = step(glp.vspace)
    
    # Obtener los percentiles de los n segmentos
    q_g = quantile(G, p)
    q_glp = quantile(GLP, p)

    # Obtener lista de segmentos para renormalizar
    segments = get_segments_list(q_g, q_glp, n)
    # @debug "Percentiles y segmentos" q_g q_glp ε segments

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

        isnan(norm_c) && continue 
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

# Renormalización de distribución g con distribución glp utilizando n segmentos.
# Esta función no devuelve la distribución glpₜ y aplica algunas optimizaciones
# de memoria 
function renorm_g_glp_perf(G::AccumulatedDistr{T}, GLP, glp, q_g, q_glp, n) where T

    # Percentiles con n segmentos y precisión
    ε = step(glp.vspace)
    
    # Obtener números de segmentos para renormalizar
    r̲, r̄ = get_segments(q_g, q_glp)

    e_glpt::T = zero(T)

    # Renormalizar cada segmento
    @inbounds for i in 2:n+1
        # Obtener segmentos a renormalizar. Saltar en el segmento especial
        r̲ < i < r̄ && continue 
        k = i
        t = i == r̄ ? r̲ : i-1

        # Renormalizar el segmento       
        if t == 1
            v1 = min(q_g[t], q_glp[t])
        else
            v1 = q_g[t]
        end

        if k == n+1
            vl = max(q_g[k], q_glp[k])
        else
            vl = q_g[k]
        end

        # Constante de normalización
        norm_c = (G(vl) - G(v1)) / (GLP(vl) - GLP(v1))

        (isnan(norm_c) || isinf(norm_c)) && continue 

        # Si es el primer segmento, incluir el límite inferior. De lo contrario,
        # renormalizar a partir de la siguiente posición en la grilla
        if t == 1
            e_glpt += renorm_sum(glp, v1, vl, norm_c)
        else
            e_glpt += renorm_sum(glp, v1 + ε, vl, norm_c)
        end
    end

    # Devolver el promedio ponderado de la distribución renormalizada
    e_glpt
end


## Algoritmos de renormalización de variante MAI-F

# Función para propósitos ilustrativos. Se utiliza en el cuaderno introductorio de la medida de inflación subyacente MAI. Para realizar el cómputo en InflationCoreMai se utiliza renorm_g_flp_perf. 

# Renormalización de distribución f con distribución flp utilizando n segmentos. 
# Esta función devuelve la distribución flpₜ y por lo tanto, tiene menor desempeño.
function renorm_f_flp(F, FLP, GLP, glp, n)

    # Percentiles con n segmentos y precisión
    p = (0:n) ./ n
    ε = step(glp.vspace)
    
    # Obtener distribuciones acumuladas
    # Obtener los percentiles de los n segmentos
    q_f = quantile(F, p)
    q_flp = quantile(FLP, p)

    # Obtener lista de segmentos para renormalizar
    segments = get_segments_list(q_f, q_flp, n)
    # @debug "Percentiles y segmentos" q_g q_flp ε segments

    # Crear una copia de la distribución glp 
    flpₜ = deepcopy(glp)

    # Renormalizar cada segmento
    S = length(segments)

    for i in 2:S
        k = segments[i]
        t = segments[i-1]

        # Renormalizar el segmento 
        v1_num = i == 2 ? min(q_f[t], q_flp[t]) : q_flp[t]
        vl_num = i == S ? max(q_f[k], q_flp[k]) : q_flp[k]
        
        v1 = i == 2 ? min(q_f[t], q_flp[t]) : q_f[t]
        vl = i == S ? max(q_f[k], q_flp[k]) : q_f[k]
        norm_c = (GLP(vl_num) - GLP(v1_num)) / (GLP(vl) - GLP(v1))

        isnan(norm_c) && continue
        # @debug "Renormalizando segmento $i" t k q_g[t] q_g[k] norm_c

        # Si es el primer segmento, incluir el límite inferior.
        # De lo contrario, renormalizar a partir de la siguiente posición en la
        # grilla
        if i == 2
            renormalize!(flpₜ, v1, vl, norm_c)
        else
            renormalize!(flpₜ, v1 + ε, vl, norm_c)
        end
    end

    # Devolver la distribución renormalizada
    flpₜ
end

# Renormalización de distribución f con distribución flp utilizando n segmentos.
# Esta función no devuelve la distribución flpₜ y aplica algunas optimizaciones
# de memoria 
function renorm_f_flp_perf(F::AccumulatedDistr{T}, GLP, glp, q_f, q_flp, n) where T

    # Percentiles con n segmentos y precisión
    ε = step(glp.vspace)
    
    # Obtener números de segmentos para renormalizar
    r̲, r̄ = get_segments(q_f, q_flp)

    e_flpt::T = zero(T)
    
    # Renormalizar cada segmento
    for i in 2:n+1
        # Obtener segmentos a renormalizar. Saltar en el segmento especial
        r̲ < i < r̄ && continue 
        k = i
        t = i == r̄ ? r̲ : i-1

        # Renormalizar el segmento       
        if t == 1
            v1 = v1_num = min(q_f[t], q_flp[t])
        else
            v1 = q_f[t]
            v1_num = q_flp[t]
        end

        if k == n+1
            vl = vl_num = max(q_f[k], q_flp[k])
        else
            vl = q_f[k]
            vl_num = q_flp[k]
        end

        # Constante de normalización
        norm_c = (GLP(vl_num) - GLP(v1_num)) / (GLP(vl) - GLP(v1))

        (isnan(norm_c) || isinf(norm_c)) && continue

        # Si es el primer segmento, incluir el límite inferior. De lo contrario,
        # renormalizar a partir de la siguiente posición en la grilla
        if t == 1
            e_flpt += renorm_sum(glp, v1, vl, norm_c)
        else
            e_flpt += renorm_sum(glp, v1 + ε, vl, norm_c)
        end
    end

    # Devolver el promedio ponderado de la distribución renormalizada
    e_flpt
end


## Funciones auxiliares

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

# Función para computar la suma ponderada de renormalización del segmento dado
# entre dos variaciones intermensuales a y b por el valor k
function renorm_sum(tdistr::TransversalDistr{T}, a, b, k) where T
    # Obtener índices de variaciones a y b en vspace
    ia = vposition(a, tdistr.vspace)
    ib = vposition(b, tdistr.vspace)

    # Renormalizar el vector de distribución subyacente y obtener la suma ponderada
    s = zero(T)
    @inbounds for j in ia:ib
        s += tdistr.distr[j] * tdistr.vspace[j]
    end
    
    s * k
end

# Función para obtener segmento especial de renormalización 
function get_segments(q_cp, q_lp)
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

    r̲, r̄
end

function get_segments_list(q_cp, q_lp, n)
    # Devolver lista de segmentos para renormalizar
    r̲, r̄ = get_segments(q_cp, q_lp)
    union(1:r̲, r̄:n+1)
end