### A Pluto.jl notebook ###
# v0.14.5

using Markdown
using InteractiveUtils

# ╔═╡ c9ebe832-4ecb-4865-892e-c56733a6338d
begin
	using PlutoUI 
	PlutoUI.TableOfContents(title="📚 Contenidos", aside=true)
end

# ╔═╡ ebf005c0-9bd4-11eb-228b-65de0518f560
using DrWatson

# ╔═╡ 4b0a7d10-9bd5-11eb-076c-6d192fd383f2
begin
	@quickactivate "HEMI"
		
	using Dates, CPIDataBase
	using JLD2
end

# ╔═╡ a7925945-2f15-4249-a7fc-e92f69812741
md"""
# Desarrollo de modelo de cómputo de medidas de inflación
"""

# ╔═╡ 50e4bd50-a5be-49f4-ac11-d61b83ac9ffd
md"""
Se activa el entorno de trabajo y se cargan las librerías necesarias. Este sería un flujo de trabajo habitual en muchos scripts.
"""

# ╔═╡ 0afd16b6-16b2-4ba9-8859-a3b9416e2fbf
md"""
Carga de datos de las bases del IPC de Guatemala
"""

# ╔═╡ 09366070-9bd5-11eb-23bc-4d0a0c7b69c9
begin 
	@load datadir("guatemala", "gtdata.jld2") gt00 gt10
end

# ╔═╡ dc8257fe-26c3-41ed-9d94-e1defe0ddeec
md"""
Se plantea un modelo de cómputo de medidas de inflación para la estructura `CountryStructure` a través de un tipo concreto del tipo abstracto `InflationFunction`. Este método tiene las siguientes ventajas: 
- Organiza las funciones de cómputo de inflación bajo el sistema de tipos de Julia.
- El nombre de la medida de inflación se puede embeber en el objeto. 
- Se pueden agregar parámetros que sirvan en el cómputo. 
- Se separa la implementación del resumen intermensual del cómputo de la trayectoria de inflación interanual.
"""

# ╔═╡ 7996fe10-9bd5-11eb-2a16-e5d27d1a40b2
begin
	abstract type InflationFunction <: Function end
	
	Base.@kwdef struct InflationTotalCPI <: InflationFunction
		name::String = "Variación interanual IPC"
	end
	
	## Las funciones sobre VarCPIBase resumen en variaciones intermensuales
	
	# Función para bases cuyo índice base es un escalar
	function (inflfn::InflationTotalCPI)(base::VarCPIBase{T, T}) where {T <: AbstractFloat} 
		base_ipc = capitalize(base.v, base.baseindex)
		ipc = base_ipc * base.w / base.baseindex
		CPIDataBase.varinterm!(ipc, ipc, 100)
		ipc
	end
	
	# Función para bases cuyos índices base son un vector
	function (inflfn::InflationTotalCPI)(base::VarCPIBase{T, B}) where {T <: AbstractFloat, B <: AbstractVector{T}} 
		base_ipc = capitalize(base.v, base.baseindex)
		# Obtener índice base y normalizar a 100
		baseindex = base.baseindex' * base.w
		ipc = 100 * (base_ipc * base.w / baseindex)
		CPIDataBase.varinterm!(ipc, ipc, 100)
		ipc
	end
	
	## La función sobre CountryStructure devuelve la inflación interanual sobre todas las bases que componen 
	
	function (inflfn::InflationTotalCPI)(cs::CountryStructure) 
		vm = mapfoldl(inflfn, vcat, cs.base)
		CPIDataBase.capitalize!(vm, vm, 100)
		varinteran(vm)
	end
	
end

# ╔═╡ 2080ffc8-2dcf-45af-b212-e95afd7da33e
md"""
A continuación una demostración de cómo se pueden utilizar dichas funciones:
"""

# ╔═╡ d604f300-9bd5-11eb-0fd3-076a90ce432f
totalfn = InflationTotalCPI()

# ╔═╡ e823c610-9bd5-11eb-1905-c1b4a88135b6
# Variaciones intermensuales IPC base 2000
totalfn(gt00)

# ╔═╡ 82889d70-9bd6-11eb-35c4-410299dbb423
# Variaciones intermensuales IPC base 2010
totalfn(gt10)

# ╔═╡ 24549910-9bd7-11eb-3466-fdf2a639093b
# Estructura de país 
gtdata = UniformCountryStructure(gt00, gt10)

# ╔═╡ 30bba58e-9bd7-11eb-1a3f-9996f23c14b9
# Inflación interanual a través de fórmula IPC
totalfn(gtdata)

# ╔═╡ 970aad80-9bd9-11eb-2e33-59c4d19ca7be
md"""
## Prueba con base con diferentes índices

En este ejemplo creamos una base de variaciones intermensuales hipotética, cuya base se sitúa en 2006, pero se tienen datos a partir de noviembre de 2009 (similar a la base del IPC de Nicaragua) y que, por lo tanto, tiene índices base diferentes todos de 100. 
"""

# ╔═╡ d978fedd-c923-41ac-83d6-cdb5796aaa31
begin 
	GB = 200
	fechas = Date(2009,12):Month(1):Date(2016,12)
	T = length(fechas)
	v06 = rand(T, GB) .- 0.25
	w06 = rand(GB)
	w06 = 100 * w06 / sum(w06)
	bases = rand(110:0.5:120, GB)
	
	nic06 = VarCPIBase(v06, w06, fechas, bases)
end

# ╔═╡ 20b2e8ed-e0ab-4f01-a8a3-aa53b19b26db
# Debe buscar el método que recibe un vector en los índices base
@which totalfn(nic06)

# ╔═╡ 049f2920-8666-462f-8e6e-bb27d52df045
totalfn(nic06)

# ╔═╡ 83a4d9de-3884-489a-ac79-a197b99bf6b5
nicdata = UniformCountryStructure(nic06)

# ╔═╡ baa40050-d2f6-4121-bd42-ff0230cb399a
infl_nic = totalfn(nicdata)

# ╔═╡ e71f6a82-6993-4ab6-9047-45e9f44546cf
length(infl_nic)

# ╔═╡ b925247c-b121-4f77-b0ac-cc3d7f76b8f8
md"""
## Combinación hipotética con otra base

Es muy fácil combinar bases en una nueva estructura `CountryStructure`. Esto permite ampliar rápidamente el cómputo cuando surja una nueva base del IPC. En este ejemplo, podemos unir la información con una nueva base del IPC hipotética.
"""

# ╔═╡ a998378f-91b0-46b1-9b26-3a61f055beeb
gtdata′ = MixedCountryStructure(gt00, gt10, nic06)

# ╔═╡ 3c56c9d5-5323-4f78-a765-449588615d84
totalfn(gtdata′)

# ╔═╡ 3a1f7446-c688-4abb-b1d6-41dacb2fe41b
gtdata′.base |> typeof

# ╔═╡ fd0d092b-75b0-4787-bc69-bfe82aa15da7
md"""
### Ojo con la inestabilidad de tipos

Al mezclar bases de diferentes tipos, esto resulta en funciones no estables en tipo, a diferencia de utilizar un tipo `UniformCountryStructure`. Esto podría resolverse en futuras versiones. 
"""

# ╔═╡ 3376d9cd-9e61-4834-a866-5c108b1331df
with_terminal() do 
	@code_warntype totalfn(gtdata′)
end

# ╔═╡ 3e5a7e7b-3e4b-439b-b4f7-f40630793465
with_terminal() do 
	@code_warntype totalfn(gtdata)	
end

# ╔═╡ Cell order:
# ╟─a7925945-2f15-4249-a7fc-e92f69812741
# ╠═c9ebe832-4ecb-4865-892e-c56733a6338d
# ╟─50e4bd50-a5be-49f4-ac11-d61b83ac9ffd
# ╠═ebf005c0-9bd4-11eb-228b-65de0518f560
# ╠═4b0a7d10-9bd5-11eb-076c-6d192fd383f2
# ╟─0afd16b6-16b2-4ba9-8859-a3b9416e2fbf
# ╠═09366070-9bd5-11eb-23bc-4d0a0c7b69c9
# ╟─dc8257fe-26c3-41ed-9d94-e1defe0ddeec
# ╠═7996fe10-9bd5-11eb-2a16-e5d27d1a40b2
# ╟─2080ffc8-2dcf-45af-b212-e95afd7da33e
# ╠═d604f300-9bd5-11eb-0fd3-076a90ce432f
# ╠═e823c610-9bd5-11eb-1905-c1b4a88135b6
# ╠═82889d70-9bd6-11eb-35c4-410299dbb423
# ╠═24549910-9bd7-11eb-3466-fdf2a639093b
# ╠═30bba58e-9bd7-11eb-1a3f-9996f23c14b9
# ╟─970aad80-9bd9-11eb-2e33-59c4d19ca7be
# ╠═d978fedd-c923-41ac-83d6-cdb5796aaa31
# ╠═20b2e8ed-e0ab-4f01-a8a3-aa53b19b26db
# ╠═049f2920-8666-462f-8e6e-bb27d52df045
# ╠═83a4d9de-3884-489a-ac79-a197b99bf6b5
# ╠═baa40050-d2f6-4121-bd42-ff0230cb399a
# ╠═e71f6a82-6993-4ab6-9047-45e9f44546cf
# ╟─b925247c-b121-4f77-b0ac-cc3d7f76b8f8
# ╠═a998378f-91b0-46b1-9b26-3a61f055beeb
# ╠═3c56c9d5-5323-4f78-a765-449588615d84
# ╠═3a1f7446-c688-4abb-b1d6-41dacb2fe41b
# ╟─fd0d092b-75b0-4787-bc69-bfe82aa15da7
# ╠═3376d9cd-9e61-4834-a866-5c108b1331df
# ╠═3e5a7e7b-3e4b-439b-b4f7-f40630793465
