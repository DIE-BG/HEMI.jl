## Trend application development

export apply_trend, apply_trend!
export RWTREND
export _get_ranges


# Trend random walk in MATLAB with 240 periods
const RWTREND = exp.(Float32[-0.047333807,-0.052973568,-0.076655388,-0.10282452,-0.18387935,-0.19143690,-0.22375830,-0.23686390,-0.26826179,-0.27769750,-0.22987440,-0.26670682,-0.27606454,-0.22782001,-0.20914310,-0.20847556,-0.23677574,-0.17618284,-0.11188145,-0.20462316,-0.062194452,-0.081171043,-0.10476636,-0.10933505,-0.14765354,-0.12722066,-0.11185908,-0.11023229,-0.099324182,-0.067331836,-0.036103532,-0.087480843,-0.14249562,-0.095918342,-0.15170261,-0.082953863,-0.15100732,-0.15708639,-0.13814363,-0.12901865,-0.14042032,-0.030509762,0.014405243,0.0058676880,0.068194509,-0.036602728,-0.052027442,-0.020089991,0.018707808,0.067368701,0.072193585,-0.0096949562,0.038944814,0.096827574,0.074188881,0.17288880,0.12731466,0.12901840,0.17889187,0.16979384,0.18328923,0.10061029,0.19992277,0.15091966,0.18300349,0.099928826,0.073082514,0.12494892,0.15087827,0.17914657,0.25262862,0.22862123,0.27573907,0.24311933,0.21537431,0.13604990,0.14812885,0.19400588,0.18651833,0.24682540,0.22918874,0.13566563,0.21445793,0.18955553,0.21475059,0.20609911,0.19753172,0.18076605,0.16932094,0.16774788,0.22826552,0.19853932,0.24986264,0.30156064,0.27550387,0.42681473,0.41089717,0.40833366,0.44208989,0.40714863,0.28264868,0.31093913,0.23636219,0.25051478,0.23761790,0.18392250,0.16783893,0.21413921,0.18105307,0.17147945,0.18627167,0.091375500,0.090748526,0.12613364,0.12443160,0.21346158,0.27965909,0.19373292,0.16529858,0.19939277,0.22272950,0.12525305,0.15904383,0.18079945,0.16827321,0.16943212,0.20305461,0.17504825,0.088035025,0.077727519,0.071169659,0.12021927,0.081558861,0.056297168,0.057177454,0.11528615,0.15058371,0.11257960,0.092309736,0.070705518,0.019975539,-0.024994150,-0.013969815,-0.0018490376,-0.056102149,0.0020816699,-0.023187758,0.032606810,0.016741825,0.014884761,0.093036868,0.017667331,-0.026025638,-0.17117059,-0.15084530,-0.26881194,-0.24620919,-0.28968149,-0.27907419,-0.22165105,-0.17509004,-0.24751477,-0.18338916,-0.27747232,-0.26294288,-0.25759080,-0.21792312,-0.20735261,-0.23813675,-0.26334730,-0.30032024,-0.23274225,-0.23332296,-0.23411681,-0.20803560,-0.13697326,-0.14023314,-0.13277616,-0.15009065,-0.10812306,-0.092539407,-0.081679754,-0.10012239,-0.031932995,-0.025128830,-0.10395968,-0.15736502,-0.071713209,-0.0010470897,-0.018757256,-0.046877384,-0.074838005,-0.020287398,0.072646931,0.037365947,0.050339378,0.12812394,0.15665604,0.16702439,0.15932854,0.19651903,0.081088200,0.12958083,0.11107469,0.10952799,0.042175025,0.022671483,0.095870659,0.081205711,0.020611491,-0.057207387,-0.029256510,-0.057922974,-0.0030477829,-0.013473514,-0.058432959,-0.028136455,0.014090959,-0.055176850,-0.066080719,-0.038586333,0.034828775,0.026209412,-0.015132746,-0.032997936,-0.096843123,-0.029833145,-0.049158860,-0.13846309,-0.058998235,-0.0071466826,-0.078891203,-0.0034969449,0.074302532,0.045504630,0.035986122,0.057317831,0.033117298,0.061279215,0.092678860]); 

# Funciona, 0 allocations, pero en este caso no es tan eficiente 
# ahorrar la memoria, es más lento.
# 363.800 μs (0 allocations: 0 bytes)
function apply_trend!(base::VarCPIBase, trend::AbstractVector)
    v = base.v
    v .= @. v * ((v .> 0) * trend + !(v .> 0))
    nothing 
end

# 82.500 μs (2 allocations: 102.27 KiB)
function apply_trend(base::VarCPIBase, trend::AbstractVector)
    vtrend =  @. base.v .* ((base.v > 0) * trend + !(base.v > 0))
    VarCPIBase(vtrend, base.w, base.fechas, base.baseindex)
end


function _get_ranges(cs::CountryStructure) 
    periods = map( base -> size(base.v, 1), cs.base)
    ranges = Vector{UnitRange}(undef, length(periods))
    start = 0
    for i in eachindex(periods)
        ranges[i] = start + 1 : start + periods[i]
        start = periods[i]
    end
    NTuple{length(cs.base), UnitRange{Int64}}(ranges)
end

## CountryStructure functions to apply trend 

# 817.600 μs (9 allocations: 1.48 KiB)
function apply_trend!(cs::CountryStructure, trend::AbstractVector)
    ranges = _get_ranges(cs)
    trends = map(r -> getindex(trend, r), ranges)
    map(apply_trend!, cs.base, trends)
    nothing
end

# 187.300 μs (9 allocations: 234.44 KiB)
function apply_trend(cs::CountryStructure, trend::AbstractVector)
    ranges = _get_ranges(cs)
    trends = map(r -> getindex(trend, r), ranges)
    newbases = map(apply_trend, cs.base, trends)
    typeof(cs)(newbases)
end


## Slower versions than MATLAB
# MATLAB por defecto utiliza multithreading en sus cómputos vectorizados
# Esto no está por defecto en Julia (aún), por lo que las siguientes funciones
# son mucho más lentas en Julia

# function apply_trend1!(cs::CountryStructure, trend::AbstractVector)

#     start = 0
#     for base in cs.base
        
#         v = base.v
#         rows, cols = size(v)
#         basetrend = @view trend[start + 1: start + rows]
        

#         for i in 1:rows, j in 1:cols
#             if v[i, j] > 0
#                 v[i, j] *= exp(basetrend[i])             
#             end
#         end

#         start = rows
#     end

# end


# function apply_trend2!(cs::CountryStructure, trend::AbstractVector)

#     start = 0
#     for base in cs.base
        
#         v = base.v
#         rows, cols = size(v)
#         basetrend = @view trend[start + 1: start + rows]
        
#         mask = @. (v > 0) * exp(basetrend) + (v <= 0)
#         v .= v .* mask

#         start = rows
#     end

# end