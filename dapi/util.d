
module dapi.util;

class PrestoClientException : Exception {
  this(string msg) {
    super(msg);
  }
}
