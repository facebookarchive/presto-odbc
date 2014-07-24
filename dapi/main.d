/**
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

//This file exists to facilitate "live testing" and trying simple queries

import std.stdio : writeln;
import queryresults : QueryResults;
import statementclient : ClientSession, StatementClient;
import std.net.curl;

version(unittest) void main() { writeln("Tests completed."); }
else void main() {
    auto session = ClientSession("localhost:8080", "test");
    session.catalog = "tpch";
    session.schema = "tiny";

    auto client = StatementClient(session, "SELECT * FROM orders");
    foreach (resultBatch; client) {
        writeln("Starting a new batch");

        foreach (row; resultBatch.byRow!(string, "comment")()) {
            writeln(row);
        }
    }
}
