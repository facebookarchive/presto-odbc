
import std.algorithm : min;
import std.stdio : writeln;
import std.traits : isNumeric, isIntegral, isSomeString, isSomeChar, Unqual;

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
