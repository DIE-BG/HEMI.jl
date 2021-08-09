# InflationTotalCPI - Implementación para obtener la medida estándar de ritmo
# inflacionario a través de la variación interanual del IPC

struct InflationTotalCPI <: InflationFunction
end

# Extender el método para obtener el nombre de esta medida
measure_name(::InflationTotalCPI) = "Variación interanual IPC"
measure_tag(::InflationTotalCPI) = "Total"

# Las funciones sobre VarCPIBase deben resumir en variaciones intermensuales

# Método para objetos VarCPIBase cuyo índice base es un escalar
function (inflfn::InflationTotalCPI)(base::VarCPIBase{T, T}) where {T <: AbstractFloat} 
    base_ipc = capitalize(base.v, base.baseindex)
    ipc = base_ipc * base.w / base.baseindex
    varinterm!(ipc, ipc, 100)
    ipc
end

# Esta medida sí se comporta diferente de acuerdo a los índices base, por lo que 
# se define una versión que toma en cuenta los diferentes índices. Si la medida
# solamente genera resumen de las variaciones intermensuales, no es necesario.
# Método para objetos VarCPIBase cuyos índices base son un vector
function (inflfn::InflationTotalCPI)(base::VarCPIBase{T, B}) where {T <: AbstractFloat, B <: AbstractVector{T}} 
    base_ipc = capitalize(base.v, base.baseindex)
    # Obtener índice base y normalizar a 100
    baseindex = base.baseindex' * base.w
    ipc = 100 * (base_ipc * base.w / baseindex)
    varinterm!(ipc, ipc, 100)
    ipc
end

