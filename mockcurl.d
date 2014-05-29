
import std.array : empty, front, popFront;
import std.net.curl : HTTP;

//Exports post and get methods, either from std.net.curl or mock versions
//depending on whether or not we are testing.

version(unittest) {
  alias CurlResultType = char[];
  CurlResultType[] mockCurlResults;

  void enqueueCurlResult(CurlResultType result) {
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
