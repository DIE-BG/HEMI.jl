### A Pluto.jl notebook ###
# v0.14.7

using Markdown
using InteractiveUtils

# ╔═╡ 723d8fc4-d796-4087-a4d6-263e8f3e5581
using Pkg

# ╔═╡ f4eb4db0-f07a-11eb-1563-b36d9bfe86bd
using PlutoUI

# ╔═╡ bc797138-a581-45f7-bcc2-f0f3665161f5
begin
md""" ## Evaluación de Medidas de Inflación 2020
	  # Medidas Basadas en Exclusión Fija """
end

# ╔═╡ 51637129-a435-4693-ad12-b6e42058fe10
md""" Se evaluaron medidas de inflación subyacente de exlcusión de fija de precios de gastos básicos seleccionados.

Las medidas evaluadas fueron las siguientes:
 - Exclusión Fija Óptima 
 - Exclusión Fija de Alimentos y Energéticos (variante 11)
 - Exclusión Fija de Energéticos
 - Exclusión Fija de Alimentos y Energéticos (variante 9)


Adicionalmente se llevó a cabo un análisis comparativo en la Exclusión Fija óptima combinando los vectores de exclusión de la Evaluación 2019 y la Evaluación 2020

Las evaluaciones se llevaron a cabo tomando en cuenta los siguientes criterios: 
 - Período final de evaluación: Diciembre 2020
 - Estadistico de Evaluación: MSE
 - Número de simulaciones 125,000
 - Función de tendencia: caminata aleatoria calibrada
 - Trayectoria de inflación paramétrica: Variación interanual del IPC con cambios de base
 - Método de remuestreo: Block bootstrap estacionario con tamaño de bloque 36 y metodología de remuestreo por meses de ocurrencia.
 
"""

# ╔═╡ 56a9f76d-7637-4636-85fe-2683f56cfa7e
md""" ## Exclusión Fija Óptima """

# ╔═╡ 51de5379-506f-49d2-995a-1ba9a6110d1e
md""" Para la determinación de la cantidad óptima de gastos básicos a excluir de cada base se llevó a cabo, en primera instancia, la optimización de la base 2010.

"""

# ╔═╡ Cell order:
# ╠═723d8fc4-d796-4087-a4d6-263e8f3e5581
# ╟─f4eb4db0-f07a-11eb-1563-b36d9bfe86bd
# ╟─bc797138-a581-45f7-bcc2-f0f3665161f5
# ╟─51637129-a435-4693-ad12-b6e42058fe10
# ╟─56a9f76d-7637-4636-85fe-2683f56cfa7e
# ╠═51de5379-506f-49d2-995a-1ba9a6110d1e
