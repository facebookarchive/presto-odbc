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

module presto.client.util;

import std.algorithm : find, max;
import std.array : array, front, empty, popFront;
import std.conv : text;
import std.range : ElementType, isBidirectionalRange, retro;
import std.typecons : Nullable, tuple, Unqual;

import facebook.json : JSONValue, JSON_TYPE;

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

auto findLastSplit(alias pred = "a==b")(string haystack, char needle) {
    auto result = haystack.retro.array.find!(pred)(needle);
    if (result.empty && haystack != text(needle)) {
        return tuple(haystack, haystack[0 .. 0], haystack[0 .. 0]);
    }

    auto lengthBeforeNeedle = !result.empty ? result.length - 1 : 0;
    auto beforeNeedle = haystack[0 .. lengthBeforeNeedle];

    haystack = haystack[lengthBeforeNeedle .. $];
    auto outNeedle = haystack[0 .. 1];

    haystack = haystack[1 .. $];
    return tuple(beforeNeedle, outNeedle, haystack);
}

unittest {
    auto test = "meep:blop";
    auto result = test.findLastSplit(':');
    assert(result[0] == "meep");
    assert(result[1] == ":");
    assert(result[2] == "blop");

    test = ":";
    result = test.findLastSplit(':');
    assert(result[0] == "");
    assert(result[1] == ":");
    assert(result[2] == "");

    test = "";
    result = test.findLastSplit(':');
    assert(result[0] == "");
    assert(result[1] == "");
    assert(result[2] == "");

    test = "meep";
    result = test.findLastSplit(':');
    assert(result[0] == "meep");
    assert(result[1] == "");
    assert(result[2] == "");

    test = "a:";
    result = test.findLastSplit(':');
    assert(result[0] == "a");
    assert(result[1] == ":");
    assert(result[2] == "");

    test = ":b";
    result = test.findLastSplit(':');
    assert(result[0] == "");
    assert(result[1] == ":");
    assert(result[2] == "b");

    test = "a:b:c";
    result = test.findLastSplit(':');
    assert(result[0] == "a:b");
    assert(result[1] == ":");
    assert(result[2] == "c");
}
