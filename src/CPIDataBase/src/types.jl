import TimeSeries: TimeArray, meta

const CPIBase = TimeArray

"""
    weights(ta::TimeArray)

Campo `meta` de `TimeArray` utilizado para almacenar las ponderaciones
de los gastos básicos de la base del IPC.
"""
weights(ta::TimeArray) = meta(ta)


# import Base: show

# function show(io::IO, base::CPIBase)
#     println("Base del IPC")
#     show(io, base)
# end

# export show