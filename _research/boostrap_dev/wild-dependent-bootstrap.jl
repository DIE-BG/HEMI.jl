### A Pluto.jl notebook ###
# v0.14.5

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : missing
        el
    end
end

# ╔═╡ 49e800a0-b440-11eb-1d5d-ffb2c90c94f5
begin
    import Pkg
    Pkg.activate(mktempdir())
    Pkg.add([
        Pkg.PackageSpec(name="Plots"),
        Pkg.PackageSpec(name="PlutoUI"),
		Pkg.PackageSpec(name="Distributions"),
		Pkg.PackageSpec(name="StatsBase"),
    ])
	using PlutoUI
    using Plots, Statistics, LinearAlgebra, Distributions, StatsBase
end

# ╔═╡ d134024e-a2e4-4c95-8105-bb094e499783
md"""
## Explorando la ventana de Bartlett

La ventana de Bartlett tiene la siguiente función: 

$$k(x) = \left\lbrace \begin{array}{cc}
1 - |x|, & |x| \leq 1 \\ 
0, & \text{otherwise} 
\end{array}\right.$$

"""

# ╔═╡ 8e17cd43-a867-474a-921f-fb0b9e5f1a14
# kernel de bartlett
function k(x; l=1)
	0 <= abs(x/l) <= 1 && return 1 - abs(x/l)
	0
end

# ╔═╡ bd172121-b027-4a2f-86c5-bbaae4a25870
plot(x -> k(x, l=2))

# ╔═╡ 96ede30e-0fc4-4996-970b-1e060aa2d15d
md"""
## Generando una distribución multivariada con covarianzas de Bartlett

Often in practice, we can take $\lbrace W_t\rbrace_{t=1}^n$ to be multivariate normal with mean 0 and covariance matrix $\Sigma_{l} = (\sigma_{ij})_{i,j=1, \ldots,n}$, where $\sigma_{ij} = a{(i − j)/l}$. 

Let $\mathbf{W} = (W_1, \ldots ,W_n)^\prime$ then $\mathbf{W}= \mathbf{\Sigma}^{1/2}\mathbf{Z}_n$, where $\mathbf{Z}_n ∼ N(0, I_{n \times n})$, with $I_{n \times n}$ being the $n \times n$ identity matrix. In the implementation of the DWB, $\mathbf{\Sigma}^{1/2}$ to be computed only once for each $l$ and given $a(·)$.
"""

# ╔═╡ 40dd0161-5c9a-413a-9d68-47fd3f1131af
@bind l_sel Slider(1:20, show_value=true)

# ╔═╡ 56e151a3-0f1b-4e97-8d40-3743eeb70366
l = l_sel

# ╔═╡ 365be671-0180-4227-84c0-8fb73045c7c5
T = 120

# ╔═╡ 34768ec2-22d7-4420-a1c6-5260632fb518
sigma = [k((i-j); l) for i in 1:T, j in 1:T]

# ╔═╡ b4e6f822-0963-4142-a4fe-be40309a0219
sigma_sqrt = sqrt(sigma)

# ╔═╡ 2a1ac330-ebbd-47c3-a539-9a1da8228d1b
N = MvNormal(zeros(T), I(T))

# ╔═╡ 2b42291b-f523-4ab6-a0c2-7eaca24b5d34
# Obtener serie de W, como en el paper
W = sigma_sqrt * rand(N)

# ╔═╡ 141b46ff-17c9-4962-836e-d7b058adf93f
begin 
	p1 = bar(autocov(W), label="Secuencia de autocovarianza")
	p2 = plot(W, label="Serie W para WDB")
	plot(p1, p2, layout = (2, 1))
end

# ╔═╡ 362c609c-1c4b-4626-94e1-11cb44600e75
mean(W), var(W)

# ╔═╡ 05026ae6-a8f9-44d5-bb79-f4bfdf1a6bd5
# Media del proceso W_t -> 0 ? 
map(1:1000) do i
	zt = sigma_sqrt * rand(N)
	mean(zt)
end |> mean

# ╔═╡ 75edbb58-e123-4b5b-b907-9117d76324ff
# Varianza del proceso W_t -> 1 ? 
map(1:1000) do i
	zt = sigma_sqrt * rand(N)
	var(zt)
end |> mean

# ╔═╡ 093ad6ac-7f3b-4307-8b65-58a384358212
md"""
Pendiente: 
- Investigar mejor la ventana de Bartlett en Hamilton.
- Construir una función de remuestreo con método de WildBootstrap, la matriz sqrt puede quedar fija, solo se debe remuestrear de la normal multivariada estándar
"""

# ╔═╡ cdf9d52c-b014-4e4d-8a1c-44e3f2d071b3
md"""
## Función de Wild Dependent Bootstrap
"""

# ╔═╡ e5eea79b-beaa-46ed-8fb6-efb71ae1cdf5
begin 

	struct WildDependentBootstrap{U}
		l::U
		T::Int
		sigma_sqrt::Matrix{U}

		# Se guarda la matriz sigma_sqrt, utilizada para generar nuevas secuencias W
		function WildDependentBootstrap(T::Int, l::U) where U <: AbstractFloat
			# Obtener la matriz para muestreo
			sigma = [k((i-j); l) for i in 1:T, j in 1:T]
			sigma_sqrt = sqrt(sigma)
			new{U}(l, T, sigma_sqrt)
		end
	end
	
	# Cómo remuestrea vector
	function (wdb::WildDependentBootstrap)(y::AbstractVecOrMat)
		N = MvNormal(zeros(eltype(y), wdb.T), I(wdb.T))
		W = wdb.sigma_sqrt * rand(N)
		ȳ = mean(y; dims=1)
		yres = @. ȳ + (y - ȳ)W
	end
	
end

# ╔═╡ 34b076c4-eb26-4a7c-b64d-2a1f4057c708
md"""
Probamos con un proceso AR(1)
"""

# ╔═╡ 9d1a4669-98a4-403d-87ff-2fb70189bbba
begin 
	z0 = 10
	rho = 0.8
	# rho2 = 0.25
	alpha = 2
	z = zeros(T)
	z[1] = z0
	# z[2] = 10-0.5
	for j in 2:T
		# z[j] = alpha + rho * z[j-1] + rho2 * z[j-2] + 0.1randn()
		z[j] = alpha + rho * z[j-1] + 0.05randn()
	end
	z |> mean
end

# ╔═╡ 841c0141-3d30-4ece-86b1-bea76fb1b7bf
fwdb = WildDependentBootstrap(T, l*1.0);

# ╔═╡ c60b92e8-ad15-4bfb-8da5-00f3a5389b53
boot_z = fwdb(z)

# ╔═╡ 6c875db4-f1ad-4463-bfdf-b3f442b43c4c
plot([z boot_z], label=["AR(1)" "Remuestreo WDB"])

# ╔═╡ a0753553-414e-4696-b700-e1606b0c2dff
# Media incondicional del proceso es
m = alpha / (1 - rho)

# ╔═╡ 2e4c493e-dc96-46b5-811d-50abb5ed87e4
# Computar el MSE de la media muestral con WDB
map(1:1000) do j
	# Obtener remuestreo wdb
	boot_z = fwdb(z)
	(mean(boot_z) - m) ^ 2
end |> mean

# ╔═╡ 4a76085b-441a-4acd-be23-0e54ab3e596c
# Computar el MSE de la media muestral con WDB como función de L
map(0.5:0.5:12) do l
	fwdb = WildDependentBootstrap(T, l)
	mse = map(1:1000) do j
		# Obtener remuestreo wdb
		boot_z = fwdb(z)
		(mean(boot_z) - m) ^ 2
	end |> mean
end |> x -> plot(x, label="MSE de método WDB con AR(1)", legend=:bottomright)

# ╔═╡ a549928b-bc60-45b5-af42-89a4a447f2ef
md"""
El menor MSE se obtiene con $l=1$, pues el proceso es AR(1). Si se cambia a un proceso con mayor complejidad, $l$ óptimo también aumentará. 
"""

# ╔═╡ Cell order:
# ╠═49e800a0-b440-11eb-1d5d-ffb2c90c94f5
# ╟─d134024e-a2e4-4c95-8105-bb094e499783
# ╠═8e17cd43-a867-474a-921f-fb0b9e5f1a14
# ╠═bd172121-b027-4a2f-86c5-bbaae4a25870
# ╟─96ede30e-0fc4-4996-970b-1e060aa2d15d
# ╠═40dd0161-5c9a-413a-9d68-47fd3f1131af
# ╠═56e151a3-0f1b-4e97-8d40-3743eeb70366
# ╠═365be671-0180-4227-84c0-8fb73045c7c5
# ╠═34768ec2-22d7-4420-a1c6-5260632fb518
# ╠═b4e6f822-0963-4142-a4fe-be40309a0219
# ╠═2a1ac330-ebbd-47c3-a539-9a1da8228d1b
# ╠═2b42291b-f523-4ab6-a0c2-7eaca24b5d34
# ╠═141b46ff-17c9-4962-836e-d7b058adf93f
# ╠═362c609c-1c4b-4626-94e1-11cb44600e75
# ╠═05026ae6-a8f9-44d5-bb79-f4bfdf1a6bd5
# ╠═75edbb58-e123-4b5b-b907-9117d76324ff
# ╟─093ad6ac-7f3b-4307-8b65-58a384358212
# ╟─cdf9d52c-b014-4e4d-8a1c-44e3f2d071b3
# ╠═e5eea79b-beaa-46ed-8fb6-efb71ae1cdf5
# ╟─34b076c4-eb26-4a7c-b64d-2a1f4057c708
# ╠═9d1a4669-98a4-403d-87ff-2fb70189bbba
# ╠═841c0141-3d30-4ece-86b1-bea76fb1b7bf
# ╠═c60b92e8-ad15-4bfb-8da5-00f3a5389b53
# ╟─6c875db4-f1ad-4463-bfdf-b3f442b43c4c
# ╠═a0753553-414e-4696-b700-e1606b0c2dff
# ╠═2e4c493e-dc96-46b5-811d-50abb5ed87e4
# ╠═4a76085b-441a-4acd-be23-0e54ab3e596c
# ╟─a549928b-bc60-45b5-af42-89a4a447f2ef
