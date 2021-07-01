# Lista de posicion de gastos básicos 
list = [20, 55, 48, 275, 85, 96, 88, 96, 14, 279] # posiciones
# Hacer esas posiciones cero, en el vector de pesos
for i in list gtdata[2].w[i] = 0 end

# Renormalización de pesos


w_exc = gtdata[2].w / sum(gtdata[2].w)

ipc_prueba = full_gt10.ipc .* w_exc'
##########
ipc_prueba2[122, 1] = 0
for i in 122 ipc_prueba2[i] = sum(ipc_prueba[i,:]) end