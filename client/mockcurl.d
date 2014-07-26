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
module presto.client.mockcurl;

import std.array : empty, front, popFront;
import std.net.curl : HTTP;

//Exports post and get methods, either from std.net.curl or mock versions
//depending on whether or not we are testing.

version(unittest) {
    char[][] mockCurlResults;

    void enqueueCurlResult(char[] result) {
        mockCurlResults ~= result;
    }

    char[] get(const(char)[] url) {
        assert(!mockCurlResults.empty);
        auto result = mockCurlResults.front;
        mockCurlResults.popFront;
        return result;
    }

    char[] post(PostUnit)(const(char)[] url, const(PostUnit)[] postData, HTTP conn = HTTP()) {
        return get(url);
    }

    void del(const(char)[] url) {
        //No-op
    }

} else {
    public import std.net.curl : post, get, del;
}

unittest {
    /* Broken when running with other tests, see:
     * http://forum.dlang.org/thread/fqbjamocnvvxpuzgmjid@forum.dlang.org#post-fqbjamocnvvxpuzgmjid
     enqueueCurlResult("test1".dup);
     enqueueCurlResult("test2".dup);
     enqueueCurlResult("test3".dup);

     assert(get("localhost") == "test1");
     assert(get("localhost") == "test2");
     assert(post("localhost", "post data") == "test3");
     del("No-op");
     */
}
