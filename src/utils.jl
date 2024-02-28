
"""
    _struct2dict(s)

Converts a struct `s` to a dictionary. Note: This function is not exported and 
would not work with all structures. Not meant to be used directly. 
"""
function _struct2dict(s)
    stype = typeof(s)
    Dict(fieldnames(stype) .=> getfield.(Ref(s), fieldnames(stype)))
end



"""
    _struct2json(s)

Converts a struct `s` to a JSON string. Note: This function is not exported and
would not work with all structures. Not meant to be used directly.
"""
_struct2json(s) = JSON3.write(_struct2dict(s))



"""
    _batch(data::Vector, batch_size::Int)

Batch a vector into smaller chunks of size `batch_size`. The last batch may be
smaller than `batch_size` if the length of `data` is not a multiple of `batch_size`.
"""
function _batch(data::Vector, batch_size::Int) 
    [data[i:min(i+batch_size-1,end)] for i in 1:batch_size:length(data)]
end