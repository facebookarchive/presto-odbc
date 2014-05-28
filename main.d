

import std.stdio : writeln;
import queryresults : QueryResults;
import statementclient : ClientSession, StatementClient;

version(unittest) void main() { writeln("Tests completed."); }
else void main() {

  auto session = ClientSession("localhost:8080/v1/statement", "test");
  session.catalog = "tpch";
  session.schema = "tiny";

  auto client = StatementClient(session, "SELECT * FROM sys.node");

  foreach (resultSet; client) {
    writeln ("Starting a new set");
    foreach (row; resultSet.byRow!(string, "http_uri")()) {
      writeln(row);
    }
  }

}
