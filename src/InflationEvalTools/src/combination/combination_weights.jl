## Método de solución analítica de ponderadores de la combinación lineal óptima del MSE 

"""
    combination_weights(tray_infl, tray_infl_param) -> Vector{<:AbstractFloat}

Obtiene los ponderadores óptimos de la solución analítica al problema de
minimización del error cuadrático medio de la combinación lineal de estiamadores
de inflación en `tray_infl` utilizando la trayectoria de inflación paramétrica
`tray_infl_param`. 

Devuelve un vector con los ponderadores asociados a cada estimador en las
columnas de `tray_infl`.

Ver también: [`ridge_combination_weights`](@ref),
[`lasso_combination_weights`](@ref)
"""
function combination_weights(tray_infl, tray_infl_param)
    # Obtener matriz de ponderadores XᵀX y vector Xᵀπ
    XᵀX, Xᵀπ = average_mats(tray_infl, tray_infl_param)
    @info "Determinante de la matriz de coeficientes" det(XᵀX)

    # Ponderadores de combinación óptima de mínimos cuadrados
    a_optim = XᵀX \ Xᵀπ
    a_optim 
end

# Matriz de diseño y de covarianza con parámetro, promediadas en tiempo y
# a través de las realizaciones 
"""
    average_mats(tray_infl, tray_infl_param) -> (Matrix{<:AbstractFloat}, Vector{<:AbstractFloat})

Obtiene las matrices `XᵀX` y `Xᵀπ` para el problema de minimización del error
cuadrático medio. 
"""
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

# Ponderadores de combinación Ridge con parámetro de regularización lambda
"""
    ridge_combination_weights(tray_infl, tray_infl_param, lambda) -> Vector{<:AbstractFloat}

Obtiene ponderadores óptimos de Ridge a través de la solución analítica al
problema de minimización del error cuadrático medio de la combinación lineal de
estimadores de inflación en `tray_infl` utilizando la trayectoria de inflación
paramétrica `tray_infl_param`, regularizada con la norma L2 de los ponderadores, 
ponderada por el parámetro `lambda`.

Devuelve un vector con los ponderadores asociados a cada estimador en las
columnas de `tray_infl`.

Ver también: [`combination_weights`](@ref), [`lasso_combination_weights`](@ref)
"""
function ridge_combination_weights(tray_infl::AbstractArray{F, 3}, tray_infl_param, lambda) where F
    # Obtener matriz de ponderadores XᵀX y vector Xᵀπ
    XᵀX, Xᵀπ = average_mats(tray_infl, tray_infl_param)
    λ = convert(F, lambda)
    n = size(tray_infl, 2)
    
    # Ponderadores de combinación óptima de Ridge
    @info "Determinante de la matriz de coeficientes" det(XᵀX)
    a_ridge = (XᵀX + λ*I(n)) \ Xᵀπ
    a_ridge 
end


# Ponderadores de combinación lasso con parámetro de regularización lambda
"""
    lasso_combination_weights(tray_infl, tray_infl_param, lambda; 
        maxiterations, alpha, tol, showstatus) -> Vector{<:AbstractFloat}

Obtiene ponderadores óptimos de LASSO a través de una aproximación iterativa al
problema de minimización del error cuadrático medio de la combinación lineal de
estimadores de inflación en `tray_infl` utilizando la trayectoria de inflación
paramétrica `tray_infl_param`, regularizada con la norma L1 de los ponderadores,
ponderada por el parámetro `lambda`.

Los parámetros opcionales son: 
- `maxiterations` (`Integer`): número máximo de iteraciones. Por defecto,
  `1000`. 
- `alpha` (`AbstractFloat`): parámetro de aproximación o avance del algoritmo de
  gradiente próximo. Por defecto, `0.005`.
- `tol` (`AbstractFloat`): desviación absoluta de la función de costo. Si la
  función de costo varía en términos absolutos menos que `tol` de una iteración
  a otra, el algoritmo de gradiente se detiene. Por defecto, `1e-4`. 
- `showstatus` (`Bool`): mostrar estado del algoritmo iterativo. Por defecto,
  `true`.

Devuelve un vector con los ponderadores asociados a cada estimador en las
columnas de `tray_infl`.

Ver también: [`combination_weights`](@ref), [`ridge_combination_weights`](@ref)
"""
function lasso_combination_weights(tray_infl::AbstractArray{F, 3}, tray_infl_param, lambda; 
    maxiterations=1000, alpha=F(0.005), tol = F(1e-4), showstatus=true) where F

    T, n, _ = size(tray_infl)

    λ = convert(F, lambda)
    α = convert(F, alpha)
    β = zeros(F, n)
    cost_vals = zeros(F, maxiterations)
    XᵀX, Xᵀπ = average_mats(tray_infl, tray_infl_param)
    πᵀπ = sum(x -> x^2, tray_infl_param) / T

    # Proximal gradient descent
    for t in 1:maxiterations
        # Computar el gradiente respecto de β
        grad = (XᵀX * β) - Xᵀπ
		
		# Proximal gradient 
		β = proxl1norm(β - α*grad, α*λ)

        # Métrica de costo 
        mse = β'*XᵀX*β - 2*β'*Xᵀπ + πᵀπ
		cost_vals[t] = mse + λ*sum(abs, β)
		abstol = t > 1 ? abs(cost_vals[t] - cost_vals[t-1]) : 10e0

		if showstatus && t % 100 == 0
			println("Iter: ", t, " cost = ", cost_vals[t], "  |Δcost| = ", abstol)
		end

        abstol < tol && break 
	end
	
	β, cost_vals
end

# Operador próximo para la norma L1 del vector z
function proxl1norm(z, α)
    proxl1 = z - clamp.(z, Ref(-α), Ref(α))
    proxl1
end
