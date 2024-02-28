
struct MilvusClient
    scheme::String
    host::String
    port::Int
    user::String
    password::String
    dbname::String
    token::String
    timeout::Int
end

function MilvusClient( uri::String; 
    user::String="", 
    password::String="",
    dbname::String="default",
    token::String="",
    timeout::Int=20 ) # TODO: not implemented 

    scheme, host, port = _parse_uri(uri)
    return MilvusClient(scheme, host, port, user, password, dbname, token, timeout)
end


"""
    _parse_uri(uri::String)

Parse the URI to extract the scheme, host and port.
"""
function _parse_uri(url::String)
    scheme, host, port = nothing, nothing, nothing
    # ensure that schema (http/https) is present
    regex_uri = r"^(http|https)://([^:/]+)(?::(\d+))?(.*)$"
    m = match(regex_uri, url)
    if m === nothing
        throw(ArgumentError("Invalid URL: $url (usrl should be in the form of http(s)://host(:port)"))
    end

    if m[3] === nothing # use default port 19530 if one is not defined
        port = 19530
    else
        port = parse(Int, m[3])
    end

    scheme = m[1] # scheme (http/https)
    host = m[2] # host

    return(scheme=scheme, host=host, port=port)
end


function uri(host::MilvusClient)
    return "$(host.scheme)://$(host.host):$(host.port)"
end


function Base.show(io::IO, host::MilvusClient)
    print(io, "$(uri(host))\n")
    print(io, "dbname: $(host.dbname)\n")
    (host.user != "") && (print(io, "user: $(host.user)\n"))
end