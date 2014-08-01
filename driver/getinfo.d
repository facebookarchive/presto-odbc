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
module presto.odbcdriver.getinfo;

import std.array : front, empty, popFront;
import std.conv : text, wtext, to;

import odbc.sqlext;
import odbc.odbcinst;

import presto.odbcdriver.handles : OdbcConnection;
import presto.odbcdriver.util;


///// SQLGetInfo /////

export extern(System)
    SQLRETURN SQLGetInfoW(
        OdbcConnection connectionHandle,
        OdbcInfo infoType,
        SQLPOINTER _infoValue,
        SQLSMALLINT _bufferMaxLengthBytes,
        SQLSMALLINT* _stringLengthBytes) {
    return exceptionBoundary!(() => {
        connectionHandle.errors = [];
        auto stringResult = outputWChar(_infoValue, _bufferMaxLengthBytes, _stringLengthBytes);
        logMessage("SQLGetInfo", infoType);
        with (OdbcInfo) with(connectionHandle) with (session) {
            switch (infoType) {
                case SQL_MAX_DRIVER_CONNECTIONS: //0
                    *cast(SQLUSMALLINT*)(_infoValue) = 1;
                    break;
                case SQL_MAX_CONCURRENT_ACTIVITIES: //1
                    *cast(SQLUSMALLINT*)(_infoValue) = 1;
                    break;
                case SQL_DATA_SOURCE_NAME: //2
                    copyToBuffer(""w, stringResult);
                    break;
                case SQL_DRIVER_NAME: //6
                    copyToBuffer("presto.dll"w, stringResult);
                    break;
                case SQL_DRIVER_VER: //7
                    copyToBuffer("00.01.0000"w, stringResult);
                    break;
                case SQL_FETCH_DIRECTION: //8
                    enum bitmask = 0;
                    *cast(SQLINTEGER*)(_infoValue) = bitmask;
                    break;
                case SQL_ODBC_API_CONFORMANCE: //9
                    //Can probably increase this in the future.
                    *cast(SQLSMALLINT*)(_infoValue) = SQL_OAC_NONE;
                    break;
                case SQL_ODBC_VER: //10
                    copyToBuffer("03.00"w, stringResult);
                    break;
                case SQL_ROW_UPDATES: //12
                    copyToBuffer("N"w, stringResult);
                    break;
                case SQL_ODBC_SAG_CLI_CONFORMANCE: //12
                    *cast(SQLUINTEGER*)(_infoValue) = SQL_OSCC_NOT_COMPLIANT;
                    break;
                case SQL_SEARCH_PATTERN_ESCAPE: //14
                    copyToBuffer("%"w, stringResult);
                    break;
                case SQL_ODBC_SQL_CONFORMANCE: //15
                    *cast(SQLSMALLINT*)(_infoValue) = SQL_OSC_MINIMUM;
                    break;
                case SQL_DATABASE_NAME: //16
                    copyToBuffer(wtext(catalog), stringResult);
                    break;
                case SQL_DBMS_NAME: //17
                    copyToBuffer("Presto"w, stringResult);
                    break;
                case SQL_DBMS_VER: //18
                    copyToBuffer("00.73.0000"w, stringResult);
                    break;
                case SQL_ACCESSIBLE_TABLES: //19
                    copyToBuffer("Y"w, stringResult);
                    break;
                case SQL_CONCAT_NULL_BEHAVIOR: //22
                    *cast(SQLUSMALLINT*)(_infoValue) = SQL_CB_NULL;
                    break;
                case SQL_CURSOR_COMMIT_BEHAVIOR: //23
                    *cast(SQLUSMALLINT*)(_infoValue) = SQL_CB_DELETE;
                    break;
                case SQL_CURSOR_ROLLBACK_BEHAVIOR: //24
                    *cast(SQLUSMALLINT*)(_infoValue) = SQL_CB_DELETE;
                    break;
                case SQL_DATA_SOURCE_READ_ONLY: //25
                    copyToBuffer("Y"w, stringResult);
                    break;
                case SQL_EXPRESSIONS_IN_ORDERBY: //27
                    copyToBuffer("Y"w, stringResult);
                    break;
                case SQL_IDENTIFIER_CASE: //28
                    *cast(SQLUSMALLINT*)(_infoValue) = SQL_IC_LOWER;
                    break;
                case SQL_IDENTIFIER_QUOTE_CHAR: //29
                    copyToBuffer("\""w, stringResult);
                    break;
                case SQL_MAXIMUM_COLUMN_NAME_LENGTH: //30
                case SQL_MAXIMUM_CURSOR_NAME_LENGTH: //31
                case SQL_MAXIMUM_SCHEMA_NAME_LENGTH: //32
                case SQL_MAXIMUM_PROCEDURE_NAME_LENGTH: //33
                case SQL_MAXIMUM_QUALIFIER_NAME_LENGTH: //34
                case SQL_MAXIMUM_TABLE_NAME_LENGTH: //35
                    *cast(SQLUSMALLINT*)(_infoValue) = 0;
                    break;
                case SQL_SCHEMA_TERM: //39
                    copyToBuffer("schema"w, stringResult);
                    break;
                case SQL_CATALOG_NAME_SEPARATOR: //41
                    copyToBuffer("."w, stringResult);
                    break;
                case SQL_CATALOG_TERM: //42
                    copyToBuffer("catalog"w, stringResult);
                    break;
                case SQL_TABLE_TERM: //45
                    copyToBuffer("table"w, stringResult);
                    break;
                case SQL_TRANSACTION_CAPABLE: //46
                    *cast(SQLUSMALLINT*)(_infoValue) = SQL_TC_NONE;
                    break;
                case SQL_CONVERT_FUNCTIONS: //48
                case SQL_STRING_FUNCTIONS: //50
                case SQL_SYSTEM_FUNCTIONS: //51
                    //Supporting these would require a parser to translate ODBC escapes
                    // http://msdn.microsoft.com/en-us/library/ms711838%28v=VS.85%29.aspx
                    *cast(SQLUINTEGER*)(_infoValue) = 0;
                    break;
                case SQL_NUMERIC_FUNCTIONS: //49
                    enum bitmask = 
                        SQL_FN_NUM_ABS      |
                        SQL_FN_NUM_ACOS     |
                        SQL_FN_NUM_ASIN     |
                        SQL_FN_NUM_ATAN     |
                        SQL_FN_NUM_ATAN2    |
                        SQL_FN_NUM_CEILING  |
                        SQL_FN_NUM_COS      |
                        SQL_FN_NUM_EXP      |
                        SQL_FN_NUM_LOG      |
                        SQL_FN_NUM_LOG10    |
                        SQL_FN_NUM_POWER    |
                        SQL_FN_NUM_RAND     |
                        SQL_FN_NUM_ROUND    |
                        SQL_FN_NUM_SIN      |
                        SQL_FN_NUM_SQRT     |
                        SQL_FN_NUM_TAN;
                    *cast(SQLUINTEGER*)(_infoValue) = bitmask;
                    break;
                case SQL_TIMEDATE_FUNCTIONS: //52
                    //Additional support would require a parser to translate ODBC escapes
                    // http://msdn.microsoft.com/en-us/library/ms711838%28v=VS.85%29.aspx
                    *cast(SQLUINTEGER*)(_infoValue) = SQL_FN_TD_EXTRACT;
                    break;
                case SQL_CONVERT_BIGINT: //53
                case SQL_CONVERT_BIT: //55
                case SQL_CONVERT_CHAR: //56
                case SQL_CONVERT_INTEGER: //61
                case SQL_CONVERT_LONGVARCHAR: //62
                case SQL_CONVERT_SMALLINT: //65
                case SQL_CONVERT_TINYINT: //68
                case SQL_CONVERT_VARCHAR: //70
                    enum bitmask =
                        SQL_CVT_BIGINT |
                        SQL_CVT_BIT |
                        SQL_CVT_CHAR |
                        SQL_CVT_INTEGER |
                        SQL_CVT_LONGVARCHAR |
                        SQL_CVT_SMALLINT |
                        SQL_CVT_TINYINT |
                        SQL_CVT_VARCHAR;
                    *cast(SQLUINTEGER*)(_infoValue) = bitmask;
                    break;
                case SQL_CONVERT_BINARY: //54
                case SQL_CONVERT_DATE: //57
                case SQL_CONVERT_DECIMAL: //58
                case SQL_CONVERT_DOUBLE: //59
                case SQL_CONVERT_FLOAT: //60
                case SQL_CONVERT_NUMERIC: //63
                case SQL_CONVERT_REAL: //64
                case SQL_CONVERT_TIME: //66
                case SQL_CONVERT_TIMESTAMP: //67
                case SQL_CONVERT_VARBINARY: //69
                case SQL_CONVERT_LONGVARBINARY: //71
                case SQL_CONVERT_WCHAR: //122
                case SQL_CONVERT_INTERVAL_DAY_TIME: //123
                case SQL_CONVERT_INTERVAL_YEAR_MONTH: //124
                case SQL_CONVERT_WLONGVARCHAR: //125
                case SQL_CONVERT_WVARCHAR: //126
                    *cast(SQLUINTEGER*)(_infoValue) = 0;
                    break;
                case SQL_CORRELATION_NAME: //74
                    *cast(SQLUSMALLINT*)(_infoValue) = SQL_CN_ANY;
                    break;
                case SQL_NON_NULLABLE_COLUMNS: //75
                    *cast(SQLUSMALLINT*)(_infoValue) = SQL_NNC_NON_NULL;
                    break;
                case SQL_DRIVER_ODBC_VER: // 77
                    //Latest version of ODBC is 3.8 (as of 6/19/14)
                    copyToBuffer("03.51"w, stringResult);
                    break;
                case SQL_POS_OPERATIONS: //79
                    *cast(SQLINTEGER*)(_infoValue) = 0;
                    break;
                case SQL_POSITIONED_STATEMENTS: //80
                    *cast(SQLINTEGER*)(_infoValue) = 0;
                    break;
                case SQL_GETDATA_EXTENSIONS: //81
                    *cast(SQLUINTEGER*)(_infoValue) = SQL_GD_ANY_ORDER;
                    break;
                case SQL_STATIC_SENSITIVITY: //83
                    *cast(SQLINTEGER*)(_infoValue) = 0;
                    break;
                case SQL_FILE_USAGE: //84
                    *cast(SQLUSMALLINT*)(_infoValue) = SQL_FILE_CATALOG;
                    break;
                case SQL_ALTER_TABLE: //86
                    *cast(SQLUINTEGER*)(_infoValue) = 0;
                    break;
                case SQL_COLUMN_ALIAS: //87
                    copyToBuffer("N"w, stringResult);
                    break;
                case SQL_GROUP_BY: //88
                    *cast(SQLUSMALLINT*)(_infoValue) = SQL_GB_GROUP_BY_CONTAINS_SELECT;
                    break;
                case SQL_KEYWORDS: //89
                    copyToBuffer("EXPLAIN,CATALOGS,COLUMNS,FUNCTIONS,PARTITIONS,SCHEMAS,TABLES"w, stringResult);
                    break;
                case SQL_ORDER_BY_COLUMNS_IN_SELECT: //90
                    copyToBuffer("N"w, stringResult);
                    break;
                case SQL_SCHEMA_USAGE: //91
                    auto bitmask =
                        SQL_SU_DML_STATEMENTS |
                        SQL_SU_PROCEDURE_INVOCATION |
                        SQL_SU_TABLE_DEFINITION |
                        SQL_SU_INDEX_DEFINITION |
                        SQL_SU_PRIVILEGE_DEFINITION;
                    *cast(SQLUINTEGER*)(_infoValue) = bitmask;
                    break;
                case SQL_CATALOG_USAGE: //92
                    auto bitmask =
                        SQL_CU_DML_STATEMENTS |
                        SQL_CU_PROCEDURE_INVOCATION |
                        SQL_CU_TABLE_DEFINITION |
                        SQL_CU_INDEX_DEFINITION |
                        SQL_CU_PRIVILEGE_DEFINITION;
                    *cast(SQLUINTEGER*)(_infoValue) = bitmask;
                    break;
                case SQL_QUOTED_IDENTIFIER_CASE: //93
                    *cast(SQLUSMALLINT*)(_infoValue) = SQL_IC_SENSITIVE;
                    break;
                case SQL_SPECIAL_CHARACTERS: //94
                    copyToBuffer(""w, stringResult);
                    break;
                case SQL_SUBQUERIES: //95
                    *cast(SQLUINTEGER*)(_infoValue) = SQL_SQ_IN;
                    break;
                case SQL_UNION: //96
                    *cast(SQLUINTEGER*)(_infoValue) = SQL_U_UNION | SQL_U_UNION_ALL;
                    break;
                case SQL_MAXIMUM_COLUMNS_IN_GROUP_BY: //97
                case SQL_MAXIMUM_COLUMNS_IN_INDEX: //98
                case SQL_MAXIMUM_COLUMNS_IN_ORDER_BY: //99
                case SQL_MAXIMUM_COLUMNS_IN_SELECT: //100
                case SQL_MAXIMUM_COLUMNS_IN_TABLE: //101
                case SQL_MAXIMUM_INDEX_SIZE: //102
                case SQL_MAXIMUM_TABLES_IN_SELECT: //106
                case SQL_MAXIMUM_USER_NAME_LENGTH: //107
                    *cast(SQLUSMALLINT*)(_infoValue) = 0;
                    break;
                case SQL_MAXIMUM_ROW_SIZE_INCLUDES_LONG: //103
                    copyToBuffer("Y"w, stringResult);
                    break;
                case SQL_MAXIMUM_ROW_SIZE: //104
                case SQL_MAXIMUM_STATEMENT_LENGTH: //105
                case SQL_MAXIMUM_CHAR_LITERAL_LENGTH: //108
                    *cast(SQLUINTEGER*)(_infoValue) = 0;
                    break;
                case SQL_TIMEDATE_ADD_INTERVALS: //109
                case SQL_TIMEDATE_DIFF_INTERVALS: //110
                    enum bitmask =
                        SQL_FN_TSI_SECOND |
                        SQL_FN_TSI_MINUTE |
                        SQL_FN_TSI_HOUR |
                        SQL_FN_TSI_DAY |
                        SQL_FN_TSI_MONTH |
                        SQL_FN_TSI_YEAR;
                    *cast(SQLUINTEGER*)(_infoValue) = bitmask;
                    break;
                case SQL_NEED_LONG_DATA_LEN: //111
                    copyToBuffer("N"w, stringResult);
                    break;
                case SQL_MAX_BINARY_LITERAL_LEN: //112
                    *cast(SQLUINTEGER*)(_infoValue) = 0;
                    break;
                case SQL_LIKE_ESCAPE_CLAUSE: //113
                    copyToBuffer("Y"w, stringResult);
                    break;
                case SQL_CATALOG_LOCATION: //114
                    *cast(SQLUSMALLINT*)(_infoValue) = SQL_CL_START;
                    break;
                case SQL_OUTER_JOIN_CAPABILITIES: //115
                    enum bitmask =
                        SQL_OJ_INNER |
                        SQL_OJ_LEFT |
                        SQL_OJ_RIGHT |
                        SQL_OJ_NESTED |
                        SQL_OJ_NOT_ORDERED |
                        SQL_OJ_ALL_COMPARISON_OPS;
                    *cast(SQLUINTEGER*)(_infoValue) = bitmask;
                    break;
                case SQL_ACTIVE_ENVIRONMENTS: //116
                    *cast(SQLUSMALLINT*)(_infoValue) = 0;
                    break;
                case SQL_ALTER_DOMAIN: //117
                    *cast(SQLUINTEGER*)(_infoValue) = 0;
                    break;
                case SQL_SQL_CONFORMANCE: //118
                    *cast(SQLUINTEGER*)(_infoValue) = 0;
                    break;
                case SQL_DATETIME_LITERALS: //119
                    //Supporting these would require a parser to translate ODBC escapes
                    // http://msdn.microsoft.com/en-us/library/ms711838%28v=VS.85%29.aspx
                    *cast(SQLUINTEGER*)(_infoValue) = 0;
                    break;
                case SQL_BATCH_SUPPORT: //121
                    *cast(SQLUINTEGER*)(_infoValue) = 0;
                    break;
                case SQL_CREATE_ASSERTION: //127
                case SQL_CREATE_CHARACTER_SET: //128
                case SQL_CREATE_COLLATION: //129
                case SQL_CREATE_DOMAIN: //130
                case SQL_CREATE_SCHEMA: //131
                case SQL_CREATE_TABLE: //132
                case SQL_CREATE_VIEW: //134
                case SQL_DROP_TABLE: //141
                case SQL_DROP_VIEW: //143
                case SQL_CREATE_TRANSLATION: //133
                    *cast(SQLUINTEGER*)(_infoValue) = 0;
                    break;
                case SQL_DROP_ASSERTION: //136
                case SQL_DROP_CHARACTER_SET: //137
                case SQL_DROP_COLLATION: //138
                case SQL_DROP_DOMAIN: //139
                case SQL_DROP_SCHEMA: //140
                case SQL_DROP_TRANSLATION: //142
                    *cast(SQLUINTEGER*)(_infoValue) = 0;
                    break;
                case SQL_INDEX_KEYWORDS: //148
                    *cast(SQLUINTEGER*)(_infoValue) = SQL_IK_ASC | SQL_IK_DESC;
                    break;
                case SQL_ODBC_INTERFACE_CONFORMANCE: //152
                    *cast(SQLUINTEGER*)(_infoValue) = SQL_OIC_CORE;
                    break;
                case SQL_PARAM_ARRAY_ROW_COUNTS: //153
                    *cast(SQLUINTEGER*)(_infoValue) = SQL_PARC_NO_BATCH;
                    break;
                case SQL_PARAM_ARRAY_SELECTS: //154
                    *cast(SQLUINTEGER*)(_infoValue) = SQL_PARC_NO_BATCH;
                    break;
                case SQL_SQL92_DATETIME_FUNCTIONS: //155
                    //Supporting these would require a parser to translate ODBC escapes
                    // http://msdn.microsoft.com/en-us/library/ms711838%28v=VS.85%29.aspx
                    *cast(SQLUINTEGER*)(_infoValue) = 0;
                    break;
                case SQL_SQL92_FOREIGN_KEY_DELETE_RULE: //156
                case SQL_SQL92_FOREIGN_KEY_UPDATE_RULE: //157
                case SQL_SQL92_GRANT: //158
                case SQL_SQL92_REVOKE: //162
                    *cast(SQLUINTEGER*)(_infoValue) = 0;
                    break;
                case SQL_SQL92_NUMERIC_VALUE_FUNCTIONS: //159
                    *cast(SQLUINTEGER*)(_infoValue) = 0;
                    break;
                case SQL_SQL92_STRING_FUNCTIONS: //164
                    //Supporting these would require a parser to translate ODBC escapes
                    // http://msdn.microsoft.com/en-us/library/ms711838%28v=VS.85%29.aspx
                    *cast(SQLUINTEGER*)(_infoValue) = 0;
                    break;
                case SQL_STANDARD_CLI_CONFORMANCE: //166
                    *cast(SQLUINTEGER*)(_infoValue) = 0;
                    break;
                case SQL_AGGREGATE_FUNCTIONS: //169
                    enum bitmask =
                        SQL_AF_AVG |
                        SQL_AF_COUNT |
                        SQL_AF_MAX |
                        SQL_AF_MIN |
                        SQL_AF_DISTINCT |
                        SQL_AF_SUM;
                    *cast(SQLUINTEGER*)(_infoValue) = bitmask;
                    break;
                case SQL_DDL_INDEX: //170
                    *cast(SQLUINTEGER*)(_infoValue) = 0;
                    break;
                case SQL_INSERT_STATEMENT: //172
                    *cast(SQLUINTEGER*)(_infoValue) = 0;
                    break;
                case SQL_DESCRIBE_PARAMETER: //10002
                    copyToBuffer("N"w, stringResult);
                    break;
                case SQL_CATALOG_NAME: //10003
                    copyToBuffer("Y"w, stringResult);
                    break;
                case SQL_COLLATION_SEQ: //10004
                    copyToBuffer(""w, stringResult);
                    break;
                case SQL_MAXIMUM_IDENTIFIER_LENGTH: //10005
                    *cast(SQLUSMALLINT*)(_infoValue) = 128;
                    break;
                case SQL_ASYNC_MODE: // 10021
                    *cast(SQLUINTEGER*)(_infoValue) = SQL_AM_NONE;
                    break;
                case SQL_MAX_ASYNC_CONCURRENT_STATEMENTS: // 10022
                    *cast(SQLUINTEGER*)(_infoValue) = 0;
                    break;
                case SQL_DRIVER_HDBC: //3
                case SQL_DRIVER_HENV: //4
                case SQL_DRIVER_HSTMT: //5
                case SQL_DRIVER_HLIB: //76
                case SQL_DRIVER_HDESC: //135
                    dllEnforce(false, "Only the Driver Manager implements this");
                    break;
                default:
                case SQL_SERVER_NAME: //13
                case SQL_ACCESSIBLE_PROCEDURES: //20
                case SQL_PROCEDURES: //21
                case SQL_DEFAULT_TXN_ISOLATION: //26
                case SQL_MULT_RESULT_SETS: //36
                case SQL_MULTIPLE_ACTIVE_TXN: //37
                case SQL_OUTER_JOINS: //38
                case SQL_PROCEDURE_TERM: //40
                case SQL_SCROLL_CONCURRENCY: //43
                case SQL_SCROLL_OPTIONS: //44
                case SQL_USER_NAME: //47
                case SQL_TRANSACTION_ISOLATION_OPTION: //72
                case SQL_INTEGRITY: //73
                case SQL_LOCK_TYPES: //78
                case SQL_BOOKMARK_PERSISTENCE: //82
                case SQL_NULL_COLLATION: //85
                case SQL_BATCH_ROW_COUNT: //120
                case SQL_DYNAMIC_CURSOR_ATTRIBUTES1: //144
                case SQL_DYNAMIC_CURSOR_ATTRIBUTES2: //145
                case SQL_FORWARD_ONLY_CURSOR_ATTRIBUTES1: //146
                case SQL_FORWARD_ONLY_CURSOR_ATTRIBUTES2: //147
                case SQL_KEYSET_CURSOR_ATTRIBUTES1: //150
                case SQL_KEYSET_CURSOR_ATTRIBUTES2: //151
                case SQL_STATIC_CURSOR_ATTRIBUTES1: //167
                case SQL_STATIC_CURSOR_ATTRIBUTES2: //168
                case SQL_INFO_SCHEMA_VIEWS: //149
                case SQL_SQL92_PREDICATES: //160
                case SQL_SQL92_RELATIONAL_JOIN_OPERATORS: //161
                case SQL_SQL92_ROW_VALUE_CONSTRUCTOR: //163
                case SQL_SQL92_VALUE_EXPRESSIONS: //165
                case SQL_DM_VER: //171
                case SQL_XOPEN_CLI_YEAR: //10000
                case SQL_CURSOR_SENSITIVITY: //10001
                    throw new OdbcException(connectionHandle, StatusCode.OPTIONAL_FEATURE,
                            "Unsupported info type"w ~ wtext(infoType));
            } //switch
        }
        return SQL_SUCCESS;
    }());
}
