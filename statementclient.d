
import std.net.curl : HTTP;
import std.datetime : SysTime, Clock;
import std.conv : text;
import std.string : toLower;
import std.traits : EnumMembers;
import json : parseJSON;
import std.stdio;

import mockcurl : get, post;
import queryresults : QueryResults;

enum PRESTO_HEADER {
  USER = "X-Presto-User",
  SOURCE = "X-Presto-Source",
  CATALOG = "X-Presto-Catalog",
  SCHEMA = "X-Presto-Schema",
  //TIME_ZONE = "X-Presto-Time-Zone",
  //LANGUAGE = "X-Presto-Language",
}

struct ClientSession {
  this(string endpoint, string user) {
    this.endpoint = endpoint;
    this.user = user;
    this.time_zone = getThisTimeZoneId();
  }

  string endpoint = null;
  string user = null;
  string source = null;
  string schema = null;
  string catalog = null;

  //Obeys format from http://docs.oracle.com/javase/7/docs/api/java/util/TimeZone.html
  string time_zone;

  //TODO: This is non-trivial.
  //Obeys format from Java Locale
  string language = null;

  //TODO: Could conceivably cache this if the variables became properties...
  HTTP constructHeaders() const {
    auto http = HTTP();
    foreach (header; EnumMembers!PRESTO_HEADER) {
      enum memberName = mapHeaderToMemberName!header;
      addHeaderIfNotNull!(header)(http, mixin(memberName));
    }

    return http;
  }
}

string getThisTimeZoneId() {
  auto utcOffset = SysTime(0).timezone.utcOffsetAt(Clock.currTime.stdTime);
  auto hoursOffset = utcOffset.hours;
  auto offsetSign = hoursOffset > 0 ? "+" : "-";
  return "GMT" ~ offsetSign ~ text(hoursOffset);
}

struct StatementClient {
  @disable this();

  this(ClientSession session, string query) {
    this.session_ = session;
    this.query_ = query;

    auto response = post(session.endpoint, query, session.constructHeaders());
    parseAndSetResults(response);
  }

  @property {
    ClientSession session() const {
      return session_;
    }
    string query() const {
      return query_;
    }
  }

  QueryResults front() {
    return results_;
  }

  void popFront() {
    assert(!empty);
    auto response = get(results_.nextURI);
    parseAndSetResults(response);
  }

  bool empty() {
    return results_.nextURI == "";
  }

private:
  void parseAndSetResults(char[] response) {
    results_ = QueryResults(parseJSON(response));
  }

  ClientSession session_;
  string query_;
  QueryResults results_;
}

private void addHeaderIfNotNull(PRESTO_HEADER header)(ref HTTP http, string value) {
  if (value != null) {
    string headerValue = header;
    http.addRequestHeader(text(headerValue), value);
  }
}

private string mapHeaderToMemberName(PRESTO_HEADER header)() {
  return toLower(text(header));
}
