
import std.stdio : writeln;
import std.array : empty, front, popFront;
import std.conv : to, text;
import std.variant : Variant;
import std.typetuple : TypeTuple;

import sqlext;
import odbcinst;

import util : showCalled, copyToBuffer;

unittest {
  import std.c.stdlib : malloc;

  enum testSqlTypeId = SQL_TYPE_ID.SQL_SMALLINT;
  alias testSqlType = SQL_TYPES[testSqlTypeId];
  auto binding = ColumnBinding(cast(SQLLEN*) malloc(SQLLEN.sizeof));
  binding.columnType = testSqlTypeId;
  binding.outputBuffer.length = testSqlType.sizeof;
  binding.numberOfBytesWritten = -1;

  copyToOutput!(testSqlType)(Variant(5), binding);
  assert(binding.numberOfBytesWritten == testSqlType.sizeof);
  assert(*(cast(testSqlType*) binding.outputBuffer) == 5);
}

unittest {
  import std.c.stdlib : malloc;

  enum testSqlTypeId = SQL_TYPE_ID.SQL_VARCHAR;
  alias testSqlType = SQL_TYPES[testSqlTypeId];
  auto binding = ColumnBinding(cast(SQLLEN*) malloc(SQLLEN.sizeof));
  binding.columnType = testSqlTypeId;
  binding.outputBuffer.length = 10; //10 character limit including null terminator
  binding.numberOfBytesWritten = -1;

  copyToOutput!(testSqlType)(Variant("Hello world, my name is Fred"), binding);
  assert(binding.numberOfBytesWritten == 9);
  assert(cast(char[]) binding.outputBuffer == "Hello wor\0");
}

void copyToOutput(SQL_TYPE)(Variant value, ref ColumnBinding binding) {
  static void copyToOutputImpl(VARIANT_TYPE)(Variant value, ref ColumnBinding binding) {
    alias ResultType = firstNonVoidType!(SQL_TYPE, VARIANT_TYPE);

    static if (is(VARIANT_TYPE == typeof(null))) {
      binding.numberOfBytesWritten = SQL_NULL_DATA;
    } else static if (is(ResultType == string)) {
      static if (is(VARIANT_TYPE == string)) {
        auto resultCStr = cast(char[]) binding.outputBuffer;
        binding.numberOfBytesWritten = copyToBuffer(value.get!VARIANT_TYPE, resultCStr.ptr, resultCStr.length);
      } else {
        assert(false, "Should not be reachable, but should be generated.");
      }
    } else {
      assert(!is(VARIANT_TYPE == string));

      auto resultPtr = cast(ResultType*) binding.outputBuffer.ptr;
      *resultPtr = to!ResultType(value.get!VARIANT_TYPE);
      binding.numberOfBytesWritten = ResultType.sizeof;
    }
  }

  dispatchOnVariantType!(copyToOutputImpl)(value, binding);
}

version(unittest) {
  static void requireIntType(T, TList...)(TList) {
    static if (!is(T == int)) {
      assert(false, "Wrong type dispatched");
    }
  }
}

unittest {
  dispatchOnSQLType!(requireIntType)(SQL_TYPE_ID.SQL_INTEGER);
  int x = 0;
}

auto dispatchOnSQLType(alias fun, TList...)(SQL_TYPE_ID type, auto ref TList vs) {
  switch(type) {
    foreach(i, SQL_TYPE; SQL_TYPES) {
      case cast(SQL_TYPE_ID)i:
        return fun!SQL_TYPE(vs);
    }
  default:
    assert(false, "Bad SQL_TYPE_ID passed: " ~ text(type));
  }
}

unittest {
  int testValue = 5;
  dispatchOnVariantType!(requireIntType)(Variant(testValue));
}

auto dispatchOnVariantType(alias fun, TList...)(Variant value, auto ref TList vs) {
  auto type = value.type();
  foreach (T; TypeTuple!(string, short, ushort, int, uint, long, ulong, bool, SQL_TYPE_ID, typeof(null))) {
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

struct ColumnBinding {
  this(SQLLEN* indicator) {
    this.indicator = indicator;
  }

  SQL_TYPE_ID columnType;
  void[] outputBuffer;
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

  SQLLEN* indicator;
}

interface OdbcResult {
  @property {
    bool empty();
    OdbcResultRow front();
    void popFront();

    int numberOfColumns();
  }
}

class EmptyOdbcResult : OdbcResult {
  @property {
    bool empty() { return true; }
    OdbcResultRow front() { return null; }
    void popFront() {}

    int numberOfColumns() { return 0; }
  }
}

OdbcResult latestOdbcResult;

interface OdbcResultRow {
  Variant dataAt(int column);
}

enum TypeInfoResultColumns {
  TYPE_NAME = 1,
  DATA_TYPE,
  COLUMN_SIZE,
  LITERAL_PREFIX,
  LITERAL_SUFFIX,
  CREATE_PARAMS,
  NULLABLE,
  CASE_SENSITIVE,
  SEARCHABLE,
  UNSIGNED_ATTRIBUTE,
  FIXED_PREC_SCALE,
  AUTO_UNIQUE_VALUE,
  LOCAL_TYPE_NAME,
  MINIMUM_SCALE,
  MAXIMUM_SCALE,
  SQL_DATA_TYPE,
  SQL_DATETIME_SUB,
  NUM_PREC_RADIX,
  INTERVAL_PRECISION,
}

class TypeInfoResultRow : OdbcResultRow {
  Variant dataAt(int column) {
    switch(column) {
    case TypeInfoResultColumns.TYPE_NAME:
    case TypeInfoResultColumns.LOCAL_TYPE_NAME:
      return Variant("varchar");
    case TypeInfoResultColumns.DATA_TYPE:
    case TypeInfoResultColumns.SQL_DATA_TYPE:
      return Variant(SQL_TYPE_ID.SQL_VARCHAR);
    case TypeInfoResultColumns.COLUMN_SIZE:
      return Variant(120); //At most 120 characters
    case TypeInfoResultColumns.LITERAL_PREFIX:
    case TypeInfoResultColumns.LITERAL_SUFFIX:
      return Variant("'");
    case TypeInfoResultColumns.CREATE_PARAMS:
      return Variant("length");
    case TypeInfoResultColumns.NULLABLE:
      return Variant(SQL_NULLABLE);
    case TypeInfoResultColumns.CASE_SENSITIVE:
      return Variant(SQL_TRUE);
    case TypeInfoResultColumns.SEARCHABLE:
      return Variant(SQL_SEARCHABLE);
    case TypeInfoResultColumns.UNSIGNED_ATTRIBUTE:
      return Variant(null);
    case TypeInfoResultColumns.FIXED_PREC_SCALE:
      return Variant(SQL_FALSE);
    case TypeInfoResultColumns.AUTO_UNIQUE_VALUE:
      return Variant(SQL_FALSE);
    case TypeInfoResultColumns.MINIMUM_SCALE:
    case TypeInfoResultColumns.MAXIMUM_SCALE:
      return Variant(null);
    case TypeInfoResultColumns.SQL_DATETIME_SUB:
      return Variant(null);
    case TypeInfoResultColumns.NUM_PREC_RADIX:
      return Variant(null);
    case TypeInfoResultColumns.INTERVAL_PRECISION:
      return Variant(null);
    default:
      assert(false);
    }
  }
}

class TypeInfoResult : OdbcResult {
  @property {
    bool empty() {
      return poppedContents;
    }

    TypeInfoResultRow front() {
      return new TypeInfoResultRow();
    }

    void popFront() {
      poppedContents = true;
    }

    int numberOfColumns() {
      return 19;
    }
  }

private:
  bool poppedContents = false;
}
