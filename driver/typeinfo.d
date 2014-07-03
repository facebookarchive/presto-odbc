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

import std.variant : Variant;

import sqlext;
import odbcinst;

import bindings : OdbcResult, OdbcResultRow;


//Does not include interval types/SQL_DECIMAL/SQL_NUMERIC
enum SQLSMALLINT[SQL_TYPE_ID] columnSizeMap = [
  SQL_TYPE_ID.SQL_CHAR : SQL_NO_TOTAL,
  SQL_TYPE_ID.SQL_VARCHAR : SQL_NO_TOTAL,
  SQL_TYPE_ID.SQL_BINARY : SQL_NO_TOTAL,
  SQL_TYPE_ID.SQL_VARBINARY : SQL_NO_TOTAL,
  SQL_TYPE_ID.SQL_LONGVARBINARY : SQL_NO_TOTAL,
  SQL_TYPE_ID.SQL_BIT : 1,
  SQL_TYPE_ID.SQL_TINYINT : 3,
  SQL_TYPE_ID.SQL_SMALLINT : 5,
  SQL_TYPE_ID.SQL_INTEGER : 10,
  SQL_TYPE_ID.SQL_BIGINT : 19,
  SQL_TYPE_ID.SQL_REAL : 7,
  SQL_TYPE_ID.SQL_FLOAT : 15,
  SQL_TYPE_ID.SQL_DOUBLE : 15,
  SQL_TYPE_ID.SQL_TYPE_DATE : 10,
  SQL_TYPE_ID.SQL_TYPE_TIME : 11,
  SQL_TYPE_ID.SQL_TYPE_TIMESTAMP : 22,
  SQL_TYPE_ID.SQL_GUID : 36,
];

//Does not include interval types/SQL_DECIMAL/SQL_NUMERIC
enum SQLSMALLINT[SQL_TYPE_ID] decimalDigitsMap = [
  SQL_TYPE_ID.SQL_CHAR : 0,
  SQL_TYPE_ID.SQL_VARCHAR : 0,
  SQL_TYPE_ID.SQL_BINARY : 0,
  SQL_TYPE_ID.SQL_VARBINARY : 0,
  SQL_TYPE_ID.SQL_LONGVARBINARY : 0,
  SQL_TYPE_ID.SQL_BIT : 0,
  SQL_TYPE_ID.SQL_TINYINT : 0,
  SQL_TYPE_ID.SQL_SMALLINT : 0,
  SQL_TYPE_ID.SQL_INTEGER : 0,
  SQL_TYPE_ID.SQL_BIGINT : 0,
  SQL_TYPE_ID.SQL_REAL : 0,
  SQL_TYPE_ID.SQL_FLOAT : 0,
  SQL_TYPE_ID.SQL_DOUBLE : 0,
  SQL_TYPE_ID.SQL_TYPE_DATE : 0,
  SQL_TYPE_ID.SQL_TYPE_TIME : 3,
  SQL_TYPE_ID.SQL_TYPE_TIMESTAMP : 3,
  SQL_TYPE_ID.SQL_GUID : 0,
];

//Does not include interval types/SQL_DECIMAL/SQL_NUMERIC
enum SQLSMALLINT[SQL_TYPE_ID] displaySizeMap = [
  SQL_TYPE_ID.SQL_CHAR : SQL_NO_TOTAL,
  SQL_TYPE_ID.SQL_VARCHAR : SQL_NO_TOTAL,
  SQL_TYPE_ID.SQL_BINARY : SQL_NO_TOTAL,
  SQL_TYPE_ID.SQL_VARBINARY : SQL_NO_TOTAL,
  SQL_TYPE_ID.SQL_LONGVARBINARY : SQL_NO_TOTAL,
  SQL_TYPE_ID.SQL_BIT : 1,
  SQL_TYPE_ID.SQL_TINYINT : 4,
  SQL_TYPE_ID.SQL_SMALLINT : 6,
  SQL_TYPE_ID.SQL_INTEGER : 11,
  SQL_TYPE_ID.SQL_BIGINT : 20,
  SQL_TYPE_ID.SQL_REAL : 14,
  SQL_TYPE_ID.SQL_FLOAT : 24,
  SQL_TYPE_ID.SQL_DOUBLE : 24,
  SQL_TYPE_ID.SQL_TYPE_DATE : 10,
  SQL_TYPE_ID.SQL_TYPE_TIME : 11,
  SQL_TYPE_ID.SQL_TYPE_TIMESTAMP : 22,
  SQL_TYPE_ID.SQL_GUID : 36,
];

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
      return Variant(columnSizeMap[SQL_TYPE_ID.SQL_VARCHAR]);
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
