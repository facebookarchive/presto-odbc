
import json : parseJSON;
import std.net.curl : post, get, HTTP;
import std.stdio : writeln;
import queryresults : QueryResults;

version(unittest) void main() { writeln("Tests completed."); }
else void main() {

  auto http = HTTP();
  http.addRequestHeader("x-presto-user", "test");
  http.addRequestHeader("x-presto-catalog", "tpch");
  http.addRequestHeader("x-presto-schema", "tiny");
  auto response = post("localhost:8080/v1/statement", "SELECT * FROM sys.node", http);
  auto json = parseJSON(response);
  auto queryResults = QueryResults(json);


  response = get(queryResults.nextURI);
  json = parseJSON(response);
  queryResults = QueryResults(json);

  writeln(json["columns"]);
  writeln(json["data"]);

  auto data = queryResults.byRow!(string, "http_uri")();
  foreach(row; data) {
    writeln(row.http_uri);
  }
}
