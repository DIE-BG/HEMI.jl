# load_param.jl - Load param from MATLAB
using DrWatson
@quickactivate "HEMI"

## Obtener inflación paramétrica

using MAT
using JLD2

vars = matread(datadir("param", "param_ipc_cb.mat"))
# nov-01 -> dic-20 (229 obs)
tray_infl_pob = vec(vars["tray_infl_pob"])[12:end]

# Guardar parámetro
@save datadir("param", "gt_param_ipc_cb.jld2") tray_infl_pob