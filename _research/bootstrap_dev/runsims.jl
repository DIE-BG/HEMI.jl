using DrWatson
@quickactivate "bootstrap_dev"

# Ejecutar simulaciones en base 2000
run(`julia bootstrap_methods.jl 2000`)

# Ejecutar simulaciones en base 2010
run(`julia bootstrap_methods.jl 2010`)