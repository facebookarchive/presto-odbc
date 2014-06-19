
import std.algorithm : min;
import std.stdio : writeln;
import std.traits : isNumeric, isIntegral, isSomeString, isSomeChar, Unqual;

import sqlext;
import odbcinst;

unittest {
  //showCalled("Hi", "there" , 5);
}

void showCalled(Ts...)(Ts vs) if (vs.length > 0) {
  import std.conv : wtext;
  import std.algorithm : joiner, equal;
  import std.c.windows.windows;

  wstring[] rngOfVs;
  foreach (v; vs) {
    rngOfVs ~= wtext(v);
  }
  auto message = joiner(rngOfVs, " ");

  MessageBoxW(GetForegroundWindow(), wtext(message).ptr, wtext(vs[0]).ptr, MB_OK);
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
