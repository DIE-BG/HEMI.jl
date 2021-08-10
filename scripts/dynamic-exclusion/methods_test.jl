# Las funciones sobre VarCPIBase resumen en variaciones intermensuales
function (inflfn::InflationDynamicExclusion)(base::VarCPIBase)
    lower_factor = inflfn.lower_factor
    upper_factor = inflfn.upper_factor

    std_v = std(base.v, dims = 2)
    mean_v = mean(base.v, dims = 2)

    dynEx_filter = (mean_v - (lower_factor .* std_v)) .<= base.v .<= (mean_v + (upper_factor .* std_v))

    dynEx_w = base.w' .* dynEx_filter
    dynEx_w = dynEx_w ./ sum(dynEx_w, dims = 2)

    dynEx_v = sum(
        base.v .* dynEx_w,
        dims = 2
    ) |> vec
end

# Las funciones sobre VarCPIBase resumen en variaciones intermensuales
function (inflfn::InflationDynamicExclusion)(base::VarCPIBase)
    lower_factor = inflfn.lower_factor
    upper_factor = inflfn.upper_factor

    out_vect = Vector{Float32}(undef, periods(base))

    Threads.@threads for period in 1:periods(base)
        
        temp_v = @view base.v[period, :]
        temp_w = @view base.w[:,:]

        temp_std = std(temp_v)
        temp_mean = mean(temp_v)
        temp_filter = -(lower_factor * temp_std) .<= temp_v .- temp_mean .<=(upper_factor * temp_std)

        @inbounds out_vect[period] = sum(temp_v .* temp_filter .* (temp_w ./ 100))
    
    end

    return out_vect
end


# Las funciones sobre VarCPIBase resumen en variaciones intermensuales
function (inflfn::InflationDynamicExclusion)(base::VarCPIBase)
    lower_factor = inflfn.lower_factor
    upper_factor = inflfn.upper_factor

    std_v = std(base.v, dims = 2)
    mean_v = mean(base.v, dims = 2)

    filter_limits = Matrix{Float32}(undef, periods(base), 2)
    filter_limits[:, 1] = mean_v - (lower_factor .* std_v) # Límite inferior
    filter_limits[:, 2] = mean_v + (lower_factor .* std_v) # Límite superior
   
# Hasta aquí tiene una eficiencia de 29.700 μs (72 allocations: 17.09 KiB)
    @time filter_dynEx = (@view filter_limits[:, 1]) .<= 
        base.v .<= 
        (@view filter_limits[:, 2]) 

    dynEx_w = base.w' .* filter_dynEx
    dynEx_w = dynEx_w ./ sum(dynEx_w, dims = 2)

    dynEx_v = sum(
        base.v .* dynEx_w,
        dims = 2
    ) |> vec
end


# Cuarta implementación

function (inflfn::InflationDynamicExclusion)(base::VarCPIBase)
    lower_factor = inflfn.lower_factor
    upper_factor = inflfn.upper_factor

    std_v = std(base.v, dims = 2)
    mean_v = mean(base.v, dims = 2)

    filter_limits = Matrix{Float32}(undef, periods(base), 2)
    filter_limits[:, 1] = mean_v - (lower_factor .* std_v) # Límite inferior
    filter_limits[:, 2] = mean_v + (upper_factor .* std_v) # Límite superior
   

    # Para cada t: 
    # Se determina aquellos gastos que cumplen la condición.
    # Se computa el producto de los pesos con los variaciones filtradas.
    # Se suma el resultado.

    # Número de gastos básicos
    nGb = size(base.v, 2)

    outVec = Vector{Float32}(undef, periods(base))
    
    # Apartado de memoria. Columnas corresponde a gastos básicos y filas
    # a hilos.
    filter_dynEx_list = BitArray(undef, Threads.nthreads(), nGb)

    Threads.@threads for period in 1:periods(base)
        
        # Obtener los vectores de cada hilo 
        thread_id = Threads.threadid()
        filter_dynEx = filter_dynEx_list[thread_id, :]

        # Obtener gastos básicos que cumplen condición.
        v_month = @view base.v[period, :]
        lower_filter_limit = @view filter_limits[period, 1]
        upper_filter_limit = @view filter_limits[period, 2]
        
        
        filter_dynEx = lower_filter_limit .<= v_month .<= upper_filter_limit

        # Pesos reponderados y renormalizados

        w_dynEx = filter_dynEx .* base.w
        w_dynEx = w_dynEx ./ sum(w_dynEx)


        # Computar promedio ponderado de variaciones dentro de límites
        @inbounds outVec[period] = sum(v_month .* w_dynEx)
    end
    
    return outVec
end