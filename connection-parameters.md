
# Connection Parameters

This file provides a brief overview of the various connection parameters you can use to connect to
your Presto instance via the Presto ODBC driver.

Connection parameter names are *not* case sensitive, the values you put into them *are*.

Connection Parameter  | Description
------------- | -------------
Endpoint (required) | host:port of the server you would like to connect to
PrestoCatalog (required) | Presto Catalog
PrestoSchema | Presto Schema
Username | Sets the Presto user
ProxyEndpoint | host:port of your socks5 proxy machine

A connection parameter string is a string of the form `key=value;key=value` up to any number of
key/value pairs. Leading/trailing semicolons are optional.

An example would be:
`endpoint=localhost:8080;prestoCatalog=tpch;prestoSchema=tiny;`
