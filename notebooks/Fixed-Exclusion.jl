### A Pluto.jl notebook ###
# v0.14.7

using Markdown
using InteractiveUtils

# ╔═╡ 9f220d09-0345-45ae-9607-81fa087851a2
begin
	import Pkg
	Pkg.activate("..")
	
	using PlutoUI
	using Revise
	using DrWatson, HEMI, Plots

end

# ╔═╡ 0b4777bd-43a2-4c68-8a52-c5d825f1da91
Pkg.add("DataFrames")


# ╔═╡ 5bb46960-3351-495e-a774-11b1a7a16256
using DataFrames

# ╔═╡ efce479b-3e7f-4e36-98fc-1292247d3147
PlutoUI.TableOfContents(aside=true, title="Contenido", depth=2)

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
md""" ## Exclusión Fija Óptima 
"""

# ╔═╡ 5359bbb3-867b-4fbc-88dc-74cc14d602c5
md""" ### Base 2000 """

# ╔═╡ 51de5379-506f-49d2-995a-1ba9a6110d1e
md""" Para la determinación de la cantidad óptima de gastos básicos a excluir de cada base se llevó a cabo, en primera instancia, la optimización de la base 2000, utilizando únicamente los datos de dicha base.

En primer lugar se ordenaron los gastos básicos según su volatilidad (desviación estándar de la variación interanual histórica de cada uno). 

Luego, se realizó la evaluación agregando un gasto básico a la vez en el vector de exclusión. 

El vector de exclusión para la base 2000, en a Evaluación 2019 fue:

Base 2000: [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161]

Correspondiente a los siguientes 14 gastos básicos:
 - Cebolla
 - Tomate
 - Otras cuotas fijas y extraordinarias en la educación preprimaria y primaria
 - Papa o patata
 - Zanahoria
 - Culantro o cilantro
 - Güisquil
 - Gastos derivados del gas manufacturado y natural y gases licuados del petróleo
 - Transporte aéreo
 - Otras verduras y hortalizas
 - Frijol
 - Gasolina
 - Otras Cuotas fijas y extraordinarias en la eduación secundaria
 - Transporte Urbano.




"""

# ╔═╡ 65fec4ed-aacb-453f-9823-a1a9a19defb4
md""" ### Algoritmo de creación de vectores de exclusión """

# ╔═╡ 8b72a157-cece-4fd9-8f51-21a1a9dff5cc
md""" Desviación estándar de las variaciones interanuales"""

# ╔═╡ ac12f804-3450-43d5-87a0-732ef2a80ec6
estd = std(gt00.v |> capitalize |> varinteran, dims=1)

# ╔═╡ a8fa3045-3c5d-41ee-8593-d8f7ef6dd323
begin
df = DataFrame(num = collect(1:218), Desv = vec(estd))
df = sort(df, "Desv", rev=true)
end

# ╔═╡ f4e54bda-8d61-4bc1-b35f-5521ade103ee
vec_v = df[!,:num]

# ╔═╡ 23c226d2-5a6d-4f20-9f3e-b923f031a930
md""" Generación de vectores de exclusión incluyendo un gasto básico a la vez"""

# ╔═╡ 3ad6fcc8-88b2-4a47-ab7c-232e04dedf0d
begin
v_exc = []
for i in 1:length(vec_v)-1
   exc = vec_v[1:i]
   append!(v_exc, [exc])
end
end

# ╔═╡ fdfc4ff6-85f5-4b0d-96d5-25749c15f199
v_exc

# ╔═╡ cfc2c2e0-d00d-41a8-8dfa-c3b3c9e0f817
v_exc00 =  [35, 30, 190, 36, 37, 40, 31, 104, 162, 32, 33, 159, 193, 161, 50, 160, 21, 163, 3, 4, 97, 2, 27, 1, 191, 188]

# ╔═╡ 5f8fa39b-67a9-4773-ac30-7644cf1ba0cf
md""" ### Base 2010 """

# ╔═╡ 03a8ea51-a6dc-4d76-af98-b0a50db73255
md""" Una vez optimizada la base 2010, se tomó como dada la exclusión óptima encontrada en la sección anterior, y se procedio de la misma manera para la optimización usando datos hasta diciembre de 2000.

Vector de exclusión base 2010, Evaluación 2019:

Base 2010 = [29, 31, 116, 39, 46, 40, 30, 35, 186, 47, 197, 41, 22, 48, 185, 34, 184]

Correspondiente a los siguientes gastos básicos:

 - Tomate
 - Chile pimiento
 - Gas Propano
 - Cebolla
 - Culantro
 - Papa
 - Güisquil
 - Lechuga
 - Diesel
 - Hierbabuena
 - Servicio de transporte aéreo
 - Zanahoria
 - Aguacate
 - Otras legumbres y hortalizas
 - Gasolina regular
 - Repollo 
 - Gasolina superior

"""

# ╔═╡ 02ea33d9-59f3-4217-9819-04174217fdd5
md""" ### Algoritmo de creación de vectores de exclusión """

# ╔═╡ 7a9b00d9-a743-42b2-ac9d-2417168b7e48
est10 = std(gt10.v |> capitalize |> varinteran, dims=1)

# ╔═╡ 75ecec89-b4f2-4b02-bd11-b30360e353f2
begin
df_10 = DataFrame(num = collect(1:279), Desv = vec(est10))
df_10= sort(df_10, "Desv", rev=true)	
end

# ╔═╡ e24fe38a-3b76-46d6-8353-e0d29746baaf
vec_10 = df_10[!,:num]

# ╔═╡ 1e10bec6-f711-46b1-9473-d163664430fb
begin
v_exc10 = []
tot = []
total = []
for i in 1:length(vec_v)-1
   exc = vec_v[1:i]
   v_exc =  append!(v_exc10, [exc])
   tot = (v_exc00, v_exc10[i])
   total = append!(total, [tot])
end
end

# ╔═╡ b115164a-97b7-4d78-b774-0db5f2cf0039
total

# ╔═╡ 6f850efe-c063-4984-8e9b-58780bb53b35
md""" ## Resultados preliminares """

# ╔═╡ f1dbe1d8-062d-4312-8015-35ca79a7ae43
md""" Luego del proceso de evaluación con 125,000 simulaciones para ambas bases, se obtuvieron los siguientes vectores de exclusión:

#### Base 2000
Aumentó de 14 exclusiones a 26.
 - Cebolla
 - Tomate
 - Otras cuotas fijas y extraordinarias en la educación preprimaria y primaria
 - Papa o patata
 - Zanahoria
 - Culantro o cilantro
 - Güisquil
 - Gastos derivados del gas manufacturado y natural y gases licuados del petróleo
 - Transporte aéreo
 - Otras verduras y hortalizas
 - Frijol
 - Gasolina
 - Otras Cuotas fijas y extraordinarias en la eduación secundaria
 - Transporte Urbano.
 - Sal
 - Transporte Extraurbano
 - Aceites y vegetales
 - Servicio de Correo internacional
 - Pastas frescas y secas
 - Productos de tortillería
 - Materiales de hierro, zinc, metal y similares
 - Pan
 - Plátanos
 - Arroz
 - Inscripción de secundaria
 - Inscripción en prepirmaria y primaria

#### Base 2010
Disminuyó de 17 exclusiones a 5
 - Tomate
 - Chile pimiento
 - Gas propano
 - Cebolla
 - Culantro

"""




# ╔═╡ 13438ae2-c455-4f98-a63e-30d689b247b6
## Instancias generales
begin
gtdata_00 = gtdata[Date(2010, 12)]
resamplefn = ResampleSBB(36)
trendfn = TrendRandomWalk()
end

# ╔═╡ fbcf4923-f33c-48d2-a978-5613ef47b708
FxEx_00 = Dict(
    :inflfn => InflationFixedExclusionCPI.(v_exc), 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :nsim => 125000) |> dict_list

# ╔═╡ 21e9e51e-5c16-475e-ac70-e423d19161eb
begin
FxEx_10 = Dict(
    :inflfn => InflationFixedExclusionCPI.(total), 
    :resamplefn => resamplefn, 
    :trendfn => trendfn,
    :nsim => 10000) |> dict_list
end

# ╔═╡ Cell order:
# ╟─0b4777bd-43a2-4c68-8a52-c5d825f1da91
# ╟─5bb46960-3351-495e-a774-11b1a7a16256
# ╟─efce479b-3e7f-4e36-98fc-1292247d3147
# ╟─bc797138-a581-45f7-bcc2-f0f3665161f5
# ╟─51637129-a435-4693-ad12-b6e42058fe10
# ╟─56a9f76d-7637-4636-85fe-2683f56cfa7e
# ╟─5359bbb3-867b-4fbc-88dc-74cc14d602c5
# ╟─51de5379-506f-49d2-995a-1ba9a6110d1e
# ╟─65fec4ed-aacb-453f-9823-a1a9a19defb4
# ╟─8b72a157-cece-4fd9-8f51-21a1a9dff5cc
# ╠═ac12f804-3450-43d5-87a0-732ef2a80ec6
# ╠═a8fa3045-3c5d-41ee-8593-d8f7ef6dd323
# ╠═f4e54bda-8d61-4bc1-b35f-5521ade103ee
# ╟─23c226d2-5a6d-4f20-9f3e-b923f031a930
# ╠═3ad6fcc8-88b2-4a47-ab7c-232e04dedf0d
# ╠═fdfc4ff6-85f5-4b0d-96d5-25749c15f199
# ╠═fbcf4923-f33c-48d2-a978-5613ef47b708
# ╠═cfc2c2e0-d00d-41a8-8dfa-c3b3c9e0f817
# ╟─5f8fa39b-67a9-4773-ac30-7644cf1ba0cf
# ╟─03a8ea51-a6dc-4d76-af98-b0a50db73255
# ╟─02ea33d9-59f3-4217-9819-04174217fdd5
# ╠═7a9b00d9-a743-42b2-ac9d-2417168b7e48
# ╠═75ecec89-b4f2-4b02-bd11-b30360e353f2
# ╠═e24fe38a-3b76-46d6-8353-e0d29746baaf
# ╠═1e10bec6-f711-46b1-9473-d163664430fb
# ╠═b115164a-97b7-4d78-b774-0db5f2cf0039
# ╠═21e9e51e-5c16-475e-ac70-e423d19161eb
# ╟─6f850efe-c063-4984-8e9b-58780bb53b35
# ╟─f1dbe1d8-062d-4312-8015-35ca79a7ae43
# ╟─13438ae2-c455-4f98-a63e-30d689b247b6
# ╟─9f220d09-0345-45ae-9607-81fa087851a2
