
import std.net.curl : post, get, HTTP;
import json : JSON_TYPE, parseJSON, JSONValue;
import std.stdio : writeln;
import std.typecons : Tuple;
import std.conv : text, to;

void main() {

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

  writeln(queryResults.dataAs!(string, string, string, bool)(0));
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

  //TODO: Remove this function and make a range class that does this
  Tuple!TList dataAs(TList...)(uint row) const {
    //Static/runtime checks:
    static assert(isJSONTypeList!TList, "Types must be bool/long/double/string");

    if (TList.length != columns.length) {
      //TODO: Rethink things - may not want/need all the types.
      // This is especially painful in that it introduces a runtime error if ever the query
      // changes what it returns in any way.
      throw new PrestoClientException("Wrong number of types");
    }

    auto jsonRow = data_.array[row];
    requireMatchingTypes!TList(jsonRow);

    //The actual work:
    Tuple!TList result;
    foreach (i, T; TList) {
      auto elt = jsonRow.array[i];
      result[i] = jsonValueAs!T(elt);
    }

    return result;
  }
private:
  T jsonValueAs(T)(JSONValue elt) const {
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

  const void requireMatchingTypes(TList...)(JSONValue jsonRow) {
    foreach (i, T; TList) {
      if (!typeMatchesColumnTypeName!T(columns[i].type)
          || !typeMatchesJSONType!T(jsonRow[i].type)) {
        throw new WrongTypeException!T;
      }
    }
  }

  static pure const nothrow bool typeMatchesJSONType(T)(JSON_TYPE jsonType) {
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

  static pure const nothrow bool typeMatchesColumnTypeName(T)(string typeName) {
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

  static pure const nothrow bool isJSONTypeList(TList...)() {
    foreach(T; TList) {
      if (!isJSONType!T) {
        return false;
      }
    }
    return true;
  }

  static pure const nothrow bool isJSONType(T)() {
    static if (is(T == string) || is(T == long) || is(T == bool) || is(T == double)) {
      return true;
    }
    return false;
  }

  string id_;
  string infoURI_;
  string partialCancelURI_;
  string nextURI_;
  Column[] columns_;
  JSONValue data_;
  //data
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

string getStringPropertyOrDefault(string propertyName)(JSONValue src, lazy string default_ = "") {
  if (propertyName !in src) {
    return default_;
  }
  return src[propertyName].str;
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
