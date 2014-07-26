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

module presto.client.prestoerrors;

import facebook.json : JSON_TYPE, JSONValue;
import std.typecons : Nullable;

import presto.client.util;

class QueryException : PrestoClientException {
    this (JSONValue rawResult) immutable {
        message = getOptionalProperty!(string, "message")(rawResult);
        super(message.isNull ? "Unknown Presto Server Exception" : message.get);

        sqlState = getOptionalProperty!(string, "sqlState")(rawResult);
        errorCode = getOptionalProperty!(long, "errorCode")(rawResult);
        if ("errorLocation" in rawResult) {
            errorLocation = immutable(ErrorLocation)(rawResult["errorLocation"]);
        }
        if ("failureInfo" in rawResult) {
            failureInfo = immutable(FailureInfo)(rawResult["failureInfo"]);
        }
    }

    immutable Nullable!string message;
    immutable Nullable!string sqlState;
    immutable Nullable!long errorCode;
    immutable Nullable!ErrorLocation errorLocation;
    immutable Nullable!FailureInfo failureInfo;
}

struct FailureInfo {
    this (JSONValue rawResult) immutable {
        message = getOptionalProperty!(string, "message")(rawResult);
        type = getOptionalProperty!(string, "type")(rawResult);
        if ("errorLocation" in rawResult) {
            errorLocation = immutable(ErrorLocation)(rawResult["errorLocation"]);
        }
        if ("stack" in rawResult) {
            stack = parseStack(rawResult["stack"].array);
        }
    }

    immutable Nullable!string message;
    immutable Nullable!string type;
    immutable Nullable!ErrorLocation errorLocation;
    immutable(string[]) stack;
}

private immutable(string[]) parseStack(JSONValue[] stack) {
    string[] result;
    foreach (line; stack) {
        result ~= line.str;
    }
    return result.idup;
}

struct ErrorLocation {
    this (JSONValue rawResult) immutable {
        lineNumber = getOptionalProperty!(long, "lineNumber")(rawResult);
        columnNumber = getOptionalProperty!(long, "columnNumber")(rawResult);
    }

    immutable Nullable!long lineNumber;
    immutable Nullable!long columnNumber;
}
