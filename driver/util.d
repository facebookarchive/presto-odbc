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
module presto.odbcdriver.util;

import std.array : front, popFront, empty, appender;
import std.algorithm : min;
import std.stdio : writeln;
import std.conv : to, text, wtext;
import std.file : append, write, readText, remove, exists, FileException;
import std.traits : isNumeric, isIntegral, isSomeString, isSomeChar, Unqual;
import core.stdc.stdlib : abort;
import core.exception : Exception;
import core.time : dur, Duration;
import std.net.curl : HTTP, CurlException;
import std.string: format;
import std.datetime: Clock;

import odbc.sqlext;
import odbc.odbcinst;

import presto.client.statementclient : StatementClient, ClientSession;

import presto.odbcdriver.handles : OdbcStatement, OdbcConnection;

enum tempPath = "C:\\temp\\";
auto logBuffer = appender!wstring;

void logMessage(TList...)(auto ref TList vs) {
    logBuffer ~= buildDebugMessage(vs);
    logBuffer ~= '\n';
    if (logBuffer.data.length > 100000) {
        flushLogBuffer();
    }
}

void logCriticalMessage(TList...)(auto ref TList vs) {
    logBuffer ~= buildDebugMessage(vs);
    logBuffer ~= '\n';
    flushLogBuffer();
}

void flushLogBuffer() {
    enum logFile = tempPath ~ "presto_odbc.log";

    FileException fileException;
    for (;;) {
        try {
            logFile.append(logBuffer.data);
            logBuffer.clear();
            if (fileException) {
                append(logFile, "Had at least one file exception, latest:\n"w ~ wtext(fileException));
            }
            break;
        } catch (FileException e) {
            if (fileException) {
                e.next = fileException;
            }
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

wstring buildDebugMessage(string fileName = __FILE__, int lineNumber = __LINE__, TList...)(auto ref TList vs) {
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
    version(unittest) {
    	return wtext(joiner(rngOfVs, " "));
    }
    
    return wtext(format("%s %s:%d %s", Clock.currTime().toSimpleString(), fileName, lineNumber, joiner(rngOfVs, " ")));
}

/**
 * TODO: Create a "real" GUI
 * This is a temporary/hacky solution that allows us to offer a
 * "GUI" for entering connection properties without having to actually
 * include/link with a cross-platform graphics library. This will be
 * removed in the future.
 */
string getTextInput(string fileTemplate = "") {
    import std.process : execute;

    auto tempFile = makeTempFile(fileTemplate);
    scope (exit) { tempFile.remove; }
    if (auto rc = execute(["notepad.exe", tempFile]).status != 0) {
        throw new OdbcException(StatusCode.GENERAL_ERROR, "Notepad returned bad return code "w ~ wtext(rc));
    }
    return tempFile.readText!string();
}

string makeTempFile(string content = "")
out(tempFile) {
    dllEnforce(tempFile.exists, "File must exist");
} body {
    import std.random : uniform;

    Exception eSaved;
    for (auto i = 0; i < 10; ++i) {
        try {
            //As long as this driver is single-threaded I don't believe we're likely
            //to find this problematic.
            auto tempFile = tempPath ~ "temp" ~ text(uniform(0, 1_000_000));
            if (tempFile.exists) {
                continue;
            }
            tempFile.write(content);
            return tempFile;
        } catch (Exception e) { eSaved = e; }
    }
    throw new OdbcException(StatusCode.GENERAL_ERROR, "Failed to make temp file"w ~ wtext(eSaved));
}

void dllEnforce(bool condition, lazy string message = "dllEnforce failed", string file = __FILE__, int line = __LINE__) {
    import core.exception : Exception;

    if (!condition) {
        auto ex = new Exception(message, file, line);
        logCriticalMessage(ex);
        showPopupMessage(ex);
        abort();
    }
}

SQLRETURN exceptionBoundary(alias fun, TList...)(auto ref TList args) {
    import presto.client.prestoerrors : QueryException;

    try {
        return fun(args);
    } catch (OdbcException e) {
        logCriticalMessage("OdbcException:", e.file ~ ":" ~ text(e.line), e.msg);
        return SQL_ERROR;
    } catch (QueryException e) {
        logCriticalMessage("QueryException:", e.message);
        return SQL_ERROR;
    } catch (Exception e) {
        logCriticalMessage(e);
        return SQL_ERROR;
    } catch (Error e) {
        logCriticalMessage(e);
        abort();
        assert(false, "Silence compiler errors about not returning");
    }
}

unittest {
    try {
        throw new OdbcException("HY000", "Test");
    } catch (OdbcException e) {}
}

class OdbcException : Exception {

    this(T)(T handle, StatusCode sqlState, wstring message, int code = 1,
            string file = __FILE__, int line = __LINE__) if (is(T == OdbcStatement) || is(T == OdbcConnection)){
        this(sqlState, message, code, file, line);
        handle.errors ~= this;
    }
    this(wstring sqlState, wstring message, int code = 1, string file = __FILE__, int line = __LINE__) {
        super(text(message), file, line);
        dllEnforce(sqlState.length == 5);
        this.sqlState = sqlState;
        this.message = message;
        this.code = code;
    }

    immutable wstring sqlState;
    immutable wstring message;
    immutable int code;
}

///wstring source, dest < src
unittest {
    auto src = "happySrcString"w;
    byte[] dest;
    dest.length = 12;
    SQLSMALLINT numberOfBytesCopied;
    copyToBuffer(src, outputWChar(dest, &numberOfBytesCopied));
    assert(numberOfBytesCopied == 10);
    assert(cast(wchar[]) dest == "happy\0");
}

///wstring source, dest > src
unittest {
    auto src = "happySrcString"w;
    byte[] dest;
    dest.length = 100;
    SQLSMALLINT numberOfBytesCopied;
    copyToBuffer(src, outputWChar(dest, &numberOfBytesCopied));
    assert(numberOfBytesCopied == src.length * wchar.sizeof);
    auto result = cast(wchar[]) (dest[0 .. numberOfBytesCopied]);
    assert(result == src);
}

void copyToBuffer(N)(const(wchar)[] src, OutputWChar!N dest) {
    import std.c.string : memcpy;
    const numberOfCharsCopied = min(src.length, dest.length - 1);
    if (numberOfCharsCopied < src.length) {
        logMessage("Truncated in wide copyToBuffer: ", src, dest.length);
    }
    memcpy(dest.buffer.ptr, src.ptr, numberOfCharsCopied * wchar.sizeof);
    dest[numberOfCharsCopied] = 0;
    dest.lengthBytes = wcharsToBytes(numberOfCharsCopied);
}

SQLSMALLINT copyToNarrowBuffer(const(char)[] src, char[] dest) {
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

size_t wcharsToBytes(size_t count) {
    return count * wchar.sizeof;
}

size_t bytesToWchars(size_t count) {
    return count / wchar.sizeof;
}

void convertPtrBytesToWChars(T)(T* lengthBytes) {
    if (!lengthBytes) {
        return;
    }
    *lengthBytes = cast(T) bytesToWchars(*lengthBytes);
}

unittest {
    auto testArray = [1, 2, 3, 4, 5];
    assert(popAndSave(testArray) == 1);
    assert(popAndSave(testArray) == 2);
    assert(popAndSave(testArray) == 3);
}

auto popAndSave(Range)(ref Range r) {
    auto result = r.front;
    r.popFront;
    return result;
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

inout(C)[] toDString(C)(inout(C)* cString, size_t lengthChars) if (isSomeChar!C) {
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

auto outputWChar(LengthType)(wchar* buffer, size_t maxLengthBytes, LengthType* lengthBytes) {
    return OutputWChar!LengthType(buffer, maxLengthBytes, lengthBytes);
}

auto outputWChar(LengthType)(SQLPOINTER buffer, size_t maxLengthBytes, LengthType* lengthBytes) {
    return outputWChar(cast(wchar*) buffer, maxLengthBytes, lengthBytes);
}

auto outputWChar(LengthType)(void[] buffer, LengthType* lengthBytes) {
    return outputWChar!LengthType(buffer.ptr, buffer.length, lengthBytes);
}

struct OutputWChar(LengthType) {
    private this(wchar* buffer, size_t maxLengthBytes, LengthType* lengthBytes) {
        lengthBytes_ = lengthBytes;
        this.lengthBytes = 0;

        if (buffer == null) {
            this.buffer = null;
            return;
        }

        if (maxLengthBytes % 2 != 0 || maxLengthBytes < 2) {
            logMessage("Warning! maxLengthBytes is", maxLengthBytes);
            this.buffer = null;
            return;
        }

        this.buffer = buffer[0 .. maxLengthBytes / 2];
    }

    void lengthBytes(size_t lengthBytes) {
        if (!lengthBytes_) {
            return;
        }
        *lengthBytes_ = cast(LengthType) lengthBytes;
    }

    bool opEquals(T : typeof(null))(T value) {
        return buffer == null;
    }

    bool opCast(T : bool)() {
        return buffer != null;
    }

    unittest {
        auto x = OutputWChar(null, 0, null);
        assert(x == null);
    }

    wchar[] buffer;
    LengthType* lengthBytes_;
    alias buffer this;
}

unittest {
    auto associativeArray = ["bob":1, "joe":2];
    assert(associativeArray.getOrDefault("bob") == 1);
    assert(associativeArray.getOrDefault("frank") == 0);
}

V getOrDefault(K, V)(V[K] associativeArray, K key, V default_ = V.init) {
    if (auto valuePointer = key in associativeArray) {
        return *valuePointer;
    }
    return default_;
}

StatementClient runQuery(OdbcStatement statementHandle, string query) {
    with (statementHandle.connection) {
        auto session = ClientSession(endpoint, "ODBC Driver");
        session.catalog = catalog;
        session.schema = schema.empty ? "tiny" : schema;

        return StatementClient(session, query);
    }
}

unittest {
    assert(escapeSqlIdentifier(r"bob") == `"bob"`);
    assert(escapeSqlIdentifier(`"bob"`) == `"""bob"""`);
}

string escapeSqlIdentifier(string identifier) {
    auto result = appender!string;
    result.reserve(identifier.length + 2);
    result ~= '"';

    foreach (c; identifier) {
        if (c != '"') {
            result ~= c;
        } else {
            result ~= `""`;
        }
    }
    result ~= '"';

    return result.data;
}
