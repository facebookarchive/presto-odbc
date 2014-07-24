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

module dapi.util;

import facebook.json : JSONValue, JSON_TYPE;
import std.conv : text;
import std.typecons : Nullable;

version(unittest) {
    import facebook.json : parseJSON;
    import std.exception : assertThrown;
}

class PrestoClientException : Exception {
    this(string msg, string file = __FILE__, int line = __LINE__) {
        super(msg, file, line);
    }
    this(string msg, string file = __FILE__, int line = __LINE__) immutable {
        super(msg, file, line);
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

unittest {
    assert(asBool(parseJSON("true")) == true);
    assert(asBool(parseJSON("false")) == false);
    assertThrown!PrestoClientException(asBool(parseJSON(`"blahblah"`)));
}


T jsonValueAs(T)(JSONValue elt) {
    static if (is(T == bool)) {
        return asBool(elt);
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

immutable(Nullable!T) getOptionalProperty(T, string propertyName)(JSONValue src) {
    if (propertyName !in src) {
        return immutable(Nullable!T)();
    }
    return immutable(Nullable!T)(jsonValueAs!T(src[propertyName]));
}

unittest {
    auto js = parseJSON(`{"test" : "value"}`);
    assert(getOptionalProperty!(string, "test")(js).get == "value");
    assert(getOptionalProperty!(string, "meep")(js).isNull);
}

T getPropertyOrDefault(T, string propertyName)(JSONValue src, lazy T default_ = T.init) {
    if (propertyName !in src) {
        return default_;
    }
    return jsonValueAs!T(src[propertyName]);
}

unittest {
    auto js = parseJSON(`{"test" : "value"}`);
    assert(getPropertyOrDefault!(string, "test")(js) == "value");
    assert(getPropertyOrDefault!(string, "meep")(js) == "");
}
