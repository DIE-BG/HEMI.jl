# scramblevar.jl - Functions to resample VarCPIBase objects

# Esta es la mejor versión, requiere crear copias de los vectores de los mismos
# meses, para cada gasto básico. Se presenta una versión más eficiente abajo
# 475.600 μs (2618 allocations: 613.20 KiB)

# function scramblevar!(vmat::AbstractMatrix, rng = Random.GLOBAL_RNG) 
#     for i in 1:12
#         # fill every column with random values from the same periods (t and t+12)
#         for j in 1:size(vmat, 2)
#             rand!(rng, (@view vmat[i:12:end, j]), vmat[i:12:end, j])
#         end
#     end
# end


# function scramblevar(vmat::AbstractMatrix, rng = Random.GLOBAL_RNG) 
#     scrambled_mat = copy(vmat)
#     scramblevar!(scrambled_mat, rng)
#     scrambled_mat
# end

# Primera versión con remuestreo por columnas 
# function scramblevar(vmat::AbstractMatrix, rng = Random.GLOBAL_RNG) 
#     periods, n = size(vmat)
#     # Matriz de valores remuestreados 
#     v_sc = similar(vmat) 
#     for i in 1:min(periods, 12)
#         v_month = vmat[i:12:periods, :]
#         periods_month = size(v_month, 1)
#         for g in 1:n 
#             v_month[:, g] = rand(rng, v_month[:, g], periods_month)
#         end       
#         # Asignar valores de los mismos meses
#         v_sc[i:12:periods, :] = v_month
#     end
#     v_sc
# end

# Versión optimizada para memoria 
# 420.100 μs (2 allocations: 204.45 KiB)
function scramblevar(vmat::AbstractMatrix, rng = Random.GLOBAL_RNG) 
    periods, n = size(vmat)

    # Matriz de valores remuestreados 
    v_sc = similar(vmat) 

    # Para cada mes y cada gasto básico, tomar aleatoriamente de los mismos
    # meses de vmat y llenar v_sc (v_scrambled)
    for i in 1:min(periods, 12), g in 1:n 
        Random.rand!(rng, view(v_sc, i:12:periods, g), view(vmat, i:12:periods, g))        
    end    
    v_sc
end


## Remuestreo de objetos de CPIDataBase
# Se define una ResampleFunction para implementar interfaz a VarCPIBase y CountryStructure

# Definición de la función de remuestreo por ocurrencia de meses
"""
    ResampleScrambleVarMonths <: ResampleFunction

Define una función de remuestreo para remuestrear las series de tiempo por los
mismos meses de ocurrencia. El muestreo se realiza de manera independiente para 
serie de tiempo en las columnas de una matriz. 
"""
struct ResampleScrambleVarMonths <: ResampleFunction end

# Definir cuál es la función para obtener bases paramétricas 
get_param_function(::ResampleScrambleVarMonths) = param_sbb

# Define cómo remuestrear matrices con las series de tiempo en las columnas.
# Utiliza la función interna `scramblevar`.
function (resamplefn::ResampleScrambleVarMonths)(vmat::AbstractMatrix, rng = Random.GLOBAL_RNG) 
    scramblevar(vmat, rng)
end 

# Definir el nombre y la etiqueta del método de remuestreo 
method_name(resamplefn::ResampleScrambleVarMonths) = "Bootstrap IID por meses de ocurrencia"
method_tag(resamplefn::ResampleScrambleVarMonths) = "SVM"