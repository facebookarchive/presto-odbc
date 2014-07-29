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
module presto.odbcdriver.columnresults;

import std.array : front, empty, popFront;
import std.conv : text, to;
import std.variant : Variant;

import odbc.sqlext;
import odbc.odbcinst;

import presto.client.util : asBool;

import presto.odbcdriver.handles : OdbcConnection;
import presto.odbcdriver.bindings : OdbcResult, OdbcResultRow;
import presto.odbcdriver.typeinfo : columnSizeMap, decimalDigitsMap, typeToNumPrecRadix;
import presto.odbcdriver.util;

// http://msdn.microsoft.com/en-us/library/ms711683%28v=vs.85%29.aspx

ColumnsResult listColumnsInTable(OdbcConnection connectionHandle, string tableName) {
    with (connectionHandle) with (session) {
        auto client = connectionHandle.runQuery("SHOW COLUMNS FROM " ~ tableName.escapeSqlIdentifier);
        auto result = makeWithoutGC!ColumnsResult();
        foreach (resultBatch; client) {
            foreach (i, row; resultBatch.data.array) {
                auto columnName = row.array[0].str;
                auto type = row.array[1].str;
                auto isNullable = asBool(row.array[2]) ? Nullability.SQL_NULLABLE : Nullability.SQL_NO_NULLS;
                auto partitionKey = asBool(row.array[3]);

                auto columnsResult = prestoTypeToColumnsResult(type, catalog, schema, text(tableName), columnName, isNullable, i + 1);

                if (columnsResult) {
                    result.addColumn(columnsResult);
                }
                logMessage("listColumnsInTable found column: ", columnName, type, isNullable, i + 1);
            }
        }
        return result;
    }
}

OdbcResultRow prestoTypeToColumnsResult(
    string prestoType, string catalogName, string schemaName,
    string tableName, string columnName, Nullability isNullable, size_t ordinalPosition) {
    dllEnforce(ordinalPosition != 0, "Columns are 1-indexed");
    switch (prestoType) {
        case "varchar":
            return makeWithoutGC!VarcharColumnsResultRow(catalogName, schemaName, tableName, columnName, isNullable, ordinalPosition);
        case "bigint":
            return makeWithoutGC!BigIntColumnsResultRow(catalogName, schemaName, tableName, columnName, isNullable, ordinalPosition);
        case "double":
            return makeWithoutGC!DoubleColumnsResultRow(catalogName, schemaName, tableName, columnName, isNullable, ordinalPosition);
        case "date":
            return makeWithoutGC!DateColumnsResultRow(catalogName, schemaName, tableName, columnName, isNullable, ordinalPosition);
        case "time":
            return makeWithoutGC!TimeColumnsResultRow(catalogName, schemaName, tableName, columnName, isNullable, ordinalPosition);
        case "time with time zone":
            return makeWithoutGC!VarcharColumnsResultRow(catalogName, schemaName, tableName, columnName, isNullable, ordinalPosition);
        case "timestamp":
            return makeWithoutGC!TimestampColumnsResultRow(catalogName, schemaName, tableName, columnName, isNullable, ordinalPosition);
        case "timestamp with time zone":
            return makeWithoutGC!VarcharColumnsResultRow(catalogName, schemaName, tableName, columnName, isNullable, ordinalPosition);
        case "interval year to month":
            return makeWithoutGC!YearToMonthColumnsResultRow(catalogName, schemaName, tableName, columnName, isNullable, ordinalPosition);
        case "interval day to second":
            return makeWithoutGC!DayToSecondColumnsResultRow(catalogName, schemaName, tableName, columnName, isNullable, ordinalPosition);
        default:
            logMessage("Unexpected type in prestoTypeToColumnsResult: " ~ prestoType);
            return null;
    }
}

SQL_TYPE_ID prestoTypeToSqlTypeId(string prestoType) {
    with (SQL_TYPE_ID) {
        switch (prestoType) {
            case "varchar":
                return SQL_VARCHAR;
            case "bigint":
                return SQL_BIGINT;
            case "double":
                return SQL_DOUBLE;
            case "date":
                return SQL_DATE;
            case "time":
                return SQL_TIME;
            case "time with time zone":
                return SQL_VARCHAR;
            case "timestamp":
                return SQL_TIMESTAMP;
            case "timestamp with time zone":
                return SQL_VARCHAR;
            case "interval year to month":
                return SQL_INTERVAL_YEAR_TO_MONTH;
            case "interval day to second":
                return SQL_INTERVAL_DAY_TO_SECOND;
            default:
                logMessage("Unexpected type in prestoTypeToSqlTypeId: " ~ prestoType);
                return SQL_UNKNOWN_TYPE;
        }
    }
}

final class ColumnsResult : OdbcResult {
    void addColumn(OdbcResultRow column) {
        results_ ~= column;
    }

    auto results() const {
        return results_;
    }

    override bool empty() const {
        return results_.empty;
    }

    override inout(OdbcResultRow) front() inout {
        assert(!empty);
        return results_.front;
    }

    override void popFront() {
        results_.popFront();
    }

    override size_t numberOfColumns() {
        return ColumnsResultColumns.max;
    }

private:
    OdbcResultRow[] results_;
}

private class ColumnsResultRow : OdbcResultRow {
    this(string catalogName, string schemaName, string tableName,
         string columnName, Nullability isNullable, size_t ordinalPosition) {
        this.catalogName = catalogName;
        this.schemaName = schemaName;
        this.tableName = tableName;
        this.columnName = columnName;
        this.isNullable = isNullable;
        this.ordinalPosition = to!int(ordinalPosition);
    }

    abstract override Variant dataAt(int column);

    final Variant dataAt(ColumnsResultColumns column) {
        return dataAt(cast(int) column);
    }

protected:
    string catalogName;
    string schemaName;
    string tableName;
    string columnName;
    Nullability isNullable;
    int ordinalPosition;
}

alias BigIntColumnsResultRow = BigIntBasedColumnsResultRow!(SQL_TYPE_ID.SQL_BIGINT);
alias IntegerColumnsResultRow = BigIntBasedColumnsResultRow!(SQL_TYPE_ID.SQL_INTEGER);
alias SmallIntColumnsResultRow = BigIntBasedColumnsResultRow!(SQL_TYPE_ID.SQL_SMALLINT);
alias TinyIntColumnsResultRow = BigIntBasedColumnsResultRow!(SQL_TYPE_ID.SQL_TINYINT);

final class BigIntBasedColumnsResultRow(SQL_TYPE_ID typeId) : ColumnsResultRow {
    this(string catalogName, string schemaName, string tableName,
         string columnName, Nullability isNullable, size_t ordinalPosition) {
        super(catalogName, schemaName, tableName, columnName, isNullable, ordinalPosition);
    }

    override Variant dataAt(int column) {
        with (ColumnsResultColumns) {
            switch (column) {
                case TABLE_CAT:
                    return Variant(catalogName);
                case TABLE_SCHEM:
                    return Variant(schemaName);
                case TABLE_NAME:
                    return Variant(tableName);
                case COLUMN_NAME:
                    return Variant(columnName);
                case DATA_TYPE:
                case SQL_DATA_TYPE:
                    return Variant(typeId);
                case TYPE_NAME:
                    return Variant("BIGINT");
                case COLUMN_SIZE:
                case BUFFER_LENGTH:
                    return Variant(columnSizeMap[typeId]);
                case DECIMAL_DIGITS:
                    return Variant(decimalDigitsMap[typeId]);
                case NUM_PREC_RADIX:
                    return Variant(typeToNumPrecRadix(typeId));
                case NULLABLE:
                    return Variant(isNullable);
                case REMARKS:
                    return Variant("No remarks");
                case COLUMN_DEF:
                    return Variant("0");
                case SQL_DATETIME_SUB:
                    return Variant(null);
                case CHAR_OCTET_LENGTH:
                    return Variant(null);
                case ORDINAL_POSITION:
                    return Variant(ordinalPosition);
                case IS_NULLABLE:
                    return Variant(isNullable);
                default:
                    dllEnforce(false, "Non-existent column " ~ text(cast(ColumnsResultColumns) column));
                    assert(false, "Silence compiler errors about not returning");
            }
        }
    }
private:
}

alias DoubleColumnsResultRow = DoubleBasedColumnsResultRow!(SQL_TYPE_ID.SQL_DOUBLE);
alias FloatColumnsResultRow = DoubleBasedColumnsResultRow!(SQL_TYPE_ID.SQL_FLOAT);
alias RealColumnsResultRow = DoubleBasedColumnsResultRow!(SQL_TYPE_ID.SQL_REAL);

final class DoubleBasedColumnsResultRow(SQL_TYPE_ID typeId) : ColumnsResultRow {
    this(string catalogName, string schemaName, string tableName,
         string columnName, Nullability isNullable, size_t ordinalPosition) {
        super(catalogName, schemaName, tableName, columnName, isNullable, ordinalPosition);
    }

    override Variant dataAt(int column) {
        with (ColumnsResultColumns) {
            switch (column) {
                case TABLE_CAT:
                    return Variant(catalogName);
                case TABLE_SCHEM:
                    return Variant(schemaName);
                case TABLE_NAME:
                    return Variant(tableName);
                case COLUMN_NAME:
                    return Variant(columnName);
                case DATA_TYPE:
                case SQL_DATA_TYPE:
                    return Variant(typeId);
                case TYPE_NAME:
                    return Variant("DOUBLE");
                case COLUMN_SIZE:
                case BUFFER_LENGTH:
                    return Variant(columnSizeMap[typeId]);
                case DECIMAL_DIGITS:
                    return Variant(null);
                case NUM_PREC_RADIX:
                    return Variant(typeToNumPrecRadix(typeId));
                case NULLABLE:
                    return Variant(isNullable);
                case REMARKS:
                    return Variant("No remarks");
                case COLUMN_DEF:
                    return Variant("0");
                case SQL_DATETIME_SUB:
                    return Variant(null);
                case CHAR_OCTET_LENGTH:
                    return Variant(null);
                case ORDINAL_POSITION:
                    return Variant(ordinalPosition);
                case IS_NULLABLE:
                    return Variant(isNullable);
                default:
                    dllEnforce(false, "Non-existent column " ~ text(cast(ColumnsResultColumns) column));
                    assert(false, "Silence compiler errors about not returning");
            }
        }
    }
private:
}


final class VarcharColumnsResultRow : ColumnsResultRow {
    this(string catalogName, string schemaName, string tableName,
         string columnName, Nullability isNullable, size_t ordinalPosition) {
        super(catalogName, schemaName, tableName, columnName, isNullable, ordinalPosition);
    }

    override Variant dataAt(int column) {
        with (ColumnsResultColumns) {
            switch (column) {
                case TABLE_CAT:
                    return Variant(catalogName);
                case TABLE_SCHEM:
                    return Variant(schemaName);
                case TABLE_NAME:
                    return Variant(tableName);
                case COLUMN_NAME:
                    return Variant(columnName);
                case DATA_TYPE:
                case SQL_DATA_TYPE:
                    return Variant(typeId);
                case TYPE_NAME:
                    return Variant("VARCHAR");
                case COLUMN_SIZE:
                case BUFFER_LENGTH:
                    return Variant(columnSizeMap[typeId]);
                case DECIMAL_DIGITS:
                    return Variant(null);
                case NUM_PREC_RADIX:
                    return Variant(null);
                case NULLABLE:
                    return Variant(isNullable);
                case REMARKS:
                    return Variant("No remarks");
                case COLUMN_DEF:
                    return Variant("''");
                case SQL_DATETIME_SUB:
                    return Variant(null);
                case CHAR_OCTET_LENGTH:
                    return Variant(SQL_NO_TOTAL); //not sure if this value works here
                case ORDINAL_POSITION:
                    return Variant(ordinalPosition);
                case IS_NULLABLE:
                    return Variant(isNullable);
                default:
                    dllEnforce(false, "Non-existent column " ~ text(cast(ColumnsResultColumns) column));
                    assert(false, "Silence compiler errors about not returning");
            }
        }
    }
private:
    enum typeId = SQL_TYPE_ID.SQL_VARCHAR;
}

alias DateColumnsResultRow = DateTimeBasedColumnsResultRow!(SQL_TYPE_ID.SQL_DATE, "DATE");
alias TimeColumnsResultRow = DateTimeBasedColumnsResultRow!(SQL_TYPE_ID.SQL_TIME, "TIME");
alias TimestampColumnsResultRow = DateTimeBasedColumnsResultRow!(SQL_TYPE_ID.SQL_TIMESTAMP, "TIMESTAMP");

final class DateTimeBasedColumnsResultRow(SQL_TYPE_ID typeId, string typeName) : ColumnsResultRow {
    this(string catalogName, string schemaName, string tableName,
         string columnName, Nullability isNullable, size_t ordinalPosition) {
        super(catalogName, schemaName, tableName, columnName, isNullable, ordinalPosition);
    }

    override Variant dataAt(int column) {
        with (ColumnsResultColumns) {
            switch (column) {
                case TABLE_CAT:
                    return Variant(catalogName);
                case TABLE_SCHEM:
                    return Variant(schemaName);
                case TABLE_NAME:
                    return Variant(tableName);
                case COLUMN_NAME:
                    return Variant(columnName);
                case DATA_TYPE:
                case SQL_DATA_TYPE:
                    return Variant(typeId);
                case TYPE_NAME:
                    return Variant(typeName);
                case COLUMN_SIZE:
                case BUFFER_LENGTH:
                    return Variant(columnSizeMap[typeId]);
                case DECIMAL_DIGITS:
                    return Variant(null);
                case NUM_PREC_RADIX:
                    return Variant(null);
                case NULLABLE:
                    return Variant(isNullable);
                case REMARKS:
                    return Variant("No remarks");
                case COLUMN_DEF:
                    return Variant(typeName ~ " ''");
                case SQL_DATETIME_SUB:
                    return Variant(dateTimeCodeMap[typeId]);
                case CHAR_OCTET_LENGTH:
                    return Variant(null);
                case ORDINAL_POSITION:
                    return Variant(ordinalPosition);
                case IS_NULLABLE:
                    return Variant(isNullable);
                default:
                    dllEnforce(false, "Non-existent column " ~ text(cast(ColumnsResultColumns) column));
                    assert(false, "Silence compiler errors about not returning");
            }
        }
    }
private:
}

alias YearToMonthColumnsResultRow = IntervalBasedColumnsResultRow!(SQL_TYPE_ID.SQL_INTERVAL_YEAR_TO_MONTH, "month");
alias DayToSecondColumnsResultRow = IntervalBasedColumnsResultRow!(SQL_TYPE_ID.SQL_INTERVAL_DAY_TO_SECOND, "second");

final class IntervalBasedColumnsResultRow(SQL_TYPE_ID typeId, string typeName) : ColumnsResultRow {
    this(string catalogName, string schemaName, string tableName,
         string columnName, Nullability isNullable, size_t ordinalPosition) {
        super(catalogName, schemaName, tableName, columnName, isNullable, ordinalPosition);
    }

    override Variant dataAt(int column) {
        with (ColumnsResultColumns) {
            switch (column) {
                case TABLE_CAT:
                    return Variant(catalogName);
                case TABLE_SCHEM:
                    return Variant(schemaName);
                case TABLE_NAME:
                    return Variant(tableName);
                case COLUMN_NAME:
                    return Variant(columnName);
                case DATA_TYPE:
                case SQL_DATA_TYPE:
                    return Variant(typeId);
                case TYPE_NAME:
                    return Variant(typeName);
                case COLUMN_SIZE:
                case BUFFER_LENGTH:
                    return Variant(columnSizeMap[typeId]);
                case DECIMAL_DIGITS:
                    return Variant(null);
                case NUM_PREC_RADIX:
                    return Variant(null);
                case NULLABLE:
                    return Variant(isNullable);
                case REMARKS:
                    return Variant("No remarks");
                case COLUMN_DEF:
                    return Variant("interval '' " ~ typeName);
                case SQL_DATETIME_SUB:
                    return Variant(intervalCodeMap[typeId]);
                case CHAR_OCTET_LENGTH:
                    return Variant(null);
                case ORDINAL_POSITION:
                    return Variant(ordinalPosition);
                case IS_NULLABLE:
                    return Variant(isNullable);
                default:
                    dllEnforce(false, "Non-existent column " ~ text(cast(ColumnsResultColumns) column));
                    assert(false, "Silence compiler errors about not returning");
            }
        }
    }
private:
}

enum ColumnsResultColumns {
    TABLE_CAT = 1,
    TABLE_SCHEM,
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    TYPE_NAME,
    COLUMN_SIZE,
    BUFFER_LENGTH, //How many bytes a BindCol buffer must have to accept this
    DECIMAL_DIGITS,
    NUM_PREC_RADIX,
    NULLABLE,
    REMARKS,
    COLUMN_DEF,
    SQL_DATA_TYPE,
    SQL_DATETIME_SUB,
    CHAR_OCTET_LENGTH,
    ORDINAL_POSITION, //Which # column in the table this is
    IS_NULLABLE
}
