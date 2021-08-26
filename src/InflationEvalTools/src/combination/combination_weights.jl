## Método de solución analítica de ponderadores de la combinación lineal óptima del MSE 

"""
    combination_weights(tray_infl, tray_infl_param) -> Vector{<:AbstractFloat}

Función de obtención de ponderadores óptimos de la solución analítica al
problema de minimización del error cuadrático medio de la combinación lineal de
estiamadores de inflación en `tray_infl` utilizando la trayectoria de inflación
paramétrica `tray_infl_param`. Devuelve un vector con los ponderadores asociados
a cada estimador en las columnas de `tray_infl`.
"""
function combination_weights(tray_infl, tray_infl_param)
    # Obtener matriz de ponderadores XᵀX y vector Xᵀπ
    XᵀX, Xᵀπ = average_mats(tray_infl, tray_infl_param)
    @info "Determinante de la matriz de coeficientes" det(A)

    # Ponderadores de combinación óptima de mínimos cuadrados
    a_optim = XᵀX \ Xᵀπ
    a_optim 
end

# Matriz de diseño y de covarianza con parámetro, promediadas en tiempo y
# a través de las realizaciones 
function average_mats(tray_infl, tray_infl_param)
    # Número de ponderadores, observaciones y simulaciones 
    T, n, K = size(tray_infl)

    # Conformar la matriz de coeficientes
    XᵀX = zeros(eltype(tray_infl), n, n)
    XᵀX_temp = zeros(eltype(tray_infl), n, n)
    for j in 1:K
        tray = @view tray_infl[:, :, j]
        mul!(XᵀX_temp, tray', tray)
        XᵀX_temp ./= T
        XᵀX += XᵀX_temp
    end
    # Promedios en número de realizaciones
    XᵀX /= K

    # Interceptos como función del parámetro y las trayectorias a combinar
    Xᵀπ = zeros(eltype(tray_infl), n)
    Xᵀπ_temp = zeros(eltype(tray_infl), n)
    for j in 1:K
        tray = @view tray_infl[:, :, j]
        mul!(Xᵀπ_temp, tray', tray_infl_param)
        Xᵀπ_temp ./= T
        Xᵀπ += Xᵀπ_temp
    end
    # Promedios en número de realizaciones
    Xᵀπ /= K

    XᵀX, Xᵀπ
end

# Ponderadores de combinación Ridge
function ridge_combination_weights(tray_infl, tray_infl_param, λ)
    # Obtener matriz de ponderadores XᵀX y vector Xᵀπ
    XᵀX, Xᵀπ = average_mats(tray_infl, tray_infl_param)
    @info "Determinante de la matriz de coeficientes" det(A)

    # Ponderadores de combinación óptima de Ridge
    n = size(tray_infl, 2)
    a_ridge = (XᵀX + λ*I(n)) \ Xᵀπ
    a_ridge 
end


# Ponderadores de combinación lasso
function lasso_combination_weights(tray_infl, tray_infl_param, λ; maxiterations=100, α=0.005)
    T, n, K = size(tray_infl)

    β = zeros(eltype(tray_infl), n)
    cost_vals = zeros(maxiterations)
    XᵀX, Xᵀπ = average_mats(tray_infl, tray_infl_param)

    # Proximal gradient descent
    for t in 1:maxiterations
        # tray_infl_comb = sum(tray_infl .* β', dims=2)
        # err_t_k =  tray_infl_comb .- tray_infl_param
        # mse_grad = vec(mean(err_t_k .* tray_infl, dims=[1, 3]))

        # metrics = eval_metrics(tray_infl_comb, tray_infl_param, short=true)
		grad = (XᵀX * β) - Xᵀπ
		
		# Proximal gradient 
		β = proxl1norm(β - α*grad, α*λ)
		
		# cost_vals[t] = metrics[:mse] + λ*sum(abs, β)
		
		if t % 5 == 0
			println("Iter: ", t, "\tcost = ", cost_vals[t])
            println("β = ", β) 
            println("grad = ", grad)
		end
	end
	
	β, cost_vals


end

# Operador próximo para la norma L1
function proxl1norm(z, α)
    proxl1 = z - clamp.(z, Ref(-α), Ref(α))
    proxl1
end
