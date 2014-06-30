
module dapi.util;

import std.conv : text;
import facebook.json : JSONValue, JSON_TYPE;

class PrestoClientException : Exception {
  this(string msg) {
    super(msg);
  }
}

bool asBool(const(JSONValue) v) {
  if (v.type == JSON_TYPE.TRUE) {
    return true;
  }
  if (v.type == JSON_TYPE.FALSE) {
    return false;
  }
  throw new PrestoClientException("Expected a JSON bool, got: " ~ text(v.type));
}
