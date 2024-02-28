


function insert( host::MilvusClient, 
        collectionName::MilvusCollection, 
        data::Vector; 
        batch_size=32 )

    url = uri(host) * "/v1/vector/insert"
    headers = ["Content-Type" => "application/json",
                "Accept" => "application/json",
                "Authorization" => "Bearer $(host.token)"]

    inserted_keys = [] # store the keys of the inserted data
    for i in _batch(data, batch_size) # batch the data
        payload = Dict( "dbname" => host.dbname,
                        "collectionName" => collectionName,
                        "data" => i )
        response = HTTP.post(url, headers, JSON3.write(payload))
        @assert response.status == 200

        # get the keys of the inserted data
        keys = JSON3.read(response.body)["data"]["insertIds"]
        append!(inserted_keys, keys)
    end

    return inserted_keys
end

function insert( host::MilvusClient, collectionName::MilvusCollection, data::Dict)
    insert( host, collectionName, [data])
end
 


function get( host::MilvusClient, 
        collection::MilvusCollection, 
        id; 
        outputFields::Vector = [] )

    url = uri(host) * "/v1/vector/get"
    headers = ["Content-Type" => "application/json",
                "Accept" => "application/json",
                "Authorization" => "Bearer $(host.token)"]


    payload = Dict( "dbname" => host.dbname,
                    "collectionName" => collection.collectionName,
                    "id" => id )

    # if outputFields is not empty, add it to the payload
    if length(outputFields) > 0
        payload["outputFields"] = outputFields
    end

    response = HTTP.post(url, headers, JSON3.write(payload))
    @assert response.status == 200

    return JSON3.read(response.body)
end




"""

Conducts a similarity search in a collection.

## Parameters:

- `dbName::String`            The name of the database.
- `collectionName::String`    The name of the collection to which this operation applies.
- `filter::String`            The filter condition for the query. The filter condition is in the SQL format.   
- `limit::Int`                The maximum number of records to return. The value ranges from 1 to 100.
- `offset::Int`               The number of records to skip before returning the results.
- `outputFields::Vector`      The fields to return in the query result. If not specified, only the object IDs are returned.
- `params::Dict`              Additional parameters for the search operation.


### filter

Filter is a string that specifies the filter condition for the query. The filter condition is in 
the SQL format. For example, 

- `filter = "age > 20"`
- `filter = "10 < reading_time < 15"`
- `filter = "id in [443300716234671427, 443300716234671426]"`


### params

Search parameter(s) specific to the specified index type. See 
[Vector Index](https://milvus.io/docs/v2.2.x/index.md) for more information. 
Possible options are as follows:

- `nprobe` Indicates the number of cluster units to search. This parameter is available only 
  when `index_type` is set to `IVF_FLAT`, `IVF_SQ8`, or `IVF_PQ`. The value should be less 
  than `nlist` specified for the index-building process.
- `ef` Indicates the search scope. This parameter is available only when `index_type` is set 
  to `HNSW`. The value should be within the range from `top_k` to `32768`.
- `search_k` Indicates the search scope. This parameter is available only when `index_type` 
  is set to `ANNOY`. The value should be greater than or equal to the top K.

## Possible Errors (RESTful API):

- 800 - Collection not found
- 1800 - User hasn't authenticated
- 1801 - Can only accept JSON format request
- 1802 - Missing required parameters
- 1805 - Fail to parse search results

## See Also

- https://milvus.io/api-reference/restful/v2.3.x/Vector%20Operations/search.md
"""
function search( host::MilvusClient, 
        collection::MilvusCollection, 
        vector::Vector;
        filter::String="",
        limit::Int=100, # ranges from 1 to 100
        offset::Int=0,
        outputFields::Vector=[],
        params::Union{Nothing, Dict} = nothing )

    url = uri(host) * "/v1/vector/search"
    headers = ["Content-Type" => "application/json",
                "Accept" => "application/json",
                "Authorization" => "Bearer $(host.token)"]


    # check if limit is within the range
    if (limit < 1 || limit > 100)
        throw(ArgumentError("limit must be between 1 and 100"))
    end

    # offset + limit <= 1024 
    # Ref: https://milvus.io/api-reference/restful/v2.3.x/Vector%20Operations/search.md
    if (offset > 1024) || ((offset + limit) > 1024)
        throw(ArgumentError("offset or (offset + limit) must not be greater than 1024"))
    end

    payload = Dict( "dbname" => host.dbname,
                    "collectionName" => collection.collectionName,
                    "vector" => vector,
                    "offset" => offset,
                    "limit"  => limit )

    # if filter is not empty, add it to the payload
    if length(filter) > 0
        payload["filter"] = filter
    end

    # if outputFields is not empty, add it to the payload
    if length(outputFields) > 0
        payload["outputFields"] = outputFields
    end

    # TODO: add params to the payload

    response = HTTP.post(url, headers, JSON3.write(payload))
    @assert response.status == 200

    return JSON3.read(response.body)
end



function query( host::MilvusClient, 
        collection::MilvusCollection, 
        filter::String="";
        limit::Int=100, # (limit + offset) < 16384
        offset::Int=0,  # should be less than 16384
        outputFields::Vector=[] )

    url = uri(host) * "/v1/vector/query"
    headers = ["Content-Type" => "application/json",
                "Accept" => "application/json",
                "Authorization" => "Bearer $(host.token)"]

    # check if limit is within the range
    if (limit < 1 || limit >= 16384)
        throw(ArgumentError("limit must be between 1 and 16384"))
    end

    # offset + limit <= 16384
    # Ref: https://milvus.io/api-reference/restful/v2.3.x/Vector%20Operations/query.md
    if (offset >= 16384) || ((offset + limit) >= 16384)
        throw(ArgumentError("offset or (offset + limit) must not be greater than 16384"))
    end

    payload = Dict( "dbname"         => host.dbname,
                    "collectionName" => collection.collectionName,
                    "filter"         => filter,
                    "offset"         => offset,
                    "limit"          => limit )

    # if outputFields is not empty, add it to the payload
    if length(outputFields) > 0
        payload["outputFields"] = outputFields
    end

    response = HTTP.post(url, headers, JSON3.write(payload))
    @assert response.status == 200

    return JSON3.read(response.body)
end



function delete( host::MilvusClient, 
        collectionName::MilvusCollection, 
        id::Vector )

    url = uri(host) * "/v1/vector/delete"
    headers = ["Content-Type" => "application/json",
                "Accept" => "application/json",
                "Authorization" => "Bearer $token"]

    payload = Dict( "dbname" => host.dbname,
                    "collectionName" => collectionName,
                    "id" => id )

    response = HTTP.post(url, headers, JSON3.write(payload))
    @assert response.status == 200

    return JSON3.read(response.body)
end



function upsert( host::MilvusClient, 
        collection::MilvusCollection, 
        data::Vector )

    url = uri(host) * "/v1/vector/upsert"
    headers = ["Content-Type" => "application/json",
                "Accept" => "application/json",
                "Authorization" => "Bearer $token"]

    payload = Dict( "dbname" => host.dbname,
                    "collectionName" => collection.collectionName,
                    "data" => data )

    response = HTTP.post(url, headers, JSON3.write(payload))
    @assert response.status == 200

    return JSON3.read(response.body)
end


function upsert( host::MilvusClient, 
        collection::MilvusCollection, 
        data::Dict )

    upsert( host, collection, [data] )
end