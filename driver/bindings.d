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

import std.stdio : writeln;
import std.array : empty, front, popFront;
import std.conv : to, text, wtext;
import std.variant : Variant;
import std.typetuple : TypeTuple;
import std.traits : isSomeString, Unqual;

import sqlext;
import odbcinst;

import util : logMessage, copyToNarrowBuffer, dllEnforce, OutputWChar, wcharsToBytes;

/**
  An OdbcStatement handle object is allocated for each HSTATEMENT requested by the driver/client.
*/
final class OdbcStatement {
  this() {
    latestOdbcResult = new EmptyOdbcResult();
  }

  ColumnBinding[uint] columnBindings;
  OdbcResult latestOdbcResult;
  wstring query;
  OdbcError[] errors;
}

struct OdbcError {
  this(wstring sqlState, wstring message, int code = 1, string file = __FILE__, int line = __LINE__) {
    import core.exception : Exception;
    dllEnforce(sqlState.length == 5);
    logMessage("OdbcError:", new Exception(text(message), file, line));
    this.sqlState = sqlState;
    this.message = message;
    this.code = code;
  }

  immutable wstring sqlState;
  immutable wstring message;
  immutable int code;
}

unittest {
  enum testSqlTypeId = SQL_C_TYPE_ID.SQL_C_LONG;
  alias testSqlType = int;
  auto binding = ColumnBinding(new SQLLEN);
  binding.columnType = testSqlTypeId;
  binding.outputBuffer.length = testSqlType.sizeof;
  binding.numberOfBytesWritten = -1;

  copyToOutput!(testSqlType)(Variant(5), binding);
  assert(binding.numberOfBytesWritten == testSqlType.sizeof);
  assert(*(cast(testSqlType*) binding.outputBuffer) == 5);
}

unittest {
  enum testSqlTypeId = SQL_C_TYPE_ID.SQL_C_CHAR;
  alias testSqlType = string;
  auto binding = ColumnBinding(new SQLLEN);
  binding.columnType = testSqlTypeId;
  binding.outputBuffer.length = 10;
  binding.numberOfBytesWritten = -1;

  copyToOutput!(testSqlType)(Variant("Hello world, my name is Fred"), binding);
  assert(binding.numberOfBytesWritten == 9);
  assert(cast(char[]) binding.outputBuffer == "Hello wor\0");
}

//Writes the value inside the Variant into the buffer specified by the binding
void copyToOutput(SQL_C_TYPE)(Variant value, ref ColumnBinding binding) {

  static void copyToOutputImpl(VARIANT_TYPE)(Variant value, ref ColumnBinding binding) {
    alias ResultType = firstNonVoidType!(SQL_C_TYPE, VARIANT_TYPE);

    with (binding) {
      static if (is(VARIANT_TYPE == typeof(null))) {
        numberOfBytesWritten = SQL_NULL_DATA;
      } else static if (is(ResultType == string)) {
        static if (is(VARIANT_TYPE == string)) {
          auto srcString = value.get!VARIANT_TYPE;
        } else {
          logMessage("Converting a non-string type to a string type for output");
          auto srcString = to!ResultType(value.get!VARIANT_TYPE);
        }
        numberOfBytesWritten = copyToNarrowBuffer(srcString, cast(char[]) outputBuffer);
      } else {
        assert(!isSomeString!VARIANT_TYPE, "" ~ text(typeid(ResultType)) ~ " " ~ text(typeid(VARIANT_TYPE)));

        auto resultPtr = cast(ResultType*) outputBuffer.ptr;
        *resultPtr = to!ResultType(value.get!VARIANT_TYPE);
        numberOfBytesWritten = ResultType.sizeof;
      }
    }
  } //with

  dispatchOnVariantType!(copyToOutputImpl)(value, binding);
}

unittest {
  dispatchOnSqlCType!(requireIntType)(SQL_C_TYPE_ID.SQL_C_LONG);
}

auto dispatchOnSqlCType(alias fun, TList...)(SQL_C_TYPE_ID type, auto ref TList vs) {
  auto impl(SqlTList...)() {
    static if (SqlTList.length <= 1) {
      assert(false, "Bad SQL_TYPE_ID passed: " ~ text(type));
    } else {
      if (type == SqlTList[0]) {
        return fun!(SqlTList[1])(vs);
      } else {
        return impl!(SqlTList[2 .. $])();
      }
    }
  }
  return impl!SQL_C_TYPES();
}

version(unittest) {
  static void requireIntType(T, TList...)(TList) {
    static if (!is(T == int)) {
      assert(false, "Wrong type dispatched");
    }
  }
}

unittest {
  int testValue = 5;
  dispatchOnVariantType!(requireIntType)(Variant(testValue));
}

auto dispatchOnVariantType(alias fun, TList...)(Variant value, auto ref TList vs) {
  auto type = value.type();
  foreach (T; TypeTuple!(string, short, ushort, int, uint, long, ulong, bool,
          double, Nullability, SQL_TYPE_ID, typeof(null))) {
    if(type == typeid(T)) {
      return fun!T(value, vs);
    }
  }
  assert(false, "Unexpected type in variant: " ~ text(value.type()));
}

unittest {
  static assert(is(firstNonVoidType!(int, void, double) == int));
  static assert(is(firstNonVoidType!(void, double) == double));
  static assert(is(firstNonVoidType!(void, void, double) == double));
}

template firstNonVoidType(TList...) {
  static assert(TList.length != 0, "No non-void types in the list");

  static if (is(TList[0] == void)) {
    alias firstNonVoidType = .firstNonVoidType!(TList[1 .. $]);
  } else {
    alias firstNonVoidType = TList[0];
  }
}

/**
 * Stores information about how to return results to the user for a particular column.
 */
struct ColumnBinding {
  this(SQLLEN* indicator) {
    this.indicator = indicator;
  }

  SQL_C_TYPE_ID columnType;
  void[] outputBuffer;
  SQLLEN* indicator;

  @property {
    SQLLEN numberOfBytesWritten() {
      assert(indicator != null);
      return *indicator;
    }
    void numberOfBytesWritten(SQLLEN value) {
      if (indicator != null) {
        *indicator = value;
      }
    }
  }
}

/**
 * A range that allows retrieving one row at a time from the result set of a query.
 */
interface OdbcResult {
  @property {
    bool empty();
    OdbcResultRow front();
    void popFront();

    uint numberOfColumns();
  }
}

final class EmptyOdbcResult : OdbcResult {
  @property {
    bool empty() { return true; }
    OdbcResultRow front() { return null; }
    void popFront() {}

    uint numberOfColumns() { return 0; }
  }
}

interface OdbcResultRow {
  Variant dataAt(int column);
}
