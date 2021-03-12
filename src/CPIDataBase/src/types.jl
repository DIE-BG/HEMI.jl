struct CPIBase{T} 
    v::Matrix{T}
    w::Vector{T}
end

function Base.show(io::IO, b::CPIBase)
    println("CPIBase: ", size(b.v)[1], " períodos")
    println("| -> ", size(b.v)[2], " gastos básicos")    
end