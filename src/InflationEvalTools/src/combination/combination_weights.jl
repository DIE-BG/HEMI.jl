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
[`lasso_combination_weights`](@ref), [`share_combination_weights`](@ref),
[`elastic_combination_weights`](@ref). 
"""
function combination_weights(tray_infl, tray_infl_param)
    # Obtener matriz de ponderadores XᵀX y vector Xᵀπ
    XᵀX, Xᵀπ = average_mats(tray_infl, tray_infl_param)
    @debug "Determinante de la matriz de coeficientes" det(XᵀX)

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
    ridge_combination_weights(tray_infl, tray_infl_param, lambda; 
        penalize_all = true) -> Vector{<:AbstractFloat}

Obtiene ponderadores óptimos de Ridge a través de la solución analítica al
problema de minimización del error cuadrático medio de la combinación lineal de
estimadores de inflación en `tray_infl` utilizando la trayectoria de inflación
paramétrica `tray_infl_param`, regularizada con la norma L2 de los ponderadores,
ponderada por el parámetro `lambda`.

Devuelve un vector con los ponderadores asociados a cada estimador en las
columnas de `tray_infl`.

Los parámetros opcionales son:  
- `penalize_all` (`Bool`): indica si aplicar la regularización a todos los
  ponderadores. Si es falso, se aplica la regularización a partir del segundo al
  último componente del vector de ponderaciones. Por defecto es `true`.

Ver también: [`combination_weights`](@ref), [`lasso_combination_weights`](@ref),
[`share_combination_weights`](@ref), [`elastic_combination_weights`](@ref).
"""
function ridge_combination_weights(
    tray_infl::AbstractArray{F, 3}, tray_infl_param, lambda; 
    penalize_all = true) where F

    # Si lambda == 0, solución de mínimos cuadrados
    lambda == 0 && return combination_weights(tray_infl, tray_infl_param)

    # Obtener matriz de ponderadores XᵀX y vector Xᵀπ
    XᵀX, Xᵀπ = average_mats(tray_infl, tray_infl_param)
    λ = convert(F, lambda)
    n = size(tray_infl, 2)
    
    # Ponderadores de combinación óptima de Ridge
    Iₙ = I(n)
    # Si penalize_all=false, no se penaliza el primer componente, que debería
    # corresponder al intercepto de la regresión. Para esto, la primera columna
    # de tray_infl de contener 1's.
    if !penalize_all
        Iₙ[1] = 0
    end

    XᵀX′ = XᵀX + λ*Iₙ
    @debug "Determinante de la matriz de coeficientes" det(XᵀX) det(XᵀX′)
    a_ridge = XᵀX′ \ Xᵀπ
    a_ridge 
end


# Ponderadores de combinación lasso con parámetro de regularización lambda
"""
    lasso_combination_weights(tray_infl, tray_infl_param, lambda; 
        max_iterations::Int = 1000, 
        alpha = F(0.005), 
        tol = F(1e-4), 
        show_status = true, 
        return_cost = false, 
        penalize_all = true) -> Vector{<:AbstractFloat}

Obtiene ponderadores óptimos de LASSO a través de una aproximación iterativa al
problema de minimización del error cuadrático medio de la combinación lineal de
estimadores de inflación en `tray_infl` utilizando la trayectoria de inflación
paramétrica `tray_infl_param`, regularizada con la norma L1 de los ponderadores,
ponderada por el parámetro `lambda`.

Los parámetros opcionales son: 
- `max_iterations::Int = 1000`: número máximo de iteraciones. 
- `alpha::AbstractFloat = 0.001`: parámetro de aproximación o avance del
  algoritmo de gradiente próximo. 
- `tol::AbstractFloat = 1e-4`: desviación absoluta de la función de costo. Si la
  función de costo varía en términos absolutos menos que `tol` de una iteración
  a otra, el algoritmo de gradiente se detiene. 
- `show_status::Bool = true`: mostrar estado del algoritmo iterativo.
- `return_cost::Bool = false`: indica si devuelve el vector de historia de la
  función de costo de entrenamiento. 
- `penalize_all::Bool = true`: indica si aplicar la regularización a todos los
  ponderadores. Si es falso, se aplica la regularización a partir del segundo al
  último componente del vector de ponderaciones.

Devuelve un vector con los ponderadores asociados a cada estimador en las
columnas de `tray_infl`.

Ver también: [`combination_weights`](@ref), [`ridge_combination_weights`](@ref),
[`share_combination_weights`](@ref), [`elastic_combination_weights`](@ref).
"""
function lasso_combination_weights(
    tray_infl::AbstractArray{F, 3}, tray_infl_param, lambda; 
    max_iterations::Int = 1000, 
    alpha = F(0.001), 
    tol = F(1e-4), 
    show_status = true, 
    return_cost = false, 
    penalize_all = true) where F

    # Si lambda == 0, solución de mínimos cuadrados
    lambda == 0 && return combination_weights(tray_infl, tray_infl_param)

    T, n, _ = size(tray_infl)

    λ = convert(F, lambda)
    α = convert(F, alpha)
    β = zeros(F, n)
    cost_vals = zeros(F, max_iterations)
    XᵀX, Xᵀπ = average_mats(tray_infl, tray_infl_param)
    πᵀπ = mean(x -> x^2, tray_infl_param)

    if show_status
        println("Optimización iterativa para LASSO:")
        println("----------------------------------")
    end

    # Proximal gradient descent
    for t in 1:max_iterations
        # Computar el gradiente respecto de β
        grad = (XᵀX * β) - Xᵀπ
		
		# Proximal gradient 
		β = proxl1norm(β - α*grad, α*λ; penalize_all)

        # Métrica de costo = MSE + λΣᵢ|βᵢ|
        mse = β'*XᵀX*β - 2*β'*Xᵀπ + πᵀπ
        l1cost = penalize_all ? sum(abs, β) : sum(abs, (@view β[2:end]))
		cost_vals[t] = mse + λ*l1cost
		abstol = t > 1 ? abs(cost_vals[t] - cost_vals[t-1]) : 100f0

		if show_status && t % 100 == 0
			println("Iter: ", t, " cost = ", cost_vals[t], "  |Δcost| = ", abstol)
		end

        abstol < tol && break 
	end
	
    return_cost && return β, cost_vals
	β
end

# Operador próximo para la norma L1 del vector z
function proxl1norm(z, α; penalize_all = true)
    proxl1 = z - clamp.(z, Ref(-α), Ref(α))
    
    # penalize_all = false : no penalizar del intercepto 
    if !penalize_all
        proxl1[1] = z[1]
    end
    
    proxl1
end


## Ponderadores de combinación restringidos
# Se restringe el problema de optimización para que la suma de los ponderadores
# sea igual a 1 y que todas las ponderaciones sean no negativas.
"""
    function share_combination_weights(tray_infl::AbstractArray{F, 3}, tray_infl_param; 
        restrict_all::Bool = true, 
        show_status::Bool = false) where F -> Vector{F}

Obtiene ponderadores no negativos, cuya suma es igual a 1. Estos ponderadores se
pueden interpretar como participaciones en la combinación lineal. 

Los parámetros opcionales son: 
- `show_status::Bool = false`: mostrar estado del proceso de optimización con
  Ipopt y JuMP. 
- `restrict_all::Bool = true`: indica si aplicar la restricción de la suma de
  ponderadores a todas las entradas del vector de ponderaciones. Si es `false`,
  se aplica la restricción a partir de la segunda entrada. Esto es para que si
  el primer ponderador corresponde a un término constante, este no sea
  restringido. 
"""
function share_combination_weights(
    tray_infl::AbstractArray{F, 3}, tray_infl_param; 
    restrict_all::Bool = true, 
    show_status::Bool = false) where F

    # Insumos para la función de pérdida cuadrática 
    n = size(tray_infl, 2)
    XᵀX, Xᵀπ = average_mats(tray_infl, tray_infl_param)
    πᵀπ = mean(x -> x^2, tray_infl_param)

    # Si restrict_all == false, se restringe la suma de ponderadores igual a 1 a
    # partir de la segunda posición del vector de ponderadores β
    r = restrict_all ? 1 : 2

    # Problema de optimización restringida
    model = Model(Ipopt.Optimizer)
	@variable(model, β[1:n] >= 0)
	@constraint(model, sum(β[r:n]) == 1)
    @objective(model, Min, β'*XᵀX*β - 2*β'*Xᵀπ + πᵀπ)
	
    # Obtener la solución numérica 
	show_status || set_silent(model)
	optimize!(model)
	convert.(F, JuMP.value.(β))
end 



# Elastic net
"""
    elastic_combination_weights(tray_infl, tray_infl_param, lambda, gamma; 
        max_iterations::Int = 1000, 
        alpha = 0.001, 
        tol = 1e-4, 
        show_status = true, 
        return_cost = false, 
        penalize_all = true) -> Vector{<:AbstractFloat}

Obtiene ponderadores óptimos de [Elastic
Net](https://en.wikipedia.org/wiki/Elastic_net_regularization) a través de una
aproximación iterativa al problema de minimización del error cuadrático medio de
la combinación lineal de estimadores de inflación en `tray_infl` utilizando la
trayectoria de inflación paramétrica `tray_infl_param`, regularizada con la
norma L1 y L2 de los ponderadores, ponderada por el parámetro `lambda`. El
porcentaje de regularización de la norma L1 se controla con el parámetro
`gamma`.

Los parámetros opcionales son: 
- `max_iterations::Int = 1000`: número máximo de iteraciones. 
- `alpha::AbstractFloat = 0.001`: parámetro de aproximación o avance del
  algoritmo de gradiente próximo. 
- `tol::AbstractFloat = 1e-4`: desviación absoluta de la función de costo. Si la
  función de costo varía en términos absolutos menos que `tol` de una iteración
  a otra, el algoritmo de gradiente se detiene. 
- `show_status::Bool = true`: mostrar estado del algoritmo iterativo.
- `return_cost::Bool = false`: indica si devuelve el vector de historia de la
  función de costo de entrenamiento. 
- `penalize_all::Bool = true`: indica si aplicar la regularización a todos los
  ponderadores. Si es falso, se aplica la regularización a partir del segundo al
  último componente del vector de ponderaciones.

Devuelve un vector con los ponderadores asociados a cada estimador en las
columnas de `tray_infl`.

Ver también: [`combination_weights`](@ref), [`ridge_combination_weights`](@ref),
[`share_combination_weights`](@ref), [`lasso_combination_weights`](@ref).
"""
function elastic_combination_weights(
    tray_infl::AbstractArray{F, 3}, tray_infl_param, lambda, gamma; 
    max_iterations::Int = 1000, 
    alpha = F(0.001), 
    tol = F(1e-4), 
    show_status::Bool = true, 
    return_cost::Bool = false, 
    penalize_all::Bool = true) where F

    # Si lambda == 0, solución de mínimos cuadrados
    lambda == 0 && return combination_weights(tray_infl, tray_infl_param)

    n = size(tray_infl, 2)

    λ = convert(F, lambda)
    γ = convert(F, gamma)
    α = convert(F, alpha)
    β = zeros(F, n)
    cost_vals = zeros(F, max_iterations)
    XᵀX, Xᵀπ = average_mats(tray_infl, tray_infl_param)
    πᵀπ = mean(x -> x^2, tray_infl_param)

    if show_status
        println("Optimización iterativa para Elastic Net:")
        println("----------------------------------------")
    end

    # Proximal gradient descent
    for t in 1:max_iterations
        # Computar el gradiente respecto de β
        grad = (XᵀX * β) - Xᵀπ + λ*(1-γ)*β
		
		# Proximal gradient 
		β = proxl1norm(β - α*grad, α*λ*γ; penalize_all)

        # Métrica de costo = 0.5MSE + 0.5λ(1-γ)Σᵢ||βᵢ||^2 + γλΣᵢ|βᵢ|
        mse = β'*XᵀX*β - 2*β'*Xᵀπ + πᵀπ
        l1cost = penalize_all ? sum(abs, β) : sum(abs, (@view β[2:end]))
        l2cost = penalize_all ? sum(x -> x^2, β) : sum(x -> x^2, (@view β[2:end]))
		cost_vals[t] = (1//2)mse + λ*γ*l1cost + (1//2)λ*(1-γ)*l2cost 
		abstol = t > 1 ? abs(cost_vals[t] - cost_vals[t-1]) : 100f0

		if show_status && t % 100 == 0
			println("Iter: ", t, " cost = ", cost_vals[t], "  |Δcost| = ", abstol)
		end

        abstol < tol && break 
	end
	
    return_cost && return β, cost_vals
	β
end
