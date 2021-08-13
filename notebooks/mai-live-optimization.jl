### A Pluto.jl notebook ###
# v0.15.1

using Markdown
using InteractiveUtils

# ╔═╡ c7e2e540-f6c8-11eb-260f-c35ca8dcef75
begin
	macro everywhere(procs, ex)
		return esc(:(Main.@everywhere $procs $ex))
	end
	workers() = filter(pid -> pid != Main.myid(), Main.workers())
	macro everywhere(ex)
		# have pluto handle evaluation on workspace process
		return esc(:(@everywhere workers() $ex; eval($(Expr(:quote, ex)))))
	end
end

# ╔═╡ bde5c9b7-aa0f-46ae-b653-2ece173e2863
begin
	@everywhere 1 using Distributed
	addprocs(args...; kwargs...) = @everywhere 1 addprocs($args...; $kwargs...)
	rmprocs(args...; kwargs...) = @everywhere 1 rmprocs($args...; $kwargs...)
end

# ╔═╡ 4f4aa3fd-a7e6-43d8-868b-d9cd88996d66
@everywhere 1 begin 
	import Pkg 
	Pkg.activate("C:\\Users\\Rodrigo\\Documents\\Julia\\HEMI\\")
	using HEMI 
end

# ╔═╡ b1418f05-3ee0-4e66-97cd-83cab0d46048
pwd()

# ╔═╡ 237770f0-c6f0-4c6d-827c-7acdcaffeb79


# ╔═╡ 67d4ad96-19cc-4dc8-ab41-05e8b0de098c


# ╔═╡ Cell order:
# ╠═c7e2e540-f6c8-11eb-260f-c35ca8dcef75
# ╠═bde5c9b7-aa0f-46ae-b653-2ece173e2863
# ╠═4f4aa3fd-a7e6-43d8-868b-d9cd88996d66
# ╠═b1418f05-3ee0-4e66-97cd-83cab0d46048
# ╠═237770f0-c6f0-4c6d-827c-7acdcaffeb79
# ╠═67d4ad96-19cc-4dc8-ab41-05e8b0de098c
