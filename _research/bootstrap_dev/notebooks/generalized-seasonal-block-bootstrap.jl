### A Pluto.jl notebook ###
# v0.14.5

using Markdown
using InteractiveUtils

# ╔═╡ d5e98234-1973-4504-8897-f738a808c126
using Plots

# ╔═╡ 4595ab46-1b51-4eab-b5f2-507a4829f071
using Statistics

# ╔═╡ 29a94110-6fac-4b72-b093-e0ff0169638a
md"""
## Generar una serie de tiempo estacional
"""

# ╔═╡ 91f9710c-8b39-415a-adc6-1fa98f8b7684
T = 120

# ╔═╡ 6055e5a0-b508-11eb-0573-45172f658df1
begin
	ϵ = randn(T)
	x = zeros(T)
	
	x0 = 0.5
	for t in 2:T
		x[t] = 0.25x[t-1] + 0.7(t % 6 == 0) + 0.9(t % 12 == 0)*(-1)^(t ÷ 12) + 0.25ϵ[t] + 0.15ϵ[t-1]
	end
	x
end

# ╔═╡ ce6fdd2b-e8c7-45b0-81bb-a0b6b27a3627
plot(x)

# ╔═╡ b5f7b71c-6041-4a12-ac43-32130b4a66c5
md"""
## Desarrollo del Generalized Seasonal Block Bootstrap (GSBB)
"""

# ╔═╡ af703189-805c-4a3d-a1d4-9d0f4d7650ea
d = 12

# ╔═╡ 2fa9ca1a-ef68-45a4-a2dc-07daaf06cb6c
b = 25

# ╔═╡ b351de7d-a44c-41ba-8c71-c358263bebf2
l = T ÷ b

# ╔═╡ 7ad8f0e2-f619-4d0f-bb6e-51045f43b689
R2 = [(T - b - t) ÷ d for t in 1:12]

# ╔═╡ f1caa077-129b-426f-a960-f9b5675a13fb
S = [t + n*d for t in 1:12, n in 0:9]

# ╔═╡ 2a1fcebd-3d9d-4f45-b9aa-063fde8dc6c5
1:10 |> typeof

# ╔═╡ 052523fb-5b7a-4f5e-b664-5765a0f7ab8c
Ids = Vector{UnitRange{Int}}(undef, 0)

# ╔═╡ 984a5365-4d66-401f-af9d-a58a57559c76
for t in 1:b:120
	R1 = (t - 1) ÷ d
	R2 = (T - b - t) ÷ d
	
	St = (t - d*R1):d:(t+ d*R2)
	kt = rand(St)
	push!(Ids, kt:(kt+b-1))
end

# ╔═╡ e58ac04d-cccd-41eb-a5d5-389a1b09ea1d
Ids

# ╔═╡ 2ad3f37c-636c-4a40-968c-266f0faecad6
mapreduce(r -> length(r), +, Ids)

# ╔═╡ 3ada7301-c34d-4e09-be11-6cfcf8ad3017
md"""
Desarrollo de funciones
"""

# ╔═╡ a0c91025-5178-4885-92a0-2cc73bd08d37
begin
	# Función para obtener índices de remuestreo
	function dbootinds_gsbb(data, d, b)
		T = size(data, 1)
		l = T ÷ b
		ids = Vector{UnitRange{Int}}(undef, 0)
		
		for t in 1:b:T
			R1 = (t - 1) ÷ d
			R2 = (T - b - t) ÷ d
	
			St = (t - d*R1):d:(t+ d*R2)
			kt = rand(St)
			
			push!(ids, kt:(kt+b-1))
		end
		final_ids = mapreduce(r -> collect(r), vcat, ids)[1:T]
	end
	
	# Función para remuestrear
	function resample_gsbb(data, d, b)
		ids = dbootinds_gsbb(data, d, b)
		data[ids]
	end
end

# ╔═╡ 8ff04927-1751-4787-995c-a3b0ae12a780
dbootinds_gsbb(x, 12, 5)

# ╔═╡ 6e465ec5-5081-4e72-bdfb-e57b3d3c6b54
begin
	plot(x, label="Original")
	plot!(resample_gsbb(x, 12, 12), label="Remuestreada")
end

# ╔═╡ 87c42585-cb6d-4326-9ff9-8bc66938eafb
md"""
## Evaluación MSE del modelo
"""

# ╔═╡ ef5a1134-5d20-44bf-98f4-828367951c0b
x̄ = mean(x)

# ╔═╡ 1c678a5e-0ccc-40f9-81c2-a14124d093a0
map(1:25) do b
	mse = map(1:1000) do k 
		boot_x = resample_gsbb(x, 12, b)
		(mean(boot_x) - x̄) ^ 2
	end |> mean
	mse
end |> mse_b -> plot(mse_b, 
	label="MSE en función de tamaño de bloque")

# ╔═╡ Cell order:
# ╠═d5e98234-1973-4504-8897-f738a808c126
# ╟─29a94110-6fac-4b72-b093-e0ff0169638a
# ╠═91f9710c-8b39-415a-adc6-1fa98f8b7684
# ╠═6055e5a0-b508-11eb-0573-45172f658df1
# ╠═ce6fdd2b-e8c7-45b0-81bb-a0b6b27a3627
# ╟─b5f7b71c-6041-4a12-ac43-32130b4a66c5
# ╠═af703189-805c-4a3d-a1d4-9d0f4d7650ea
# ╠═2fa9ca1a-ef68-45a4-a2dc-07daaf06cb6c
# ╠═b351de7d-a44c-41ba-8c71-c358263bebf2
# ╠═7ad8f0e2-f619-4d0f-bb6e-51045f43b689
# ╠═f1caa077-129b-426f-a960-f9b5675a13fb
# ╠═2a1fcebd-3d9d-4f45-b9aa-063fde8dc6c5
# ╠═052523fb-5b7a-4f5e-b664-5765a0f7ab8c
# ╠═984a5365-4d66-401f-af9d-a58a57559c76
# ╠═e58ac04d-cccd-41eb-a5d5-389a1b09ea1d
# ╠═2ad3f37c-636c-4a40-968c-266f0faecad6
# ╟─3ada7301-c34d-4e09-be11-6cfcf8ad3017
# ╠═a0c91025-5178-4885-92a0-2cc73bd08d37
# ╠═8ff04927-1751-4787-995c-a3b0ae12a780
# ╠═6e465ec5-5081-4e72-bdfb-e57b3d3c6b54
# ╟─87c42585-cb6d-4326-9ff9-8bc66938eafb
# ╠═4595ab46-1b51-4eab-b5f2-507a4829f071
# ╠═ef5a1134-5d20-44bf-98f4-828367951c0b
# ╠═1c678a5e-0ccc-40f9-81c2-a14124d093a0
