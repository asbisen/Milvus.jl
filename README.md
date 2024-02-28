# Milvus

[![Build Status](https://github.com/asbisen/Milvus.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/asbisen/Milvus.jl/actions/workflows/CI.yml?query=branch%3Amain)

A minimal and unofficial implementation of [Milvus VectorDB](https://milvus.io) client for Julia. This library wraps their [REST API](https://milvus.io/api-reference/restful/v2.2.x/About.md) in Julia functions.

**Note:** This library should be considered *WIP* pre-alpha.

# Example

## Create and Describe a Collection 

```julia
using Milvus
using Random

dbname = "default"
collectionName = "myCollection"
host = MilvusClient("http://localhost:19530", dbname=dbname)

# List collections
r = list_collections(host)
println("Avialable collections: $r")

# Define a collection (dbname, collectionName, vectorLength)
collection = create_collection( host, collectionName, 768)

# Describe collection
describe_collection(host, collectionName)
```


## Insert Vector Embeddings

```julia
# generate a record with random values and "vector" 
function recordGen() 
    rec = Dict(
        "title"   => randstring(10),
        "content" => randstring(60),
        "vector"  => rand(768)
        )
end

# Generate 100 records
n = 100
data = [recordGen() for i in 1:n]

# insert records 16 at a time. Returns list of ID's of the created objects
r = insert( host, collection, data, batch_size=16)
```

