module Milvus

using HTTP
using JSON3

include("utils.jl")

include("client.jl")
export MilvusClient
        
include("collections.jl")
export MilvusCollection,
       list_collections,
       create_collection,
       describe_collection,
       drop_collection

include("vectors.jl")
export insert,
       get,
       search,
       query,
       delete,
       upsert


end # end module
