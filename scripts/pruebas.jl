using DrWatson
@quickactivate "HEMI"

# Capitalización de índices a partir de objeto VarCPIBase
    base_ipc = capitalize(gt10.v, gt10.baseindex)

# Lista de posicion de gastos básicos a excluir

list_exc = [35,30,190,36,37,40,31,104,162,32,33,159,193,161,279]


# Hacer esas posiciones cero, en el vector de pesos
w_exc = copy(gt10.w)
for i in list_exc w_exc[i] = 0 end

# Renormalización de pesos
w_exc = w_exc / sum(w_exc)


## ########

v_exc = ([35,30,190,36,37,40,31,104,162,32,33,159,193,161,218],[25, 40, 45, 50, 55, 70, 75, 80, 85, 275, 279])
base_ipc = (Matrix{Float32}, Matrix{Float32})
w_exc = (Vector{Float32}, Vector{Float32})
for i in 1:length(gtdata.base)
    # Capitalizar los índices de precios a partir del objeto cs.VarCPIBase[i]
    base_ipc = capitalize(gtdata.base[i].v, gtdata.base[i].baseindex)
    # Copia de la lista original de pesos desde cs.base[i]
    w_exc = copy(gtdata.base[i].w)
    # Asignación de peso cero a los gastos básicos de la lista de exclusión (v_exc[i]) (j itera sobre los elementos de la lista de exclusión)
        for j in v_exc[i] w_exc[j] = 0.0 end
    # Renormalización de pesos
    w_exc = w_exc / sum(w_exc)
    # Obtener IPC
    cpi_exc = sum(base_ipc.*w_exc', dims=2)
    # Obtener variación intermensual
    varinterm(cpi_exc)
end