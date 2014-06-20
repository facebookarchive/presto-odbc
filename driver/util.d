
import std.algorithm : min;
import std.stdio : writeln;
import std.traits : isNumeric, isIntegral, isSomeString, isSomeChar, Unqual;
import std.c.stdlib : abort;

import sqlext;
import odbcinst;

void logMessage(TList...)(auto ref TList vs) {
  import std.file : append;
  auto message = buildDebugMessage(vs) ~ '\n';
  append("C:\\Users\\markisaa\\Desktop\\presto_odbc.log", message);
}

void showPopupMessage(TList...)(auto ref TList vs) {
  import std.c.windows.windows;
  auto message = buildDebugMessage(vs) ~ '\0';
  MessageBoxW(GetForegroundWindow(), message.ptr, "Presto ODBC Driver", MB_OK);
}

unittest {
  assert(buildDebugMessage("Hi", "there", 5) == "Hi there 5"w);
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
    rngOfVs ~= wtext(v);
  }
  return wtext(joiner(rngOfVs, " "));
}

void dllEnforce(bool condition, lazy string message = "dllEnforce failed", string file = __FILE__, int line = __LINE__) {
  import core.exception : Exception;

  if (!condition) {
    auto ex = new Exception(message, file, line);
    logMessage(ex);
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
  }
}

///wstring source, dest < src
unittest {
  auto src = "happySrcString"w;
  byte[] dest;
  dest.length = 12;
  assert(10 == copyToBuffer(src, cast(void*) dest, dest.length));
  assert(cast(wchar[]) dest == "happy\0");
}

///string source, dest < src
unittest {
  auto src = "happySrcString";
  byte[] dest;
  dest.length = 6;
  assert(5 == copyToBuffer(src, cast(void*) dest, dest.length));
  assert(cast(char[]) dest == "happy\0");
}

///wstring source, dest > src
unittest {
  auto src = "happySrcString"w;
  byte[] dest;
  dest.length = 100;
  auto numCopied = copyToBuffer(src, cast(void*) dest, dest.length);
  assert(numCopied == src.length * wchar.sizeof);
  auto result = (cast(wchar[]) dest)[0 .. numCopied / wchar.sizeof];
  assert(result == src);
}

SQLSMALLINT copyToBuffer(C)(const(C)[] src, SQLPOINTER dest, ulong destSize) if (isSomeChar!C) {
  import std.c.string : memcpy;
  const numCopied = cast(SQLSMALLINT) min(src.length * C.sizeof, destSize - C.sizeof);
  memcpy(dest, src.ptr, numCopied);
  *(cast(C*) (dest + numCopied)) = 0;
  return numCopied;
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
