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
module presto.odbcdriver.typeinfo;

import std.variant : Variant;

import odbc.sqlext;
import odbc.odbcinst;

import presto.odbcdriver.bindings : OdbcResult, OdbcResultRow;


// http://msdn.microsoft.com/en-us/library/ms711786(v=vs.85).aspx
//Does not include SQL_DECIMAL/SQL_NUMERIC
enum SQLSMALLINT[SQL_TYPE_ID] columnSizeMap = [
    SQL_TYPE_ID.SQL_CHAR : SQL_NO_TOTAL,
    SQL_TYPE_ID.SQL_VARCHAR : SQL_NO_TOTAL,
    SQL_TYPE_ID.SQL_LONGVARCHAR : SQL_NO_TOTAL,
    SQL_TYPE_ID.SQL_WCHAR : SQL_NO_TOTAL,
    SQL_TYPE_ID.SQL_WVARCHAR : SQL_NO_TOTAL,
    SQL_TYPE_ID.SQL_WLONGVARCHAR : SQL_NO_TOTAL,
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
    SQL_TYPE_ID.SQL_DATE : 10,
    SQL_TYPE_ID.SQL_TIME : 11,
    SQL_TYPE_ID.SQL_TIMESTAMP : 22,
    SQL_TYPE_ID.SQL_DATETIME : 22,
    //Told by Dain to pick an arbitary large number for intervals
    SQL_TYPE_ID.SQL_INTERVAL_YEAR : 30,
    SQL_TYPE_ID.SQL_INTERVAL_MONTH : 30,
    SQL_TYPE_ID.SQL_INTERVAL_DAY : 30,
    SQL_TYPE_ID.SQL_INTERVAL_HOUR : 30,
    SQL_TYPE_ID.SQL_INTERVAL_MINUTE : 30,
    SQL_TYPE_ID.SQL_INTERVAL_SECOND : 30,
    SQL_TYPE_ID.SQL_INTERVAL_YEAR_TO_MONTH : 30,
    SQL_TYPE_ID.SQL_INTERVAL_DAY_TO_HOUR : 30,
    SQL_TYPE_ID.SQL_INTERVAL_DAY_TO_MINUTE : 30,
    SQL_TYPE_ID.SQL_INTERVAL_DAY_TO_SECOND : 30,
    SQL_TYPE_ID.SQL_INTERVAL_HOUR_TO_MINUTE : 30,
    SQL_TYPE_ID.SQL_INTERVAL_HOUR_TO_SECOND : 30,
    SQL_TYPE_ID.SQL_INTERVAL_MINUTE_TO_SECOND : 30,
    SQL_TYPE_ID.SQL_GUID : 36,
];

// http://msdn.microsoft.com/en-us/library/ms709314(v=vs.85).aspx
//Does not include SQL_DECIMAL/SQL_NUMERIC
enum SQLSMALLINT[SQL_TYPE_ID] decimalDigitsMap = [
    SQL_TYPE_ID.SQL_CHAR : 0,
    SQL_TYPE_ID.SQL_VARCHAR : 0,
    SQL_TYPE_ID.SQL_LONGVARCHAR : 0,
    SQL_TYPE_ID.SQL_WCHAR : 0,
    SQL_TYPE_ID.SQL_WVARCHAR : 0,
    SQL_TYPE_ID.SQL_WLONGVARCHAR : 0,
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
    SQL_TYPE_ID.SQL_DATE : 0,
    SQL_TYPE_ID.SQL_TIME : 3,
    SQL_TYPE_ID.SQL_TIMESTAMP : 3,
    SQL_TYPE_ID.SQL_DATETIME : 3,
    SQL_TYPE_ID.SQL_INTERVAL_YEAR : 0,
    SQL_TYPE_ID.SQL_INTERVAL_MONTH : 0,
    SQL_TYPE_ID.SQL_INTERVAL_DAY : 0,
    SQL_TYPE_ID.SQL_INTERVAL_HOUR : 0,
    SQL_TYPE_ID.SQL_INTERVAL_MINUTE : 0,
    SQL_TYPE_ID.SQL_INTERVAL_SECOND : 3,
    SQL_TYPE_ID.SQL_INTERVAL_YEAR_TO_MONTH : 0,
    SQL_TYPE_ID.SQL_INTERVAL_DAY_TO_HOUR : 0,
    SQL_TYPE_ID.SQL_INTERVAL_DAY_TO_MINUTE : 0,
    SQL_TYPE_ID.SQL_INTERVAL_DAY_TO_SECOND : 3,
    SQL_TYPE_ID.SQL_INTERVAL_HOUR_TO_MINUTE : 0,
    SQL_TYPE_ID.SQL_INTERVAL_HOUR_TO_SECOND : 3,
    SQL_TYPE_ID.SQL_INTERVAL_MINUTE_TO_SECOND : 3,
    SQL_TYPE_ID.SQL_GUID : 0,
];

// http://msdn.microsoft.com/en-us/library/ms713979(v=vs.85).aspx
//Does not include SQL_DECIMAL/SQL_NUMERIC
enum SQLSMALLINT[SQL_TYPE_ID] octetLengthMap = [
    SQL_TYPE_ID.SQL_CHAR : SQL_NO_TOTAL,
    SQL_TYPE_ID.SQL_VARCHAR : SQL_NO_TOTAL,
    SQL_TYPE_ID.SQL_LONGVARCHAR : SQL_NO_TOTAL,
    SQL_TYPE_ID.SQL_WCHAR : SQL_NO_TOTAL,
    SQL_TYPE_ID.SQL_WVARCHAR : SQL_NO_TOTAL,
    SQL_TYPE_ID.SQL_WLONGVARCHAR : SQL_NO_TOTAL,
    SQL_TYPE_ID.SQL_BINARY : SQL_NO_TOTAL,
    SQL_TYPE_ID.SQL_VARBINARY : SQL_NO_TOTAL,
    SQL_TYPE_ID.SQL_LONGVARBINARY : SQL_NO_TOTAL,
    SQL_TYPE_ID.SQL_BIT : 1,
    SQL_TYPE_ID.SQL_TINYINT : 1,
    SQL_TYPE_ID.SQL_SMALLINT : 2,
    SQL_TYPE_ID.SQL_INTEGER : 4,
    SQL_TYPE_ID.SQL_BIGINT : 40,
    SQL_TYPE_ID.SQL_REAL : 4,
    SQL_TYPE_ID.SQL_FLOAT : 8,
    SQL_TYPE_ID.SQL_DOUBLE : 8,
    SQL_TYPE_ID.SQL_DATE : 6,
    SQL_TYPE_ID.SQL_TIME : 6,
    SQL_TYPE_ID.SQL_TIMESTAMP : 16,
    SQL_TYPE_ID.SQL_DATETIME : 16,
    SQL_TYPE_ID.SQL_INTERVAL_YEAR : 34,
    SQL_TYPE_ID.SQL_INTERVAL_MONTH : 34,
    SQL_TYPE_ID.SQL_INTERVAL_DAY : 34,
    SQL_TYPE_ID.SQL_INTERVAL_HOUR : 34,
    SQL_TYPE_ID.SQL_INTERVAL_MINUTE : 34,
    SQL_TYPE_ID.SQL_INTERVAL_SECOND : 34,
    SQL_TYPE_ID.SQL_INTERVAL_YEAR_TO_MONTH : 34,
    SQL_TYPE_ID.SQL_INTERVAL_DAY_TO_HOUR : 34,
    SQL_TYPE_ID.SQL_INTERVAL_DAY_TO_MINUTE : 34,
    SQL_TYPE_ID.SQL_INTERVAL_DAY_TO_SECOND : 34,
    SQL_TYPE_ID.SQL_INTERVAL_HOUR_TO_MINUTE : 34,
    SQL_TYPE_ID.SQL_INTERVAL_HOUR_TO_SECOND : 34,
    SQL_TYPE_ID.SQL_INTERVAL_MINUTE_TO_SECOND : 34,
    SQL_TYPE_ID.SQL_INTERVAL : 34,
    SQL_TYPE_ID.SQL_GUID : 16,
];

// http://msdn.microsoft.com/en-us/library/ms713974(v=vs.85).aspx
//Does not include SQL_DECIMAL/SQL_NUMERIC
enum SQLSMALLINT[SQL_TYPE_ID] displaySizeMap = [
    SQL_TYPE_ID.SQL_CHAR : SQL_NO_TOTAL,
    SQL_TYPE_ID.SQL_VARCHAR : SQL_NO_TOTAL,
    SQL_TYPE_ID.SQL_LONGVARCHAR : SQL_NO_TOTAL,
    SQL_TYPE_ID.SQL_WCHAR : SQL_NO_TOTAL,
    SQL_TYPE_ID.SQL_WVARCHAR : SQL_NO_TOTAL,
    SQL_TYPE_ID.SQL_WLONGVARCHAR : SQL_NO_TOTAL,
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
    SQL_TYPE_ID.SQL_DATE : 10,
    SQL_TYPE_ID.SQL_TIME : 11,
    SQL_TYPE_ID.SQL_TIMESTAMP : 22,
    SQL_TYPE_ID.SQL_DATETIME : 22,
    //Told by Dain to pick an arbitary large number for intervals
    SQL_TYPE_ID.SQL_INTERVAL_YEAR : 30,
    SQL_TYPE_ID.SQL_INTERVAL_MONTH : 30,
    SQL_TYPE_ID.SQL_INTERVAL_DAY : 30,
    SQL_TYPE_ID.SQL_INTERVAL_HOUR : 30,
    SQL_TYPE_ID.SQL_INTERVAL_MINUTE : 30,
    SQL_TYPE_ID.SQL_INTERVAL_SECOND : 30,
    SQL_TYPE_ID.SQL_INTERVAL_YEAR_TO_MONTH : 30,
    SQL_TYPE_ID.SQL_INTERVAL_DAY_TO_HOUR : 30,
    SQL_TYPE_ID.SQL_INTERVAL_DAY_TO_MINUTE : 30,
    SQL_TYPE_ID.SQL_INTERVAL_DAY_TO_SECOND : 30,
    SQL_TYPE_ID.SQL_INTERVAL_HOUR_TO_MINUTE : 30,
    SQL_TYPE_ID.SQL_INTERVAL_HOUR_TO_SECOND : 30,
    SQL_TYPE_ID.SQL_INTERVAL_MINUTE_TO_SECOND : 30,
    SQL_TYPE_ID.SQL_GUID : 36,
];

bool isNumericalTypeId(SQL_TYPE_ID typeId) {
    with (SQL_TYPE_ID) {
        switch (typeId) {
            case SQL_BIT:
            case SQL_TINYINT:
            case SQL_SMALLINT:
            case SQL_INTEGER:
            case SQL_BIGINT:
            case SQL_REAL:
            case SQL_FLOAT:
            case SQL_DOUBLE:
                return true;
            default:
                return false;
        }
    }
}

bool isStringTypeId(SQL_TYPE_ID typeId) {
    with (SQL_TYPE_ID) {
        switch (typeId) {
            case SQL_CHAR:
            case SQL_VARCHAR:
            case SQL_LONGVARCHAR:
            case SQL_WCHAR:
            case SQL_WVARCHAR:
            case SQL_WLONGVARCHAR:
                return true;
            default:
                return false;
        }
    }
}

bool isInterval(SQL_TYPE_ID typeId) {
    with (SQL_TYPE_ID) {
        switch (typeId) {
            case SQL_INTERVAL_YEAR:
            case SQL_INTERVAL_MONTH:
            case SQL_INTERVAL_DAY:
            case SQL_INTERVAL_HOUR:
            case SQL_INTERVAL_MINUTE:
            case SQL_INTERVAL_SECOND:
            case SQL_INTERVAL_YEAR_TO_MONTH:
            case SQL_INTERVAL_DAY_TO_HOUR:
            case SQL_INTERVAL_DAY_TO_MINUTE:
            case SQL_INTERVAL_DAY_TO_SECOND:
            case SQL_INTERVAL_HOUR_TO_MINUTE:
            case SQL_INTERVAL_HOUR_TO_SECOND:
            case SQL_INTERVAL_MINUTE_TO_SECOND:
                return true;
            default:
                return false;
        }
    }
}

bool isTimeRelated(SQL_TYPE_ID typeId) {
    with (SQL_TYPE_ID) {
        switch (typeId) {
            case SQL_TYPE_DATE:
            case SQL_TYPE_TIME:
            case SQL_TYPE_TIMESTAMP:
            case SQL_INTERVAL_YEAR:
            case SQL_INTERVAL_MONTH:
            case SQL_INTERVAL_DAY:
            case SQL_INTERVAL_HOUR:
            case SQL_INTERVAL_MINUTE:
            case SQL_INTERVAL_SECOND:
            case SQL_INTERVAL_YEAR_TO_MONTH:
            case SQL_INTERVAL_DAY_TO_HOUR:
            case SQL_INTERVAL_DAY_TO_MINUTE:
            case SQL_INTERVAL_DAY_TO_SECOND:
            case SQL_INTERVAL_HOUR_TO_MINUTE:
            case SQL_INTERVAL_HOUR_TO_SECOND:
            case SQL_INTERVAL_MINUTE_TO_SECOND:
                return true;
            default:
                return false;
        }
    }
}

bool isTimeOrDate(SQL_TYPE_ID typeId) {
    with (SQL_TYPE_ID) {
        switch (typeId) {
            case SQL_TYPE_DATE:
            case SQL_TYPE_TIME:
            case SQL_TYPE_TIMESTAMP:
                return true;
            default:
                return false;
        }
    }
}

SQL_TYPE_ID toVerboseType(SQL_TYPE_ID typeId) {
    with (SQL_TYPE_ID) {
        switch (typeId) {
            case SQL_TYPE_DATE:
            case SQL_TYPE_TIME:
            case SQL_TYPE_TIMESTAMP:
                return SQL_DATETIME;
            case SQL_INTERVAL_YEAR:
            case SQL_INTERVAL_MONTH:
            case SQL_INTERVAL_DAY:
            case SQL_INTERVAL_HOUR:
            case SQL_INTERVAL_MINUTE:
            case SQL_INTERVAL_SECOND:
            case SQL_INTERVAL_YEAR_TO_MONTH:
            case SQL_INTERVAL_DAY_TO_HOUR:
            case SQL_INTERVAL_DAY_TO_MINUTE:
            case SQL_INTERVAL_DAY_TO_SECOND:
            case SQL_INTERVAL_HOUR_TO_MINUTE:
            case SQL_INTERVAL_HOUR_TO_SECOND:
            case SQL_INTERVAL_MINUTE_TO_SECOND:
                return SQL_INTERVAL;
            default:
                return typeId;
        }
    }
}

// http://msdn.microsoft.com/en-us/library/ms711683%28v=vs.85%29.aspx
// (When looking at the reference on the above page and the values
//  from the source listed for column size, this seems to be the
//  appropriate result)
int typeToNumPrecRadix(SQL_TYPE_ID typeId) {
    return isNumericalTypeId(typeId) ? 10 : 0;
}

final class TypeInfoResult(RowT) : OdbcResult {
    this(TList...)(TList vs) {
        result = new RowT(vs);
    }

    override bool empty() const {
        return result is null;
    }

    override inout(RowT) front() inout {
        assert(!empty);
        return result;
    }

    override void popFront() {
        result = null;
    }

    override size_t numberOfColumns() {
        return TypeInfoResultColumns.max;
    }

private:
    RowT result;
}

alias SQL_SIGNED = SQL_FALSE;
alias SQL_UNSIGNED = SQL_TRUE;
enum SQL_HAS_NO_SIGN = null;

/*
 * TODO: Turns out that these should be named after the SQL type, not the Presto type
 *       I believe that this one is named appropriately, should we need other type info
 *       classes, bear that in mind.
 * TODO: The information in this file has not been double-checked for correctness in a
 *       while. It should be reviewed when this file is refactored.
 */
// http://msdn.microsoft.com/en-us/library/ms714632%28v=vs.85%29.aspx
final class VarcharTypeInfoResultRow : OdbcResultRow {
    this(Nullability isNullable) {
        this.isNullable = isNullable;
    }

    override Variant dataAt(int column) {
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
                return Variant(typeToNumPrecRadix(typeId));
            case TypeInfoResultColumns.INTERVAL_PRECISION:
                return Variant(null);
            default:
                assert(false);
        }
    }
private:
    Nullability isNullable;
    enum typeId = SQL_TYPE_ID.SQL_VARCHAR;
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
