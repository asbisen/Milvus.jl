

struct MilvusCollection
    collectionName::String
    description::String
    enableDynamicField::Bool
    fields::Vector
    indexes::Vector
    raw_object::Dict
end

function MilvusCollection( raw_object::Dict ) 
    collectionName     = raw_object[:data][:collectionName]
    description        = raw_object[:data][:description]
    enableDynamicField = raw_object[:data][:enableDynamicField]
    fields             = raw_object[:data][:fields] .|> Dict
    indexes            = raw_object[:data][:indexes] .|> Dict
    raw_object         = raw_object

    return MilvusCollection( collectionName, description, enableDynamicField, fields, indexes, raw_object )
end


function Base.show(io::IO, collection::MilvusCollection)
    print(io, "Collection: $(collection.collectionName)\n")
    print(io, "Description: $(collection.description)\n")
    print(io, "Enable Dynamic Field: $(collection.enableDynamicField)\n")
    o1 = Base.get.(collection.fields, :name, "")
    print(io, "Fields: $(o1)\n")
    o2 = Base.get.(collection.indexes, :fieldName, "")
    print(io, "Indexes: $(o2)\n")
end



"""
    create_collection(host, collectionName, dimension; primaryField, vectorField, metricType, description)
    
Create a collection. 

## Arguments

- `host::MilvusClient`: The Milvus client object. 
- `collectionName::String`: The name of the collection.
- `dimension::Int`: The dimension of the vectors in the collection.
- `primaryField::String` ["id"]: The name of the primary field.
- `vectorField::String` ["vector"]: The name of the vector field.
- `metricType::String` ["L2"]: The metric type of the collection. 
- `description::String` [""]: A description of the collection.

### metricType

The metric type of the collection. The following metric types are supported:
- "L2" (Floating Type Vectors)
- "IP" (Floating Type Vectors)
- "COSINE" (Floating Type Vectors)
- "JACCARD" (Binary Vectors)
- "HAMMING" (Binary Vectors)
"""
function create_collection( host::MilvusClient, collectionName::String, dimension::Int;
        primaryField::String="id",
        vectorField::String="vector",
        metricType::String="IP",
        description::String="" )

    url = uri(host) * "/v1/vector/collections/create"
    headers = ["Content-Type" => "application/json",
                "Accept" => "application/json",
                "Authorization" => "Bearer $(host.token)"]

    payload = Dict(
        "dbName" => host.dbname,
        "collectionName" => collectionName,
        "dimension" => dimension,
        "metricType" => metricType,
        "primaryField" => primaryField,
        "vectorField" => vectorField,
        "description" => description
    )
    response = HTTP.post(url, headers, JSON3.write(payload))
    @assert response.status == 200

    # describe the collection and create MilvusCollection object
    describe_collection(host, collectionName)
end


"""
    describe_collection(host, collectionName)

Returns a `MilvusCollection` object for the given collection name with all parameters.
"""
function describe_collection( host::MilvusClient, collectionName::String )
    url = uri(host) * "/v1/vector/collections/describe"
    headers = ["Content-Type" => "application/json",
               "Accept" => "application/json",
               "Authorization" => "Bearer $(host.token)"]

    response = HTTP.get(url, headers, query = ["collectionName" => collectionName])
    obj = JSON3.read(response.body) |> Dict
    return MilvusCollection(obj)
end


"""
    list_collections(host)

Returns a list of collections available in the host.
"""
function list_collections( host::MilvusClient )
    url = uri(host) * "/v1/vector/collections"
    headers = ["Content-Type" => "application/json",
               "Accept" => "application/json",
               "Authorization" => "Bearer $(host.token)"]

    response = HTTP.get(url, headers)
    jsn = JSON3.read(response.body)
    return collect(jsn["data"])
end


"""
    drop_collection(host, collectionName)

Drops the collection with the given name `String` or a `MilvusCollection` object.
"""
function drop_collection(host::MilvusClient, collectionName::String)
    url = uri(host) * "/v1/vector/collections/drop"
    headers = ["Content-Type" => "application/json",
               "Accept" => "application/json",
               "Authorization" => "Bearer $(host.token)"]

    data = Dict("collectionName" => collectionName)
    response = HTTP.post(url, headers, JSON3.write(data))
    obj = JSON3.read(response.body)

    if haskey(obj, "code") && obj["code"] == 200
        return true
    else
        throw(ErrorException("Failed to drop collection:\n\t $(obj["message"])"))
    end
end

function drop_collection(host::MilvusClient, collection::MilvusCollection)
    return drop_collection(host, collection.collectionName)
end