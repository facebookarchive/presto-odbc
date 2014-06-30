
import std.variant : Variant;

import sqlext;
import odbcinst;

import bindings : OdbcResult, OdbcResultRow;


final class TypeInfoResult(RowT) : OdbcResult {
  this(TList...)(TList vs) {
    result = new RowT(vs);
  }

  @property {
    bool empty() {
      return poppedContents;
    }

    RowT front() {
      assert(!empty);
      return result;
    }

    void popFront() {
      poppedContents = true;
    }

    uint numberOfColumns() {
      return TypeInfoResultColumns.max;
    }
  }

private:
  RowT result;
  bool poppedContents = false;
}

alias SQL_SIGNED = SQL_FALSE;
alias SQL_UNSIGNED = SQL_TRUE;
enum SQL_HAS_NO_SIGN = null;

final class VarcharTypeInfoResultRow : OdbcResultRow {
  this(Nullability isNullable) {
    this.isNullable = isNullable;
  }

  Variant dataAt(int column) {
    switch(column) {
    case TypeInfoResultColumns.TYPE_NAME:
    case TypeInfoResultColumns.LOCAL_TYPE_NAME:
      return Variant("VARCHAR");
    case TypeInfoResultColumns.DATA_TYPE:
    case TypeInfoResultColumns.SQL_DATA_TYPE:
      return Variant(SQL_TYPE_ID.SQL_VARCHAR);
    case TypeInfoResultColumns.COLUMN_SIZE:
      return Variant(SQL_NO_TOTAL); //Any number of characters
    case TypeInfoResultColumns.LITERAL_PREFIX:
    case TypeInfoResultColumns.LITERAL_SUFFIX:
      return Variant("'");
    case TypeInfoResultColumns.CREATE_PARAMS:
      return Variant("length");
    case TypeInfoResultColumns.NULLABLE:
      return Variant(isNullable);
    case TypeInfoResultColumns.CASE_SENSITIVE:
      return Variant(SQL_TRUE);
    case TypeInfoResultColumns.SEARCHABLE:
      return Variant(SQL_SEARCHABLE);
    case TypeInfoResultColumns.UNSIGNED_ATTRIBUTE:
      return Variant(SQL_HAS_NO_SIGN);
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
private:
  Nullability isNullable;
}

/*
 * TODO: Turns out that these should be named after the SQL type, not the Presto type
 *
final class TypeInfoResultRow : OdbcResultRow {
  this(Nullability isNullable) {
    this.isNullable = isNullable;
  }

  Variant dataAt(int column) {
    switch(column) {
    case TypeInfoResultColumns.TYPE_NAME:
    case TypeInfoResultColumns.LOCAL_TYPE_NAME:
      return Variant("BOOLEAN");
    case TypeInfoResultColumns.DATA_TYPE:
    case TypeInfoResultColumns.SQL_DATA_TYPE:
      return Variant(SQL_TYPE_ID.SQL_SMALLINT);
    case TypeInfoResultColumns.COLUMN_SIZE:
      return Variant(5);
    case TypeInfoResultColumns.LITERAL_PREFIX:
    case TypeInfoResultColumns.LITERAL_SUFFIX:
      return Variant(null);
    case TypeInfoResultColumns.CREATE_PARAMS:
      return Variant(null);
    case TypeInfoResultColumns.NULLABLE:
      return Variant(isNullable);
    case TypeInfoResultColumns.CASE_SENSITIVE:
      return Variant(SQL_FALSE);
    case TypeInfoResultColumns.SEARCHABLE:
      return Variant(SQL_SEARCHABLE);
    case TypeInfoResultColumns.UNSIGNED_ATTRIBUTE:
      return Variant(SQL_SIGNED);
    case TypeInfoResultColumns.FIXED_PREC_SCALE:
      return Variant(SQL_FALSE);
    case TypeInfoResultColumns.AUTO_UNIQUE_VALUE:
      return Variant(SQL_FALSE); //Will need to look into this more.
    case TypeInfoResultColumns.MINIMUM_SCALE:
    case TypeInfoResultColumns.MAXIMUM_SCALE:
      return Variant(null); //What is this? Docs unclear.
    case TypeInfoResultColumns.SQL_DATETIME_SUB:
      return Variant(null);
    case TypeInfoResultColumns.NUM_PREC_RADIX:
      return Variant(10);
    case TypeInfoResultColumns.INTERVAL_PRECISION:
      return Variant(null);
    default:
      assert(false);
    }
  }
private:
  Nullability isNullable;
}
*/

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
