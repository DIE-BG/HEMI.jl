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


##########
