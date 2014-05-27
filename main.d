
import std.net.curl : post, get, HTTP;
import json : JSON_TYPE, parseJSON, JSONValue;
import std.stdio : writeln;
import std.typecons : Tuple, tuple;
import std.typetuple : TypeTuple;
import std.conv : text, to;
import std.array : front, popFront, empty;
import std.range : zip;

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

      bool allTsHaveNames = 2 * UnnamedRowTList.length == RowTList.length;
      if (!allTsHaveNames) {
        throw new PrestoClientException("Wrong number of types");
      }

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

struct QueryStats {
  this(JSONValue rawResult) {
    //TODO
  }
}

struct Column {
  string name;
  string type;
}

class PrestoClientException : Exception {
  this(string msg) {
    super(msg);
  }
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

private void requireMatchingType(T)(ulong fieldIndex, QueryResults* qr, JSONValue jsonRow) {
  if (!typeMatchesColumnTypeName!T(qr.columns[fieldIndex].type)
      || !typeMatchesJSONType!T(jsonRow[fieldIndex].type)) {
    throw new WrongTypeException!T;
  }
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

private pure nothrow bool isJSONTypeList(TList...)() {
  foreach(T; TList) {
    if (!isJSONType!T) {
      return false;
    }
  }
  return true;
}

private pure nothrow bool isJSONType(T)() {
  static if (is(T == string) || is(T == long) || is(T == bool) || is(T == double)) {
    return true;
  }
  return false;
}

private string getStringPropertyOrDefault(string propertyName)(JSONValue src, lazy string default_ = "") {
  if (propertyName !in src) {
    return default_;
  }
  return src[propertyName].str;
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
