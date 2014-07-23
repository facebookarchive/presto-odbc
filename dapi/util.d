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
