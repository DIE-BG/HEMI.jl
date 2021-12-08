"""
    absme_combination_weights(tray_infl::AbstractArray{F, 3}, tray_infl_param; 
        restrict_all::Bool = true, 
        show_status::Bool = false) where F -> Vector{F}

Obtiene ponderadores no negativos, cuya suma es igual a 1, para el problema de
combinación lineal que minimiza el valor absoluto de error medio. Estos
ponderadores se pueden interpretar como participaciones en la combinación
lineal. 

Los parámetros opcionales son: 
- `show_status::Bool = false`: mostrar estado del proceso de optimización con
  Ipopt y JuMP. 
- `restrict_all::Bool = true`: indica si aplicar la restricción de la suma de
  ponderadores a todas las entradas del vector de ponderaciones. Si es `false`,
  se aplica la restricción a partir de la segunda entrada. Esto es para que si
  el primer ponderador corresponde a un término constante, este no sea
  restringido. 
"""
function absme_combination_weights(
    tray_infl::AbstractArray{F, 3}, tray_infl_param; 
    restrict_all::Bool = true, 
    show_status::Bool = false) where F
  
      # Insumos para la función de pérdida de valor absoluto
      n = size(tray_infl, 2)
      ē = vec(mean(tray_infl .- tray_infl_param, dims=[1,3]))
  
      # Si restrict_all == false, se restringe la suma de ponderadores igual a 1 a
      # partir de la segunda posición del vector de ponderadores β
      r = restrict_all ? 1 : 2
  
      # Problema de optimización restringida
      model = Model(Ipopt.Optimizer)
      @variable(model, β[1:n] >= 0)
      @constraint(model, sum(β[r:n]) == 1)
  
      # Error medio de la combinación como la combinación de los errores medios
      @variable(model, me)
      @constraint(model, me == dot(ē, β))
  
      # Restricción de valor absoluto
      @variable(model, absme)
      @constraints(model, begin absme >= me; absme >= -me end)
  
      @objective(model, Min, absme)
  
      # Obtener la solución numérica 
      show_status || set_silent(model)
      optimize!(model)
      convert.(F, JuMP.value.(β))
  end