
import std.algorithm : min;
import std.stdio : writeln;
import std.conv : to, text, wtext;
import std.traits : isNumeric, isIntegral, isSomeString, isSomeChar, Unqual;
import core.stdc.stdlib : abort;

import sqlext;
import odbcinst;
import statementclient : StatementClient, ClientSession;

void logMessage(TList...)(auto ref TList vs) {
  import std.file : append, FileException;
  enum logFile = "C:\\temp\\presto_odbc.log";

  auto message = buildDebugMessage(vs) ~ '\n';
  FileException fileException;
  for (;;) {
    try {
      append(logFile, message);
      if (fileException) {
        append(logFile, "Had at least one file exception, latest:\n"w ~ wtext(fileException));
      }
      break;
    } catch (FileException e) {
      fileException = e;
    }
  }
}

void showPopupMessage(TList...)(auto ref TList vs) {
  import std.c.windows.windows;
  auto message = buildDebugMessage(vs) ~ '\0';
  MessageBoxW(GetForegroundWindow(), message.ptr, "Presto ODBC Driver", MB_OK);
}

unittest {
  assert(buildDebugMessage("Hi", "there", 5) == "Hi there 5"w);
  assert(buildDebugMessage("Hi".ptr, "there"w.ptr, 5) == "Hi there 5"w);
  assert(buildDebugMessage(2, "there", 5) == "2 there 5"w);
  assert(buildDebugMessage(2, 3, 4) == "2 3 4"w);
  assert(buildDebugMessage("Hi", null, 5) == "Hi null 5"w);
  long addr = 12345;
  auto ptr = cast(void*)(addr);
  assert(buildDebugMessage("Hi", ptr, 5) == "Hi 3039 5"w);
}

wstring buildDebugMessage(TList...)(auto ref TList vs) {
  import std.conv : wtext;
  import std.algorithm : joiner;

  wstring[] rngOfVs;
  foreach (v; vs) {
    static if (isSomeCString!(typeof(v))) {
      if (v == null) {
        rngOfVs ~= "null_string";
        continue;
      }
      rngOfVs ~= wtext(v[0 .. strlen(v)]);
    } else {
      rngOfVs ~= wtext(v);
    }
  }
  return wtext(joiner(rngOfVs, " "));
}

void dllEnforce(bool condition, lazy string message = "dllEnforce failed", string file = __FILE__, int line = __LINE__) {
  import core.exception : Exception;

  if (!condition) {
    auto ex = new Exception(message, file, line);
    logMessage(ex);
    showPopupMessage(ex);
    abort();
  }
}

SQLRETURN exceptionBoundary(alias fun, TList...)(auto ref TList args) {
  try {
    return fun(args);
  } catch(Exception e) {
    logMessage(e);
    return SQL_ERROR;
  } catch(Error e) {
    logMessage(e);
    abort();
    assert(false, "Silence compiler errors about not returning");
  }
}

///wstring source, dest < src
unittest {
  auto src = "happySrcString"w;
  byte[] dest;
  dest.length = 12;
  assert(5 == copyToBuffer(src, OutputWChar(dest)));
  assert(cast(wchar[]) dest == "happy\0");
}

///string source, dest < src
unittest {
/*  auto src = "happySrcString";
  byte[] dest;
  dest.length = 6;
  assert(5 == copyToBuffer(src, cast(char*) dest, dest.length));
  assert(cast(char[]) dest == "happy\0");
*/
}

///wstring source, dest > src
unittest {
  auto src = "happySrcString"w;
  byte[] dest;
  dest.length = 100;
  auto numCopied = copyToBuffer(src, OutputWChar(dest));
  assert(numCopied == src.length);
  auto result = (cast(wchar[]) dest)[0 .. numCopied];
  assert(result == src);
}

SQLSMALLINT copyToBuffer(const(wchar)[] src, OutputWChar dest) {
  import std.c.string : memcpy;
  const numberOfCharsCopied = min(src.length, dest.length - 1);
  if (numberOfCharsCopied < src.length) {
    logMessage("Truncated in wide copyToBuffer: ", src, dest.length);
  }
  memcpy(dest.buffer.ptr, src.ptr, numberOfCharsCopied * wchar.sizeof);
  dest[numberOfCharsCopied] = 0;
  //dest.length = numberOfCharsCopied + 1;
  return to!SQLSMALLINT(numberOfCharsCopied);
}

SQLSMALLINT copyToBuffer(const(char)[] src, char[] dest) {
  import std.c.string : memcpy;
  const numberOfCharsCopied = min(src.length, dest.length - 1);
  if (numberOfCharsCopied < src.length) {
    logMessage("Truncated in narrow copyToBuffer: ", src, dest.length);
  }
  memcpy(dest.ptr, src.ptr, numberOfCharsCopied);
  dest[numberOfCharsCopied] = 0;
  //dest.length = numberOfCharsCopied + 1;
  return to!SQLSMALLINT(numberOfCharsCopied);
}

SQLSMALLINT wcharsToBytes(int count) {
  return to!SQLSMALLINT(count * wchar.sizeof);
}


///Test with class
unittest {
  import std.c.stdlib : free;

  class TestClass {
    this() {}
    this(int x, int y) {
      this.x = x;
      this.y = y;
    }
    int x;
    int y;
  }
  auto ptr = makeWithoutGC!TestClass();
  assert(ptr.x == 0);
  assert(ptr.y == 0);
  free(cast(void*) ptr);

  ptr = makeWithoutGC!TestClass(2, 3);
  assert(ptr.x == 2);
  assert(ptr.y == 3);
  free(cast(void*) ptr);
}

///Test with struct
unittest {
  import std.c.stdlib : free;

  struct TestStruct {
    this(int x, int y) {
      this.x = x;
      this.y = y;
    }
    int x;
    int y;
  }

  auto ptr = makeWithoutGC!TestStruct();
  assert(ptr.x == 0);
  assert(ptr.y == 0);
  free(cast(void*) ptr);

  ptr = makeWithoutGC!TestStruct(2, 3);
  assert(ptr.x == 2);
  assert(ptr.y == 3);
  free(cast(void*) ptr);

}

auto makeWithoutGC(T, TList...)(auto ref TList args) {
  import std.c.stdlib : malloc;
  auto ptr = malloc(getInstanceSize!T);
  return emplaceWrapper!T(ptr, args);
}

private auto emplaceWrapper(T, TList...)(void* memory, auto ref TList args) {
  import std.conv : emplace;

  static if (is(T == class)) {
    return emplace!T(cast(void[]) memory[0 .. getInstanceSize!T], args);
  } else {
    return emplace!T(cast(T*) memory, args);
  }
}

ulong getInstanceSize(T)() if(is(T == class)) {
  return __traits(classInstanceSize, T);
}

ulong getInstanceSize(T)() if(!is(T == class)) {
  return T.sizeof;
}

unittest {
  auto test1 = "Hello, world!";
  assert(strlen(test1.ptr) == test1.length);
  auto test2 = "Hello, world!"w;
  assert(strlen(test2.ptr) == test2.length);
  auto test3 = "Hello, world!"d;
  assert(strlen(test3.ptr) == test3.length);
}

size_t strlen(C)(const(C)* str) {
  ulong length = 0;
  for (; str[length] != 0; ++length) {
    //Intentionally blank
  }
  return length;
}

unittest {
  static assert(isSomeCString!(char*));
  static assert(isSomeCString!(wchar*));
  static assert(isSomeCString!(const (wchar)*));
  static assert(!isSomeCString!(char[]));
  static assert(!isSomeCString!(string));
}

bool isSomeCString(T)() {
  import std.traits : isPointer, PointerTarget;
  static if (isPointer!T && !is(T == void*) && isSomeChar!(PointerTarget!T)) {
    return true;
  } else {
    return false;
  }
}

unittest {
  auto str = "Hello world";
  auto wstr = "Hello world"w;
  assert(toDString(str.ptr, SQL_NTS) == str);
  assert(toDString(str.ptr, str.length) == str);
  assert(toDString(wstr.ptr, SQL_NTS) == wstr);
  assert(toDString(wstr.ptr, wstr.length) == wstr);
}

C[] toDString(C)(C* cString, size_t lengthChars) if (isSomeChar!C) {
  if (cString == null) {
    return null;
  }
  if (lengthChars == SQL_NTS) {
    lengthChars = strlen(cString);
  }
  return cString[0 .. lengthChars];
}

template UnqualString(T) {
  static if (!isSomeString!T) {
    static assert(false, "Not a string");
  } else {
    alias CharType =  typeof(T.init[0]);
    alias UnqualString = Unqual!(CharType)[];
  }
}

struct OutputWChar {
  this(wchar* buffer, size_t lengthBytes) {
    assert(buffer != null); //Revisit?
    assert(lengthBytes % 2 == 0);
    assert(lengthBytes >= 2);

    this.buffer = buffer[0 .. lengthBytes / 2];
  }

  this(SQLPOINTER buffer, size_t lengthBytes) {
    this(cast(wchar*) buffer, lengthBytes);
  }

  this(void[] buffer) {
    this(buffer.ptr, buffer.length);
  }


  wchar[] buffer;
  alias buffer this;
}

StatementClient runQuery(string query) {
  auto session = ClientSession("localhost:8080", "ODBC Driver");
  session.catalog = "tpch";
  session.schema = "tiny";

  return StatementClient(session, query);
}
