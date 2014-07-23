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

import std.net.curl : HTTP;
import std.datetime : SysTime, Clock;
import std.conv : text;
import std.string : toLower;
import std.traits : EnumMembers;
import std.typecons : Rebindable, rebindable;
import facebook.json : parseJSON;
import std.stdio;

import mockcurl : get, post, del;
import queryresults : QueryResults, queryResults;

version(unittest) {
    import mockcurl : enqueueCurlResult;
    import queryresults : JSBuilder;
}

struct ClientSession {
    this(string endpoint, string user) {
        this.endpoint = endpoint ~ "/v1/statement";
        this.user = user;
        this.time_zone = getThisTimeZoneId();
    }

    string endpoint = null;
    string user = null;
    string source = null;
    string schema = null;
    string catalog = null;

    //Obeys format from http://docs.oracle.com/javase/7/docs/api/java/util/TimeZone.html
    string time_zone;

    //TODO: This is non-trivial.
    //Obeys format from Java Locale
    string language = null;

    //TODO: Could conceivably cache this if the variables became properties...
    HTTP constructHeaders() const {
        auto http = HTTP();
        foreach (header; EnumMembers!PRESTO_HEADER) {
            enum memberName = mapHeaderToMemberName!header;
            addHeaderIfNotNull!(header)(http, mixin(memberName));
        }

        return http;
    }
}

unittest {
    auto cs = ClientSession("localhost", "user1");
    cs.schema = "tiny";
    cs.catalog = "tpch";
    cs.constructHeaders();
}

string getThisTimeZoneId() {
    auto utcOffset = SysTime(0).timezone.utcOffsetAt(Clock.currTime.stdTime);
    auto hoursOffset = utcOffset.hours;
    auto offsetSign = hoursOffset > 0 ? "+" : "-";
    return "GMT" ~ offsetSign ~ text(hoursOffset);
}

struct StatementClient {
    @disable this();

    this(ClientSession session, string query) {
        this.session_ = session;
        this.query_ = query;

        auto response = post(session.endpoint, query, session.constructHeaders());
        parseAndSetResults(response);
    }

    ~this() {
        terminateQuery();
    }

    ClientSession session() const {
        return session_;
    }
    string query() const {
        return query_;
    }
    bool queryTerminated() {
        return queryTerminated_;
    }

    immutable(QueryResults) front() const nothrow pure {
        return results_;
    }

    void popFront() {
        assert(!empty);
        auto response = get(results_.nextURI);
        parseAndSetResults(response);
    }

    bool empty() const nothrow {
        return results_.nextURI == "" || queryTerminated_;
    }

    void terminateQuery() {
        if (!empty) {
            del(results_.nextURI);
            queryTerminated_ = true;
        }
    }

private:
    void parseAndSetResults(char[] response) {
        results_ = Rebindable!(immutable(QueryResults))(queryResults(parseJSON(response)));
    }

    bool queryTerminated_ = false;
    ClientSession session_;
    string query_;
    Rebindable!(immutable(QueryResults)) results_;
}

enum PRESTO_HEADER {
    USER = "X-Presto-User",
    SOURCE = "X-Presto-Source",
    CATALOG = "X-Presto-Catalog",
    SCHEMA = "X-Presto-Schema",
    //TIME_ZONE = "X-Presto-Time-Zone",
    //LANGUAGE = "X-Presto-Language",
}

unittest {
    enqueueCurlResult(new JSBuilder().withNext().toString().dup);
    enqueueCurlResult(new JSBuilder().withNext().withColumns().toString().dup);
    enqueueCurlResult(new JSBuilder().withNext().withColumns().withData().toString().dup);
    enqueueCurlResult(new JSBuilder().withColumns().withData().toString().dup);

    auto session = ClientSession("localhost", "user1");
    auto query = "SELECT lemons FROM life";
    auto client = StatementClient(session, query);
    assert(client.query == query);
    assert(!client.empty);
    assert(client.front.byRow().empty);

    client.popFront;
    assert(!client.empty);
    assert(client.front.byRow().empty);

    client.popFront;
    assert(!client.empty);
    assert(!client.front.byRow().empty);

    client.popFront;
    assert(client.empty);
    assert(!client.front.byRow().empty);
}

unittest {
    enqueueCurlResult(new JSBuilder().withNext().toString().dup);
    enqueueCurlResult(new JSBuilder().withNext().withColumns().toString().dup);
    enqueueCurlResult(new JSBuilder().withNext().withColumns().withData().toString().dup);
    enqueueCurlResult(new JSBuilder().withColumns().withData().toString().dup);

    auto session = ClientSession("localhost", "user1");
    auto query = "SELECT lemons FROM life";
    auto client = StatementClient(session, query);
    assert(client.query == query);
    assert(!client.empty);
    assert(client.front.byRow().empty);

    client.popFront;
    assert(!client.empty);
    assert(client.front.byRow().empty);

    client.popFront;
    assert(!client.empty);
    assert(!client.front.byRow().empty);

    client.popFront;
    assert(client.empty);
    assert(!client.front.byRow().empty);
}

unittest {
    import std.concurrency : Tid, spawn, receiveOnly;

    enqueueCurlResult(new JSBuilder().withNext().withColumns().withData().toString().dup);
    enqueueCurlResult(new JSBuilder().withNext().withColumns().withData().toString().dup);
    enqueueCurlResult(new JSBuilder().withNext().withColumns().withData().toString().dup);
    enqueueCurlResult(new JSBuilder().withNext().withColumns().withData().toString().dup);
    enqueueCurlResult(new JSBuilder().withColumns().withData().toString().dup);

    auto session = ClientSession("localhost", "user1");
    auto client = StatementClient(session, "");

    Tid[] workers;
    foreach (resultBatch; client) {
        workers ~= spawn(&resultProcessorThread, resultBatch);
    }

    foreach (workerTid; workers) {
        auto result = receiveOnly!long();
        assert(result == 48);
    }
}

version(unittest) {
    import std.concurrency : ownerTid, send;

    void resultProcessorThread(immutable(QueryResults) resultBatch) {
        long reduceVal = 0;
        foreach (row; resultBatch.byRow!(long, "col2")()) {
            reduceVal += row[0];
        }
        ownerTid.send(reduceVal);
    }
}


unittest {
    enqueueCurlResult(new JSBuilder().withNext().toString().dup);

    auto session = ClientSession("localhost", "user1");
    auto client = StatementClient(session, "query");
    assert(!client.empty);
    client.terminateQuery();
    assert(client.empty);
}

private void addHeaderIfNotNull(PRESTO_HEADER header)(ref HTTP http, string value) {
    if (value != null) {
        string headerValue = header;
        http.addRequestHeader(text(headerValue), value);
    }
}

private string mapHeaderToMemberName(PRESTO_HEADER header)() {
    return toLower(text(header));
}

unittest {
    static assert(mapHeaderToMemberName!(PRESTO_HEADER.USER) == "user");
}
