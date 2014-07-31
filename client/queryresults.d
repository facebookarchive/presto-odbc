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
module presto.client.queryresults;

import facebook.json : JSON_TYPE, JSONValue;
import std.typecons : Tuple, tuple;
import std.typetuple : TypeTuple;
import std.conv : text, to;
import std.array : front, popFront, empty;
import std.stdio;

import presto.client.prestoerrors;
import presto.client.util;

version(unittest) {
    import facebook.json : parseJSON;
    import std.exception : assertThrown;
}

immutable(QueryResults) queryResults(JSONValue rawResult) {
    return new immutable(QueryResults)(rawResult);
}

final class QueryResults {

    this(JSONValue rawResult) immutable {
        id_ = rawResult["id"].str;
        infoURI_ = rawResult["infoUri"].str;
        partialCancelURI_ = getPropertyOrDefault!(string,"partialCancelUri")(rawResult);
        nextURI_ = getPropertyOrDefault!(string, "nextUri")(rawResult);
        stats_ = QueryStats(rawResult["stats"]);

        columnMetadata_ = parseColumnMetadata(rawResult);

        if ("data" in rawResult) {
            data_ = rawResult["data"];
        } else {
            data_ = emptyJSONArray();
        }
        if ("error" in rawResult) {
            error_ = new immutable(QueryException)(rawResult["error"]);
        }
    }

    const nothrow {
        string id() { return id_; }
        string infoURI() { return infoURI_; }
        string partialCancelURI() { return partialCancelURI_; }
        string nextURI() { return nextURI_; }
        auto columnMetadata() { return columnMetadata_; }

        auto stats() { return stats_;}
        bool succeeded() { return error_ is null; }
    }
    auto data() const {
        enforceSucceeded();
        return data_;
    }
    auto error() const {
        assert(!succeeded());
        return error_;
    }


    auto byRow(RowTList...)() const {
        enforceSucceeded();
        if (columnMetadata_.empty) {
            return Range!RowTList();
        }
        return Range!RowTList(this, data_.array);
    }

    static struct Range(RowTList...) {
        this(const(QueryResults) qr, immutable(JSONValue)[] data) {
            static assert(isJSONTypeList!UnnamedRowTList, "Types must be bool/long/double/string");
            static assert(2 * UnnamedRowTList.length == RowTList.length,
                          "All types must have names to match against the JSON");

            this.qr = qr;
            this.data = data;
            foreach (i, column; qr.columnMetadata_) {
                fieldNameToIndex[column.name] = i;
            }
            foreach (fieldName; fieldNames) {
                if (fieldName !in fieldNameToIndex) {
                    throw new NoSuchColumn("Asked for a column that does not exist");
                }
            }
        }

        const {
            Tuple!RowTList front() {
                assert(!data.empty);

                auto jsonRow = data[0];

                //Decompose row data into tuple:
                Tuple!RowTList result;
                foreach (i, T; UnnamedRowTList) {
                    alias name = fieldNames[i];
                    auto fieldIndex = fieldNameToIndex[name];

                    //TODO: Consider running this check only on the 0th row.
                    requireMatchingType!T(fieldIndex, qr, jsonRow);

                    auto elt = jsonRow.array[fieldIndex];
                    mixin("result." ~ name) = jsonValueAs!T(elt);
                }

                return result;
            }

            bool empty() {
                return data.empty;
            }
        }

        void popFront() {
            assert(!empty);
            data = data[1 .. $];
        }

    private:
        alias UnnamedRowTList = Tuple!RowTList.Types;
        alias fieldNames = extractCTFEStrings!RowTList;
        const(QueryResults) qr;
        immutable(JSONValue)[] data;
        size_t[string] fieldNameToIndex;
    }

private:
    version(unittest) {
        this(inout ColumnMetadata[] cols) {
            columnMetadata_ = cols.idup;
            stats_ = QueryStats();
            data_ = emptyJSONArray();
        }
    }

    void enforceSucceeded() const {
        if (!succeeded) {
            throw error;
        }
    }

    string id_;
    string infoURI_;
    string partialCancelURI_;
    string nextURI_;
    immutable(ColumnMetadata[]) columnMetadata_;
    immutable(JSONValue) data_;
    immutable(QueryStats) stats_;
    QueryException error_;
}

version(unittest) {
    final class JSBuilder {
        private string js = "{
            \"id\" : \"123\",
            \"infoUri\" : \"localhost\",
            \"stats\" : {}";

        JSBuilder withNext() {
            js ~= ",\"nextUri\" : \"localhost\"";
            return this;
        }

        JSBuilder withColumns() {
            js ~= ",\"columns\" : [ { \"name\" : \"col1\", \"type\" : \"varchar\" },
                                    { \"name\" : \"col2\", \"type\" : \"bigint\" } ]";
            return this;
        }

        JSBuilder withData() {
            js ~= ",\"data\" : [ [\"testentry1\", 45], [\"testentry2\", 3] ]";
            return this;
        }

        JSONValue build() {
            return parseJSON(toString());
        }

        override string toString() {
            return js ~ "}";
        }
    }
}

unittest {
    auto qr = queryResults(new JSBuilder().withNext().build());
    assert(qr.id == "123");
    assert(qr.nextURI == "localhost");
    assert(qr.columnMetadata.empty);
    assert(qr.data.array.empty);
    assert(qr.byRow().empty);
}

unittest {
    auto qr = queryResults(new JSBuilder().withNext().withColumns().build());
    assert(qr.id == "123");
    assert(qr.nextURI == "localhost");
    assert(!qr.columnMetadata.empty);
    assert(qr.data.array.empty);
    assert(qr.byRow().empty);
    assert(qr.byRow!(long, "col2").empty);
    assert(qr.columnMetadata[0].name == "col1");
    assertThrown!NoSuchColumn(qr.byRow!(long, "doesNotExist"));
}

unittest {
    auto qr = queryResults(new JSBuilder().withNext().withColumns().withData().build());
    assert(qr.id == "123");
    assert(qr.nextURI == "localhost");
    assert(!qr.columnMetadata.empty);
    assert(!qr.data.array.empty);
    assert(!qr.byRow().empty);
    assert(qr.columnMetadata[0].name == "col1");

    auto rng = qr.byRow!(long, "col2");
    assert(rng.front[0] == 45);
    rng.popFront();
    assert(!rng.empty);
    assert(rng.front[0] == 3);
    rng.popFront();
    assert(rng.empty);

    auto rng2 = qr.byRow!(long, "col2", string, "col1");
    assert(rng2.front[0] == 45 && rng2.front[1] == "testentry1");

    auto badRng = qr.byRow!(string, "col2");
    assertThrown!(WrongTypeException!string)(badRng.front);
}

struct QueryStats {
    this(JSONValue rawResult) {
        //TODO
    }
}

struct ColumnMetadata {
    string name;
    string type;
}

class WrongTypeException(Expected) : PrestoClientException {
    this(string received = "bad runtime type") {
        super("Expected " ~ Expected.stringof ~ " received " ~ received);
    }
}

class NoSuchColumn : PrestoClientException {
    this(string column = "") {
        super("Asked for a non-existent column (" ~ column ~ ")");
    }
}

private void requireMatchingType(T)(size_t fieldIndex, const(QueryResults) qr, const JSONValue jsonRow) {
    if (!typeMatchesColumnTypeName!T(qr.columnMetadata[fieldIndex].type)
        || !typeMatchesJSONType!T(jsonRow[fieldIndex].type)) {
        throw new WrongTypeException!T;
    }
}

unittest {
    auto js = parseJSON("[\"test\"]");
    auto qr = new QueryResults([ ColumnMetadata("test", "varchar") ]);
    requireMatchingType!string(0, qr, js);
    assertThrown!(WrongTypeException!long)(requireMatchingType!long(0, qr, js));
    assertThrown!(WrongTypeException!bool)(requireMatchingType!bool(0, qr, js));
}

private pure nothrow bool typeMatchesJSONType(T)(JSON_TYPE jsonType) {
    static if (is(T == bool)) {
        return jsonType == JSON_TYPE.TRUE || jsonType == JSON_TYPE.FALSE;
    } else static if (is(T == long)) {
        return jsonType == JSON_TYPE.INTEGER;
    } else static if (is(T == double)) {
        return jsonType == JSON_TYPE.FLOAT;
    } else {
        return jsonType == JSON_TYPE.STRING;
    }
}

unittest {
    static assert(typeMatchesJSONType!bool(JSON_TYPE.TRUE));
    static assert(typeMatchesJSONType!string(JSON_TYPE.STRING));
}

private pure nothrow bool typeMatchesColumnTypeName(T)(string typeName) {
    static if (is(T == bool)) {
        return typeName == "boolean";
    } else static if (is(T == long)) {
        return typeName == "bigint";
    } else static if (is(T == double)) {
        return typeName == "double";
    } else {
        return true;
    }
}

unittest {
    static assert(typeMatchesColumnTypeName!bool("boolean"));
    static assert(!typeMatchesColumnTypeName!bool("bool"));
}

private pure nothrow bool isJSONTypeList(TList...)() {
    foreach(T; TList) {
        if (!isJSONType!T) {
            return false;
        }
    }
    return true;
}

unittest {
    static assert(isJSONTypeList!(string));
    static assert(isJSONTypeList!(string, string));
    static assert(isJSONTypeList!(string, long));
    static assert(!isJSONTypeList!(string, int));
}

private pure nothrow bool isJSONType(T)() {
    static if (is(T == string) || is(T == long) || is(T == bool) || is(T == double)) {
        return true;
    } else {
        return false;
    }
}

unittest {
    static assert(isJSONType!string);
    static assert(isJSONType!long);
    static assert(!isJSONType!int);
}

private template extractCTFEStrings(RowTList...) {
    static if (RowTList.length == 0) {
        alias extractCTFEStrings = TypeTuple!();
    } else static if (is(typeof(RowTList[0]) : string)) {
        alias extractCTFEStrings = TypeTuple!(RowTList[0], extractCTFEStrings!(RowTList[1 .. $]));
    } else {
        alias extractCTFEStrings = extractCTFEStrings!(RowTList[1 .. $]);
    }
}

unittest {
    static assert(extractCTFEStrings!(int,"1","2",string,"3") == TypeTuple!("1","2","3"));
}

immutable(ColumnMetadata[]) parseColumnMetadata(JSONValue rawResult) {
    if ("columns" !in rawResult) {
        return [];
    }

    import std.array;
    import std.algorithm : map;
    auto columnMetadata = appender!(ColumnMetadata[]);
    columnMetadata.reserve(rawResult["columns"].array.length);

    return rawResult["columns"].array.map!(v => ColumnMetadata(v["name"].str, v["type"].str)).array.idup;
}

JSONValue emptyJSONArray() {
    auto result = JSONValue();
    result.array = [];
    return result;
}
