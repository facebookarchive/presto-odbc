
import json : JSON_TYPE, JSONValue;
import std.typecons : Tuple, tuple;
import std.typetuple : TypeTuple;
import std.conv : text, to;
import std.array : front, popFront, empty;
import std.stdio;

import util : PrestoClientException;

version(unittest) {
  import json : parseJSON;
  import std.exception : assertThrown;
}

struct QueryResults {

  this(JSONValue rawResult) {
    id_ = rawResult["id"].str;
    infoURI_ = rawResult["infoUri"].str;
    partialCancelURI_ = getStringPropertyOrDefault!"partialCancelUri"(rawResult);
    nextURI_ = getStringPropertyOrDefault!"nextUri"(rawResult);
    stats_ = QueryStats(rawResult["stats"]);

    if ("columns" in rawResult) {
      foreach (columnJSON; rawResult["columns"].array) {
        columns_ ~= Column(columnJSON["name"].str, columnJSON["type"].str);
      }
    }

    if ("data" in rawResult) {
      data_ = rawResult["data"];
    } else {
      data_.array = [];
    }
  }

  @property {
    string id() const nothrow { return id_; }
    string infoURI() const nothrow { return infoURI_; }
    string partialCancelURI() const nothrow { return partialCancelURI_; }
    string nextURI() const nothrow { return nextURI_; }
    const(Column)[] columns() const nothrow { return columns_; }
    const(JSONValue) data() const nothrow { return data_; }
    QueryStats stats() const nothrow { return stats_; }
  }

  auto byRow(RowTList...)() {
    if (columns_.empty) {
      return Range!RowTList();
    }
    return Range!RowTList(&this, data_.array);
  }

  struct Range(RowTList...) {
    this(QueryResults* qr, JSONValue[] data) {
      static assert(isJSONTypeList!UnnamedRowTList, "Types must be bool/long/double/string");
      static assert(2 * UnnamedRowTList.length == RowTList.length,
        "All types must have names to match against the JSON");

      this.qr = qr;
      this.data = data;
      foreach (i, column; qr.columns_) {
        fieldNameToIndex[column.name] = i;
      }
      foreach (fieldName; fieldNames) {
        if (fieldName !in fieldNameToIndex) {
          throw new NoSuchColumn("Asked for a column that does not exist!");
        }
      }
    }

    @property {
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
      data = data[1 .. $];
    }

  private:
    alias UnnamedRowTList = Tuple!RowTList.Types;
    alias fieldNames = extractCTFEStrings!RowTList;
    QueryResults* qr;
    JSONValue[] data;
    ulong[string] fieldNameToIndex;
  }

private:
  string id_;
  string infoURI_;
  string partialCancelURI_;
  string nextURI_;
  Column[] columns_;
  JSONValue data_;
  QueryStats stats_;
  //error
}

version(unittest) {
  struct JSBuilder {
    private string js = "{
      \"id\" : \"123\",
      \"infoUri\" : \"localhost\",
      \"stats\" : {}";

    JSBuilder* withNext() {
      js ~= ",\"nextUri\" : \"localhost\"";
      return &this;
    }

    JSBuilder* withColumns() {
      js ~= ",\"columns\" : [ { \"name\" : \"col1\", \"type\" : \"varchar\" },
                              { \"name\" : \"col2\", \"type\" : \"bigint\" } ]";
      return &this;
    }

    JSBuilder* withData() {
      js ~= ",\"data\" : [ [\"testentry1\", 45], [\"testentry2\", 3] ]";
      return &this;
    }

    JSONValue build() {
      return parseJSON(toString());
    }

    string toString() {
      return js ~ "}";
    }
  }
}

unittest {
  auto qr = QueryResults(JSBuilder().withNext().build());
  assert(qr.id == "123");
  assert(qr.nextURI == "localhost");
  assert(qr.columns.empty);
  assert(qr.data.array.empty);
  assert(qr.byRow().empty);
}

unittest {
  auto qr = QueryResults(JSBuilder().withNext().withColumns().build());
  assert(qr.id == "123");
  assert(qr.nextURI == "localhost");
  assert(!qr.columns.empty);
  assert(qr.data.array.empty);
  assert(qr.byRow().empty);
  assert(qr.byRow!(long, "col2").empty);
  assert(qr.columns[0].name == "col1");
  assertThrown!NoSuchColumn(qr.byRow!(long, "doesNotExist"));
}

unittest {
  auto qr = QueryResults(JSBuilder().withNext().withColumns().withData().build());
  assert(qr.id == "123");
  assert(qr.nextURI == "localhost");
  assert(!qr.columns.empty);
  assert(!qr.data.array.empty);
  assert(!qr.byRow().empty);
  assert(qr.columns[0].name == "col1");

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

struct Column {
  string name;
  string type;
}

class WrongTypeException(Expected) : PrestoClientException {
  this(string received = "bad runtime type") {
    super("Expected " ~ text(typeid(Expected)) ~ " received " ~ received);
  }
}

class NoSuchColumn : PrestoClientException {
  this(string column = "") {
    super("Asked for a non-existant column (" ~ column ~ ")");
  }
}

private T jsonValueAs(T)(JSONValue elt) {
  static if (is(T == bool)) {
    if (elt.type == JSON_TYPE.TRUE) {
      return true;
    } else {
      return false;
    }
  } else static if (is(T == long)) {
    return elt.integer;
  } else static if (is(T == double)) {
    return elt.floating;
  } else {
    return elt.str;
  }
}

unittest {
  assert(jsonValueAs!long(parseJSON("5")) == 5);
  assert(jsonValueAs!long(parseJSON("4")) != 5);
  assertThrown!Exception(jsonValueAs!long(parseJSON("\"str\"")));
}

private void requireMatchingType(T)(ulong fieldIndex, QueryResults* qr, JSONValue jsonRow) {
  if (!typeMatchesColumnTypeName!T(qr.columns[fieldIndex].type)
      || !typeMatchesJSONType!T(jsonRow[fieldIndex].type)) {
    throw new WrongTypeException!T;
  }
}

unittest {
  auto js = parseJSON("[\"test\"]");
  QueryResults qr;
  qr.columns_ = [ Column("test", "varchar") ];
  requireMatchingType!string(0, &qr, js);
  assertThrown!(WrongTypeException!long)(requireMatchingType!long(0, &qr, js));
  assertThrown!(WrongTypeException!bool)(requireMatchingType!bool(0, &qr, js));
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
  }
  return false;
}

unittest {
  static assert(isJSONType!string);
  static assert(isJSONType!long);
  static assert(!isJSONType!int);
}

private string getStringPropertyOrDefault(string propertyName)(JSONValue src, lazy string default_ = "") {
  if (propertyName !in src) {
    return default_;
  }
  return src[propertyName].str;
}

unittest {
  auto js = parseJSON("{\"test\" : \"value\"}");
  assert(getStringPropertyOrDefault!"test"(js) == "value");
  assert(getStringPropertyOrDefault!"meep"(js) == "");
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
