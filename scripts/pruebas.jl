using DrWatson
@quickactivate "HEMI"

##
v_exc = (v_exc00, v_exc10)
if size(gt10.v)[2] == 218 exc = v_exc[1] else exc = v_exc[2] end   
# Capitalizar los índices de precios a partir del objeto base::VarCPIBase
base_ipc= capitalize(gt10.v, gt10.baseindex)
# Copia de la lista original de pesos desde cs.base[i]
w_exc = copy(gt10.w)
# Asignación de peso cero a los gastos básicos de la lista de exclusión (v_exc[i]) 
# (j itera sobre los elementos de la lista de exclusión)
    for j in exc w_exc[j] = 0.0 end
# Renormalización de pesos
w_exc = w_exc / sum(w_exc)
# Obtener Ipc con exclusión 
cpi_exc = sum(base_ipc.*w_exc', dims=2)
# Obtener variación intermensual
varm_cpi_exc =  varinterm(cpi_exc)
varm_cpi_exc


## 
v_exc00 = [35,30,190,36,37,40,31,104,162,32,33,159,193,161,218]
v_exc10 = [25, 40, 45, 50, 55, 70, 75, 80, 85, 275, 279]


inst = InflationFixedExclusionCPI((v_exc00, v_exc10))
inst(gt10)
inst(gt00)
inst(gtdata)