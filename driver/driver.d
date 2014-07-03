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

import core.runtime;

import std.array : front, popFront, empty;
import std.algorithm;
import std.stdio : writeln;
import std.conv : to;

import std.c.stdio;
import std.c.stdlib;
import std.c.string;
import std.c.windows.windows;

import sqlext;
import odbcinst;

import util : logMessage, copyToBuffer, makeWithoutGC, dllEnforce, exceptionBoundary, strlen, toDString;
import util : outputWChar, wcharsToBytes, runQuery, convertPtrBytesToWChars;
import bindings;
import prestoresults;
import columnresults;

//////  DLL entry point for global initializations/finalizations if any

version(unittest) {
  void main() {
    writeln("Tests completed.");
  }
} else {
  extern(Windows) BOOL DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved)
  {
    if (fdwReason == DLL_PROCESS_ATTACH) {        // DLL is being loaded
      Runtime.initialize();
      import core.memory;
      GC.disable();
      logMessage("ODBCDRV0 loaded by application or driver manager");
    } else if (fdwReason == DLL_PROCESS_DETACH) {   // DLL is being unloaded
      Runtime.terminate();
    }

    return TRUE;
  }
}

extern(System):


///// SQLDriverConnect /////

//Note: If making changes here, also look at SQLBrowseConnect
SQLRETURN SQLDriverConnectW(
    SQLHDBC hdbc,
    SQLHWND hwnd,
    in SQLWCHAR* _connStrIn,
    SQLSMALLINT _connStrInChars,
    SQLWCHAR* _connStrOut,
    SQLSMALLINT _connStrOutMaxChars,
    SQLSMALLINT* _connStrOutChars,
    SQLUSMALLINT driverCompletion) {
  return exceptionBoundary!(() => {
    auto connStr = toDString(_connStrIn, _connStrInChars);
    auto connStrOut = outputWChar(_connStrOut, _connStrOutMaxChars * wchar.sizeof, _connStrOutChars);
    scope (exit) convertPtrBytesToWChars(_connStrOutChars);
    logMessage("SQLDriverConnect", connStr, driverCompletion);

    if (connStr == null) {
      return SQL_SUCCESS;
    }

    //Copy input string to output string
    if (connStrOut) {
      copyToBuffer(connStr, connStrOut);
    }

    return SQL_SUCCESS;
  }());
}

///// SQLBrowseConnect /////

//Note: If making changes here, also look at SQLDriverConnect
SQLRETURN SQLBrowseConnectW(
    SQLHDBC hdbc,
    in SQLWCHAR* _connStrIn,
    SQLSMALLINT _connStrInChars,
    SQLWCHAR* _connStrOut,
    SQLSMALLINT _connStrOutMaxChars,
    SQLSMALLINT* _connStrOutChars) {
  return exceptionBoundary!(() => {
    auto connStr = toDString(_connStrIn, _connStrInChars);
    auto connStrOut = outputWChar(_connStrOut, _connStrOutMaxChars * wchar.sizeof, _connStrOutChars);
    scope (exit) convertPtrBytesToWChars(_connStrOutChars);

    logMessage("SQLBrowseConnect (unimplemented)", connStr);
    return SQL_SUCCESS;
  }());
}

///// SQLConnect /////

SQLRETURN SQLConnectW(
    SQLHDBC hdbc,
    in SQLWCHAR* _serverName,
    SQLSMALLINT _serverNameLengthChars,
    in SQLWCHAR* _userName,
    SQLSMALLINT _userNameLengthChars,
    in SQLWCHAR* _authenticationString,
    SQLSMALLINT _authenticationStringLengthChars) {
  logMessage("SQLConnect (unimplemented)");
  return exceptionBoundary!(() => {
    auto serverName = toDString(_serverName, _serverNameLengthChars);
    auto userName = toDString(_userName, _userNameLengthChars);
    auto authenticationName = toDString(_authenticationString, _authenticationStringLengthChars);
    logMessage("SQLConnect (unimplemented)", serverName, userName, authenticationName);
    return SQL_SUCCESS;
  }());
}

///// SQLExecDirect /////

SQLRETURN SQLExecDirectW(
    OdbcStatement statementHandle,
    in SQLWCHAR* _statementText,
    SQLINTEGER _textLengthChars) {
  return exceptionBoundary!(() => {
    auto statementText = toDString(_statementText, _textLengthChars);
    logMessage("SQLExecDirectW (unimplemented)", statementText);
    with (statementHandle) {
      //TODO
    }
    return SQL_SUCCESS;
  }());
}

///// SQLAllocHandle /////

SQLRETURN SQLAllocHandle(
    SQL_HANDLE_TYPE	handleType,
    SQLHANDLE handleParent,
    SQLHANDLE* newHandlePointer) {
  dllEnforce(newHandlePointer != null);

  with(SQL_HANDLE_TYPE) {
    switch (handleType) {
    case DBC:
      break;
    case DESC:
      break;
    case ENV:
      break;
    case SENV:
      break;
    case STMT:
      *newHandlePointer = cast(void*) makeWithoutGC!OdbcStatement();
      break;
    default:
      *newHandlePointer = null;
      return SQL_ERROR;
    }
  }

  logMessage("SQLAllocHandle", handleType, handleType);

  return SQL_SUCCESS;
}

///// SQLBindCol /////

SQLRETURN SQLBindCol(
    OdbcStatement statementHandle,
    SQLUSMALLINT columnNumber,
    SQL_C_TYPE_ID columnType,
    SQLPOINTER outputBuffer,
    SQLLEN bufferLengthBytes,
    SQLLEN* numberOfBytesWritten) {
  return exceptionBoundary!(() => {
    logMessage("SQLBindCol", columnNumber, columnType, bufferLengthBytes);
    dllEnforce(statementHandle !is null);
    with (statementHandle) {
      if (outputBuffer == null) {
        columnBindings.remove(columnNumber);
        return SQL_SUCCESS;
      }
      if (bufferLengthBytes < 0) {
        return SQL_ERROR;
      }
      if (numberOfBytesWritten) {
        *numberOfBytesWritten = 0;
      }

      if (columnType > SQL_C_TYPE_ID.max || columnType < SQL_C_TYPE_ID.min) {
        logMessage("SQLBindCol: Column type out of bounds:", columnType);
        return SQL_ERROR;
      }

      auto binding = ColumnBinding(numberOfBytesWritten);
      binding.columnType = columnType;
      binding.outputBuffer = outputBuffer[0 .. bufferLengthBytes];
      columnBindings[columnNumber] = binding;
    }

    return SQL_SUCCESS;
  }());
}

///// SQLCancel /////

SQLRETURN SQLCancel(OdbcStatement statementHandle) {
  return exceptionBoundary!(() => {
    logMessage("SQLCancel (unimplemented)");
    with (statementHandle) {
      //TODO -- Not relevant until we support concurrency
    }
    return SQL_SUCCESS;
  }());
}

///// SQLDescribeCol /////

SQLRETURN SQLDescribeColW(
    OdbcStatement statementHandle,
    SQLUSMALLINT columnNumber,
    SQLWCHAR* _columnName,
    SQLSMALLINT _columnNameMaxLengthChars,
    SQLSMALLINT* _columnNameLengthChars,
    SQLSMALLINT* sqlDataTypeOfColumn,
    SQLULEN* columnSize,
    SQLSMALLINT* decimalDigits,
    SQLSMALLINT* nullable) {
  return exceptionBoundary!(() => {
    auto columnName = outputWChar(_columnName, _columnNameMaxLengthChars * wchar.sizeof, _columnNameLengthChars);
    scope (exit) convertPtrBytesToWChars(_columnNameLengthChars);
    assert(columnName);
    assert(_columnNameLengthChars);
    assert(sqlDataTypeOfColumn);
    assert(columnSize);
    assert(decimalDigits);
    assert(nullable);
    logMessage("SQLDescribeCol", columnNumber);
    with (statementHandle) {
      //TODO: Technically this can be called after SQLPrepare, not just SQLExecute, fix this:
      dllEnforce(latestOdbcResult !is null);
      auto result = cast(PrestoResult) latestOdbcResult;
      auto columnMetadata = result.columnMetadata[columnNumber - 1];
      copyToBuffer(wtext(columnMetadata.name), columnName);
      auto sqlTypeId = prestoTypeToSqlTypeId(columnMetadata.type);
      *sqlDataTypeOfColumn = sqlTypeId;
      *columnSize = columnSizeMap[sqlTypeId] >= 0 ? columnSizeMap[sqlTypeId] : 0;
      *decimalDigits = decimalDigitsMap[sqlTypeId];
      *nullable = to!SQLSMALLINT(Nullability.SQL_NULLABLE_UNKNOWN);

      logMessage("SQLDescribeCol found column: ", columnMetadata.name, columnMetadata.type, sqlTypeId);
    }
    return SQL_SUCCESS;
  }());
}

///// SQLDescribeParam /////

SQLRETURN SQLDescribeParam(
    OdbcStatement statementHandle,
    SQLUSMALLINT parameterNumber,
    SQLSMALLINT* dataType,
    SQLULEN* columnSize,
    SQLSMALLINT* decimalDigits,
    SQLSMALLINT* nullable) {
  return exceptionBoundary!(() => {
    logMessage("SQLDescribeParam (unimplemented)", parameterNumber);
    with (statementHandle) {
      //TODO
    }
    return SQL_SUCCESS;
  }());
}

///// SQLDisconnect /////

SQLRETURN SQLDisconnect(SQLHDBC connectionHandle) {
  return exceptionBoundary!(() => {
    logMessage("SQLDisconnect (unimplemented)");
    return SQL_SUCCESS;
  }());
}

///// SQLExecute /////

SQLRETURN SQLExecute(OdbcStatement statementHandle) {
  return exceptionBoundary!(() => {
    logMessage("SQLExecute");
    with (statementHandle) {
      import bindings;
      auto client = runQuery(text(query));
      auto result = makeWithoutGC!PrestoResult();
      uint batchNumber;
      foreach (resultBatch; client) {
        logMessage("SQLExecute working on result batch", ++batchNumber);
        result.columnMetadata = resultBatch.columnMetadata;
        foreach (row; resultBatch.data.array) {
          auto dataRow = makeWithoutGC!PrestoResultRow();
          foreach (columnData; row.array) {
            addToPrestoResultRow(columnData, dataRow);
          }
          dllEnforce(dataRow.numberOfColumns() != 0, "Row has at least 1 column");
          result.addRow(dataRow);
        }
      }
      latestOdbcResult = result;
    }
    return SQL_SUCCESS;
  }());
}

///// SQLFetch /////

SQLRETURN SQLFetch(OdbcStatement statementHandle) {
  return exceptionBoundary!(() => {
    logMessage("SQLFetch");

    dllEnforce(statementHandle !is null);
    with (statementHandle) {
      if (latestOdbcResult.empty) {
        return SQL_NO_DATA;
      }

      logMessage("SQLFetch -- Showing something!");
      auto row = latestOdbcResult.front;
      latestOdbcResult.popFront;
      foreach (col, binding; statementHandle.columnBindings) {
        if (col > latestOdbcResult.numberOfColumns) {
          return SQL_ERROR;
        }
        logMessage("SQLFetching column:", col);
        dispatchOnSqlCType!(copyToOutput)(binding.columnType, row.dataAt(col), binding);
      }
    }
    return SQL_SUCCESS;
  }());
}

///// SQLFreeStmt /////

SQLRETURN SQLFreeStmt(
    OdbcStatement statementHandle,
    FreeStmtOptions option) {
  import std.c.stdlib : free;
  return exceptionBoundary!(() => {
    logMessage("SQLFreeStmt", option);
    with (statementHandle) with (FreeStmtOptions) {
      final switch(option) {
      case SQL_CLOSE:
        latestOdbcResult = null;
        columnBindings = null;
        break;
      case SQL_DROP:
        dllEnforce(false, "Deprecated option: SQL_DROP");
        return SQL_ERROR;
      case SQL_UNBIND:
        columnBindings = null;
        break;
      case SQL_RESET_PARAMS:
        break;
      }
    }

    return SQL_SUCCESS;
  }());
}

///// SQLGetCursorName /////

SQLRETURN SQLGetCursorNameW(
    OdbcStatement statementHandle,
    SQLWCHAR* _cursorName,
    SQLSMALLINT _cursorNameMaxLengthBytes,
    SQLSMALLINT* _cursorNameLengthBytes) {
    return exceptionBoundary!(() => {
      auto cursorName = outputWChar(_cursorName, _cursorNameMaxLengthBytes, _cursorNameLengthBytes);
      logMessage("SQLGetCursorName (unimplemented)");
      with (statementHandle) {
        //TODO
      }
    return SQL_SUCCESS;
  }());
}

///// SQLSetCursorName /////

SQLRETURN SQLSetCursorNameW(
    OdbcStatement statementHandle,
    in SQLWCHAR* _cursorName,
    SQLSMALLINT _cursorNameLengthChars) {
  return exceptionBoundary!(() => {
    auto cursorName = toDString(_cursorName, _cursorNameLengthChars);
    logMessage("SQLSetCursorName (unimplemented)");
    with (statementHandle) {
      //TODO
    }
    return SQL_SUCCESS;
  }());
}

///// SQLNumResultCols /////

SQLRETURN SQLNumResultCols(
    OdbcStatement statementHandle,
    SQLSMALLINT* columnCount) {
  return exceptionBoundary!(() => {
    logMessage("SQLNumResultCols (pseudo-implemented)");
    assert(columnCount);
    with (statementHandle) {
      //TODO: Revisit this assert: Can actually call this function when the query
      //                           is prepared but before it has been executed.
      logMessage(text(typeid(cast(Object) statementHandle.latestOdbcResult)));
      bool couldBeEmptyPrestoResult = typeid(cast(Object) statementHandle.latestOdbcResult) == typeid(PrestoResult);
      bool isAnOldResult = latestOdbcResult.empty && latestOdbcResult.numberOfColumns;
      assert(!isAnOldResult || couldBeEmptyPrestoResult);
      *columnCount = to!SQLSMALLINT(latestOdbcResult.numberOfColumns);
    }
    return SQL_SUCCESS;
  }());
}

///// SQLPrepare /////

SQLRETURN SQLPrepareW(
    OdbcStatement statementHandle,
    in SQLWCHAR* _statementText,
    SQLINTEGER _textLengthChars) {
  return exceptionBoundary!(() => {
    auto statementText = toDString(_statementText, _textLengthChars);
    logMessage("SQLPrepare", statementText);
    with (statementHandle) {
      query = statementText.idup;
    }
    return SQL_SUCCESS;
  }());
}

///// SQLRowCount /////

SQLRETURN SQLRowCount(
    OdbcStatement statementHandle,
    SQLLEN* rowCount) {
  return exceptionBoundary!(() => {
    logMessage("SQLRowCount (unimplemented)", rowCount);
    with (statementHandle) {
      //TODO
    }
    return SQL_SUCCESS;
  }());
}

///// SQLColumns /////

SQLRETURN SQLColumnsW(
    OdbcStatement statementHandle,
    in SQLWCHAR* _catalogName,
    SQLSMALLINT _catalogNameLength,
    in SQLWCHAR* _schemaName,
    SQLSMALLINT _schemaNameLength,
    in SQLWCHAR* _tableName,
    SQLSMALLINT _tableNameLength,
    in SQLWCHAR* _columnName,
    SQLSMALLINT _columnNameLength) {
  return exceptionBoundary!(() => {
    auto catalogName = toDString(_catalogName, _catalogNameLength);
    auto schemaName = toDString(_schemaName, _schemaNameLength);
    auto tableName = toDString(_tableName, _tableNameLength);
    auto columnName = toDString(_columnName, _columnNameLength);

    logMessage("SQLColumns", catalogName, schemaName, tableName, columnName);
    with (statementHandle) {
      latestOdbcResult = listColumnsInTable(text(tableName));
    }
    return SQL_SUCCESS;
  }());
}

///// SQLColumnPrivileges /////

SQLRETURN SQLColumnPrivilegesW(
    OdbcStatement statementHandle,
    in SQLWCHAR* _catalogName,
    SQLSMALLINT _catalogNameLength,
    in SQLWCHAR* _schemaName,
    SQLSMALLINT _schemaNameLength,
    in SQLWCHAR* _tableName,
    SQLSMALLINT _tableNameLength,
    in SQLWCHAR* _columnName,
    SQLSMALLINT _columnNameLength) {
  return exceptionBoundary!(() => {
    auto catalogName = toDString(_catalogName, _catalogNameLength);
    auto schemaName = toDString(_schemaName, _schemaNameLength);
    auto tableName = toDString(_tableName, _tableNameLength);
    auto columnName = toDString(_columnName, _columnNameLength);

    logMessage("SQLColumnPrivileges", catalogName, schemaName, tableName, columnName);
    with (statementHandle) {
      //TODO
    }
    return SQL_SUCCESS;
  }());
}

///// SQLGetData /////

SQLRETURN SQLGetData(
    OdbcStatement statementHandle,
    SQLUSMALLINT columnNumber,
    SQL_C_TYPE_ID targetType,
    SQLPOINTER targetValue,
    SQLLEN bufferLength,
    SQLLEN* stringLengthBytes) {
  return exceptionBoundary!(() => {
    logMessage("SQLGetData (unimplemented)", columnNumber, targetType);
    with (statementHandle) {
      //TODO
    }
    return SQL_SUCCESS;
  }());
}

///// SQLGetInfo /////

SQLRETURN SQLGetInfoW(
    SQLHDBC connectionHandle,
    OdbcInfo infoType,
    SQLPOINTER _infoValue,
    SQLSMALLINT _bufferMaxLengthBytes,
    SQLSMALLINT* _stringLengthBytes) {
  return exceptionBoundary!(() => {
    auto stringResult = outputWChar(_infoValue, _bufferMaxLengthBytes, _stringLengthBytes);
    logMessage("SQLGetInfo", infoType);
    with (OdbcInfo) {
      switch (infoType) {

      case SQL_DRIVER_ODBC_VER: // 77
        //Latest version of ODBC is 3.8 (as of 6/19/14)
        copyToBuffer(""w, stringResult);
        break;
      case SQL_ASYNC_DBC_FUNCTIONS: //10023
        *cast(SQLUSMALLINT*)(_infoValue) = SQL_ASYNC_DBC_NOT_CAPABLE;
        break;
      case SQL_ASYNC_NOTIFICATION: //10025
        *cast(SQLUSMALLINT*)(_infoValue) = SQL_ASYNC_NOTIFICATION_NOT_CAPABLE;
        break;
      case SQL_CURSOR_COMMIT_BEHAVIOR: //23
        *cast(SQLUSMALLINT*)(_infoValue) = SQL_CB_DELETE;
        break;
      case SQL_CURSOR_ROLLBACK_BEHAVIOR: //24
        *cast(SQLUSMALLINT*)(_infoValue) = SQL_CB_DELETE;
        break;
      case SQL_GETDATA_EXTENSIONS: //81
        *cast(SQLUSMALLINT*)(_infoValue) = SQL_GD_ANY_ORDER;
        break;
      case SQL_DATA_SOURCE_NAME: //2
        copyToBuffer(""w, stringResult);
        break;
      case SQL_MAX_CONCURRENT_ACTIVITIES: //1
        *cast(SQLUSMALLINT*)(_infoValue) = 1;
        break;
      case SQL_DATA_SOURCE_READ_ONLY: //25
        copyToBuffer("Y"w, stringResult);
        break;
      case SQL_DRIVER_NAME: //6
        copyToBuffer("ODBCDRV0.dll"w, stringResult);
        break;
      case SQL_SEARCH_PATTERN_ESCAPE: //14
        copyToBuffer("%"w, stringResult);
        break;
      case SQL_CORRELATION_NAME: //74
        *cast(SQLUSMALLINT*)(_infoValue) = SQL_CN_ANY;
        break;
      case SQL_NON_NULLABLE_COLUMNS: //75
        *cast(SQLUSMALLINT*)(_infoValue) = SQL_NNC_NON_NULL;
        break;
      case SQL_CATALOG_NAME_SEPARATOR: //41
        copyToBuffer("."w, stringResult);
        break;
      case SQL_FILE_USAGE: //84
        *cast(SQLUSMALLINT*)(_infoValue) = SQL_FILE_CATALOG;
        break;
      case SQL_CATALOG_TERM: //42
        copyToBuffer("catalog"w, stringResult);
        break;
      case SQL_DATABASE_NAME: //16
        copyToBuffer("dbname"w, stringResult);
        break;
      case SQL_MAX_SCHEMA_NAME_LEN: //32
        *cast(SQLUSMALLINT*)(_infoValue) = 0;
        break;
      case SQL_IDENTIFIER_QUOTE_CHAR: //29
        copyToBuffer("\""w, stringResult);
        break;
      case SQL_OWNER_TERM: //39
        copyToBuffer("schema"w, stringResult);
        break;
      default:
        logMessage("SQLGetInfo: Unhandled case: ", infoType);
        break;
      } //switch
    }
    return SQL_SUCCESS;
  }());
}

///// SQLGetTypeInfo /////
SQLRETURN SQLGetTypeInfoW(
    OdbcStatement statementHandle,
    SQL_TYPE_ID dataType) {
  return exceptionBoundary!(() => {
    import typeinfo;
    logMessage("SQLGetTypeInfo", dataType);

    with (statementHandle) with (Nullability) with (SQL_TYPE_ID) {
      switch(dataType) {
      case SQL_UNKNOWN_TYPE:
      case SQL_VARCHAR:
        latestOdbcResult = new TypeInfoResult!VarcharTypeInfoResultRow(SQL_NULLABLE);
        break;
      default:
        logMessage("Unexpected type in GetTypeInfo");
        break;
      }
    }

    return SQL_SUCCESS;
  }());
}

///// SQLParamData /////

SQLRETURN SQLParamData(
    OdbcStatement statementHandle,
    SQLPOINTER *value) {
  return exceptionBoundary!(() => {
    logMessage("SQLParamData (unimplemented)");
    with (statementHandle) {
      //TODO
    }
    return SQL_SUCCESS;
  }());
}

///// SQLPutData /////

SQLRETURN SQLPutData(
    OdbcStatement statementHandle,
    SQLPOINTER data,
    SQLLEN stringLengthBytes) {
  return exceptionBoundary!(() => {
    logMessage("SQLPutData (unimplemented)");
    with (statementHandle) {
      //TODO
    }
    return SQL_SUCCESS;
  }());
}

///// SQLSpecialColumns /////


SQLRETURN SQLSpecialColumnsW(
    OdbcStatement statementHandle,
    SpecialColumnRequestType identifierType,
    in SQLWCHAR* _catalogName,
    SQLSMALLINT _catalogNameLength,
    in SQLWCHAR* _schemaName,
    SQLSMALLINT _schemaNameLength,
    in SQLWCHAR* _tableName,
    SQLSMALLINT _tableNameLength,
    SQLUSMALLINT minScope,
    SQLUSMALLINT nullable) {
  return exceptionBoundary!(() => {
    auto catalogName = toDString(_catalogName, _catalogNameLength);
    auto schemaName = toDString(_schemaName, _schemaNameLength);
    auto tableName = toDString(_tableName, _tableNameLength);
    with (statementHandle) with (SpecialColumnRequestType) {
      logMessage("SQLSpecialColumns (unimplemented)", identifierType, catalogName, schemaName, tableName, minScope, nullable);
      final switch (identifierType) {
      case SQL_BEST_ROWID:
        latestOdbcResult = new EmptyOdbcResult();
        break;
      case SQL_ROWVER:
        latestOdbcResult = new EmptyOdbcResult();
        break;
      }
    }
    return SQL_SUCCESS;
  }());
}

///// SQLStatistics /////

SQLRETURN SQLStatisticsW(
    OdbcStatement statementHandle,
    in SQLWCHAR* _catalogName,
    SQLSMALLINT _catalogNameLengthChars,
    in SQLWCHAR* _schemaName,
    SQLSMALLINT _schemaNameLengthChars,
    in SQLWCHAR* _tableName,
    SQLSMALLINT _tableNameLengthChars,
    IndexType unique,
    StatisticsUrgency urgency) {
  return exceptionBoundary!(() => {
    auto catalogName = toDString(_catalogName, _catalogNameLengthChars);
    auto schemaName = toDString(_schemaName, _schemaNameLengthChars);
    auto tableName = toDString(_tableName, _tableNameLengthChars);
    logMessage("SQLStatistics (unimplemented)", catalogName, schemaName, tableName, unique, urgency);
    with (statementHandle) {
      //TODO
    }
    return SQL_SUCCESS;
  }());
}

///// SQLTables /////

SQLRETURN SQLTablesW(
    OdbcStatement statementHandle,
    in SQLWCHAR* _catalogName,
    SQLSMALLINT _catalogNameLength,
    in SQLWCHAR* _schemaName,
    SQLSMALLINT _schemaNameLength,
    in SQLWCHAR* _tableNamePattern,
    SQLSMALLINT _tableNamePatternLength,
    in SQLWCHAR* _tableType,
    SQLSMALLINT _tableTypeLength) {
  return exceptionBoundary!(() => {
    import tableinfo;
    auto catalogName = toDString(_catalogName, _catalogNameLength);
    auto schemaName = toDString(_schemaName, _schemaNameLength);
    auto tableNamePattern = toDString(_tableNamePattern, _tableNamePatternLength);
    auto tableType = toDString(_tableType, _tableTypeLength);
    with (statementHandle) {
      logMessage("SQLTablesW", catalogName, schemaName, tableNamePattern, tableType);

      auto client = runQuery("SHOW TABLES");
      auto result = makeWithoutGC!TableInfoResult();
      foreach (resultBatch; client) {
        foreach (row; resultBatch.data.array) {
          auto tableName = row.array.front.str;
          result.addTable(tableName);
          logMessage("SQLTablesW found table:", tableName);
        }
      }

      latestOdbcResult = result;
      return SQL_SUCCESS;
      return SQL_SUCCESS;
    }
  }());
}

///// SQLForeignKeys /////

SQLRETURN SQLForeignKeysW(
    OdbcStatement statementHandle,
    in SQLWCHAR* _primaryKeyCatalogName,
    SQLSMALLINT _primaryKeyCatalogNameLengthChars,
    in SQLWCHAR* _primaryKeySchemaName,
    SQLSMALLINT _primaryKeySchemaNameLengthChars,
    in SQLWCHAR* _primaryKeyTableName,
    SQLSMALLINT _primaryKeyTableNameLengthChars,
    in SQLWCHAR* _foreignKeyCatalogName,
    SQLSMALLINT _foreignKeyCatalogNameLengthChars,
    in SQLWCHAR* _foreignKeySchemaName,
    SQLSMALLINT _foreignKeySchemaNameLengthChars,
    in SQLWCHAR* _foreignKeyTableName,
    SQLSMALLINT _foreignKeyTableNameLengthChars) {
  return exceptionBoundary!(() => {
    auto primaryKeyCatalogName = toDString(_primaryKeyCatalogName, _primaryKeyCatalogNameLengthChars);
    auto primaryKeySchemaName = toDString(_primaryKeySchemaName, _primaryKeySchemaNameLengthChars);
    auto primaryKeyTableName = toDString(_primaryKeyTableName, _primaryKeyTableNameLengthChars);
    auto foreignKeyCatalogName = toDString(_foreignKeyCatalogName, _foreignKeyCatalogNameLengthChars);
    auto foreignKeySchemaName = toDString(_foreignKeySchemaName, _foreignKeySchemaNameLengthChars);
    auto foreignKeyTableName = toDString(_foreignKeyTableName, _foreignKeyTableNameLengthChars);

    logMessage("SQLForeignKeys (unimplemented)",
        primaryKeyCatalogName, primaryKeySchemaName, primaryKeyTableName,
        foreignKeyCatalogName, foreignKeySchemaName, foreignKeyTableName);
    with (statementHandle) {
      //TODO
    }
    return SQL_SUCCESS;
  }());
}

///// SQLMoreResults /////
SQLRETURN SQLMoreResults(OdbcStatement statementHandle) {
  return exceptionBoundary!(() => {
    logMessage("SQLMoreResults (unimplemented)");
    with (statementHandle) {
      //TODO
    }
    return SQL_SUCCESS;
  }());
}

///// SQLNativeSql /////

SQLRETURN SQLNativeSqlW(
    SQLHDBC hdbc,
    in SQLWCHAR* _inSql,
    SQLINTEGER _inSqlLengthChars,
    SQLWCHAR* _outSql,
    SQLINTEGER _outSqlMaxLengthBytes,
    SQLINTEGER* _outSqlLengthBytes) {
  return exceptionBoundary!(() => {
    auto inSql = toDString(_inSql, _inSqlLengthChars);
    auto outSql = outputWChar(_outSql, _outSqlMaxLengthBytes, _outSqlLengthBytes);
    logMessage("SQLNativeSql (unimplemented)", inSql);
    return SQL_SUCCESS;
  }());
}

///// SQLNumParams /////

SQLRETURN SQLNumParams(
    OdbcStatement statementHandle,
    SQLSMALLINT* parameterCount) {
  return exceptionBoundary!(() => {
    logMessage("SQLNumParams (unimplemented)");
    with (statementHandle) {
      //TODO
    }
    return SQL_SUCCESS;
  }());
}

///// SQLPrimaryKeys /////

SQLRETURN SQLPrimaryKeysW(
    OdbcStatement statementHandle,
    in SQLWCHAR* _catalogName,
    SQLSMALLINT _catalogNameLength,
    in SQLWCHAR* _schemaName,
    SQLSMALLINT _schemaNameLength,
    in SQLWCHAR* _tableName,
    SQLSMALLINT _tableNameLength) {
  return exceptionBoundary!(() => {
    auto catalogName = toDString(_catalogName, _catalogNameLength);
    auto schemaName = toDString(_schemaName, _schemaNameLength);
    auto tableName = toDString(_tableName, _tableNameLength);

    logMessage("SQLPrimaryKeys (unimplemented)", catalogName, schemaName, tableName);
    with (statementHandle) {
      //TODO
    }
    return SQL_SUCCESS;
  }());
}

///// SQLProcedureColumns /////

SQLRETURN SQLProcedureColumnsW(
    OdbcStatement statementHandle,
    in SQLWCHAR* _catalogName,
    SQLSMALLINT _catalogNameLength,
    in SQLWCHAR* _schemaName,
    SQLSMALLINT _schemaNameLength,
    in SQLWCHAR* _procedureName,
    SQLSMALLINT _procedureNameLength,
    in SQLWCHAR* _columnName,
    SQLSMALLINT _columnNameLength) {
  return exceptionBoundary!(() => {
    auto catalogName = toDString(_catalogName, _catalogNameLength);
    auto schemaName = toDString(_schemaName, _schemaNameLength);
    auto procedureName = toDString(_procedureName, _procedureNameLength);
    auto columnName = toDString(_columnName, _columnNameLength);

    logMessage("SQLProcedureColumns (unimplemented)", catalogName, schemaName, procedureName, columnName);
    with (statementHandle) {
      //TODO
    }
    return SQL_SUCCESS;
  }());
}

///// SQLProcedures /////

SQLRETURN SQLProceduresW(
    OdbcStatement statementHandle,
    in SQLWCHAR* _catalogName,
    SQLSMALLINT _catalogNameLength,
    in SQLWCHAR* _schemaName,
    SQLSMALLINT _schemaNameLength,
    in SQLWCHAR* _procedureName,
    SQLSMALLINT _procedureNameLength) {
  return exceptionBoundary!(() => {
    auto catalogName = toDString(_catalogName, _catalogNameLength);
    auto schemaName = toDString(_schemaName, _schemaNameLength);
    auto procedureName = toDString(_procedureName, _procedureNameLength);

    logMessage("SQLProcedures (unimplemented)", catalogName, schemaName, procedureName);
    with (statementHandle) {
      //TODO
    }
    return SQL_SUCCESS;
  }());
}

///// SQLSetPos /////

SQLRETURN SQLSetPos(
    OdbcStatement statementHandle,
    SQLSETPOSIROW rowNumber,
    SetPosOperation operation,
    SetPosLockOperation lockType) {
  return exceptionBoundary!(() => {
    logMessage("SQLSetPos (unimplemented)", rowNumber, operation, lockType);
    with (statementHandle) {
      //TODO
    }
    return SQL_SUCCESS;
  }());
}

///// SQLTablePrivileges /////

SQLRETURN SQLTablePrivilegesW(
    OdbcStatement statementHandle,
    in SQLWCHAR* _catalogName,
    SQLSMALLINT _catalogNameLength,
    in SQLWCHAR* _schemaName,
    SQLSMALLINT _schemaNameLength,
    in SQLWCHAR* _tableName,
    SQLSMALLINT _tableNameLength) {
  return exceptionBoundary!(() => {
    auto catalogName = toDString(_catalogName, _catalogNameLength);
    auto schemaName = toDString(_schemaName, _schemaNameLength);
    auto tableName = toDString(_tableName, _tableNameLength);

    logMessage("SQLTablePrivileges (unimplemented)", catalogName, schemaName, tableName);
    with (statementHandle) {
      //TODO
    }
    return SQL_SUCCESS;
  }());
}

///// SQLBindParameter /////

SQLRETURN SQLBindParameter(
    OdbcStatement statementHandle,
    SQLUSMALLINT parameterNumber,
    InputOutputType inputOutputType,
    SQL_C_TYPE_ID valueType,
    SQL_TYPE_ID parameterType,
    SQLULEN columnSize,
    SQLSMALLINT decimalDigits,
    SQLPOINTER parameterValue,
    SQLLEN bufferLength,
    SQLLEN* stringLengthBytes) {
  return exceptionBoundary!(() => {
    logMessage("SQLBindParameter (unimplemented)", parameterNumber, inputOutputType,
        valueType, parameterType, columnSize, decimalDigits);
    with (statementHandle) {
      //TODO
    }
    return SQL_SUCCESS;
  }());
}

///// SQLCloseCursor /////

SQLRETURN SQLCloseCursor(OdbcStatement statementHandle) {
  return exceptionBoundary!(() => {
    logMessage("SQLCloseCursor (unimplemented)");
    with (statementHandle) {
      //TODO
    }
    return SQL_SUCCESS;
  }());
}

///// SQLColAttribute /////

SQLRETURN SQLColAttributeW(
    OdbcStatement statementHandle,
    SQLUSMALLINT columnNumber,
    SQLUSMALLINT fieldIdentifier,
    SQLPOINTER characterAttribute,
    SQLSMALLINT bufferLength,
    SQLSMALLINT* stringLength,
    SQLLEN* numericAttribute) {
  return exceptionBoundary!(() => {
    logMessage("SQLColAttribute (unimplemented)", columnNumber, fieldIdentifier);
    with (statementHandle) {
      //TODO
    }
    return SQL_SUCCESS;
  }());
}

///// SQLCopyDesc /////

SQLRETURN SQLCopyDesc(SQLHDESC sourceDescHandle, SQLHDESC targetDescHandle) {
  return exceptionBoundary!(() => {
    logMessage("SQLCopyDesc (unimplemented)");
    return SQL_SUCCESS;
  }());
}

///// SQLEndTran /////
SQLRETURN SQLEndTran(
    SQL_HANDLE_TYPE handleType,
    SQLHANDLE handle,
    TransactionOption completionType) {
  return exceptionBoundary!(() => {
    logMessage("SQLEndTran (unimplemented)", handleType, completionType);
    return SQL_SUCCESS;
  }());
}

///// SQLFetchScroll /////

SQLRETURN SQLFetchScroll(
    OdbcStatement statementHandle,
    FetchType fetchOrientation,
    SQLLEN fetchOffset) {
  return exceptionBoundary!(() => {
    logMessage("SQLFetchScroll (unimplemented)", fetchOrientation, fetchOffset);
    with (statementHandle) {
      //TODO
    }
    return SQL_SUCCESS;
  }());
}

///// SQLFreeHandle /////

SQLRETURN SQLFreeHandle(SQL_HANDLE_TYPE handleType, SQLHANDLE handle) {
  return exceptionBoundary!(() => {
    logMessage("SQLFreeHandle", handleType);

    with(SQL_HANDLE_TYPE) {
      switch (handleType) {
      case DBC:
      case DESC:
      case ENV:
      case SENV:
        logMessage("SQLFreeHandle not implemented for handle type", handleType);
        break;
      case STMT:
        free(cast(void*) handle);
        break;
      default:
        return SQL_ERROR;
      }
    }

    return SQL_SUCCESS;
  }());
}

///// SQLGetConnectAttr /////

SQLRETURN SQLGetConnectAttrW(
    SQLHDBC connectionHandle,
    ConnectionAttribute attribute,
    SQLPOINTER value,
    SQLINTEGER bufferLengthBytes,
    SQLINTEGER* stringLengthBytes) {
  return exceptionBoundary!(() => {
    logMessage("SQLGetConnectAttr (unimplemented)", attribute);
    return SQL_SUCCESS;
  }());
}

///// SQLSetConnectAttr /////

SQLRETURN SQLSetConnectAttrW(
    SQLHDBC connectionHandle,
    ConnectionAttribute attribute,
    SQLPOINTER value,
    SQLINTEGER stringLength) {
  return exceptionBoundary!(() => {
    logMessage("SQLSetConnectAttr (unimplemented)", attribute);
    return SQL_SUCCESS;
  }());

}

///// SQLGetDescField /////

SQLRETURN SQLGetDescFieldW(
    SQLHDESC descriptorHandle,
    SQLSMALLINT recordNumber,
    DescriptorField fieldIdentifier,
    SQLPOINTER value,
    SQLINTEGER bufferLength,
    SQLINTEGER* stringLengthBytes) {
  return exceptionBoundary!(() => {
    logMessage("SQLGetDescField (unimplemented)", recordNumber, fieldIdentifier);
    return SQL_SUCCESS;
  }());
}

///// SQLSetDescField /////

SQLRETURN SQLSetDescFieldW(
    SQLHDESC descriptorHandle,
    SQLSMALLINT recordNumber,
    DescriptorField fieldIdentifier,
    SQLPOINTER value,
    SQLINTEGER bufferLength) {
  return exceptionBoundary!(() => {
    logMessage("SQLSetDescField (unimplemented)");
    return SQL_SUCCESS;
  }());
}


///// SQLGetDescRec /////

SQLRETURN SQLGetDescRecW(
    SQLHDESC descriptorHandle,
    SQLSMALLINT recordNumber,
    SQLWCHAR* _name,
    SQLSMALLINT _nameMaxLengthChars,
    SQLSMALLINT* _nameLengthChars,
    SQLSMALLINT* descType,
    SQLSMALLINT* subType,
    SQLLEN* length,
    SQLSMALLINT* precision,
    SQLSMALLINT* scale,
    SQLSMALLINT* nullable) {
  return exceptionBoundary!(() => {
    logMessage("SQLGetDescRec (unimplemented)", recordNumber);
    return SQL_SUCCESS;
  }());
}

///// SQLSetDescRec /////

SQLRETURN SQLSetDescRec(
    SQLHDESC descriptorHandle,
    SQLSMALLINT recordNumber,
    SQLSMALLINT type,
    SQLSMALLINT subType,
    SQLLEN length,
    SQLSMALLINT precision,
    SQLSMALLINT scale,
    SQLPOINTER data,
    SQLLEN* stringLengthBytes,
    SQLLEN* indicator) {
  return exceptionBoundary!(() => {
    logMessage("SQLSetDescRec (unimplemented)", recordNumber, type, subType, length, precision, scale);
    return SQL_SUCCESS;
  }());
}

///// SQLGetDiagField /////

SQLRETURN SQLGetDiagFieldW(
    SQL_HANDLE_TYPE handleType,
    SQLHANDLE handle,
    SQLSMALLINT recordNumber,
    SQLSMALLINT diagnosticIdentifier,
    SQLPOINTER _diagnosticInfo,
    SQLSMALLINT _diagnosticInfoLengthBytes,
    SQLSMALLINT* _stringLengthBytes) {
  return exceptionBoundary!(() => {
    auto diagnosticInfo = outputWChar(_diagnosticInfo, _diagnosticInfoLengthBytes, _stringLengthBytes);
    if (diagnosticInfo) {
      diagnosticInfo[0] = '\0';
    }
    logMessage("SQLGetDiagField (unimplemented)", handleType, recordNumber,
        diagnosticIdentifier, diagnosticInfo.length);
    return SQL_NO_DATA;
  }());
}

///// SQLGetDiagRec /////

SQLRETURN SQLGetDiagRecW(
    SQL_HANDLE_TYPE handleType,
    SQLHANDLE handle,
    SQLSMALLINT recordNumber,
    SQLWCHAR*  _sqlState,
    SQLINTEGER* nativeError,
    SQLWCHAR* _errorMessage,
    SQLSMALLINT _errorMessageMaxLengthChars,
    SQLSMALLINT* _errorMessageLengthChars) {
  return exceptionBoundary!(() => {
    auto sqlState = outputWChar!(void*)(_sqlState, 5 * wchar.sizeof, null);
    auto errorMessage = outputWChar(_errorMessage, _errorMessageMaxLengthChars * wchar.sizeof,
                                                   _errorMessageLengthChars);
    scope (exit) convertPtrBytesToWChars(_errorMessageLengthChars);
    logMessage("SQLGetDiagRec (unimplemented)", handleType, recordNumber);
    return SQL_SUCCESS;
  }());
}

///// SQLGetEnvAttr /////

SQLRETURN SQLGetEnvAttr(
    SQLHENV environmentHandle,
    EnvironmentAttribute attribute,
    SQLPOINTER value,
    SQLINTEGER bufferLength,
    SQLINTEGER* stringLengthBytes) {
  return exceptionBoundary!(() => {
    logMessage("SQLGetEnvAttr (unimplemented)", attribute);
    return SQL_SUCCESS;
  }());
}

///// SQLSetEnvAttr /////

SQLRETURN SQLSetEnvAttr(
    SQLHENV environmentHandle,
    EnvironmentAttribute attribute,
    SQLPOINTER value,
    SQLINTEGER stringLengthBytes) {
  return exceptionBoundary!(() => {
    logMessage("SQLSetEnvAttr (unimplemented)", attribute);
    with (EnvironmentAttribute) {
      switch (attribute) {
      case SQL_ATTR_ODBC_VERSION:
        break;
      default:
        return SQL_ERROR;
      }
    }
    return SQL_SUCCESS;
  }());
}

///// SQLGetStmtAttr /////

SQLRETURN SQLGetStmtAttrW(
    OdbcStatement statementHandle,
    StatementAttribute attribute,
    SQLPOINTER value,
    SQLINTEGER _valueLengthBytes,
    SQLINTEGER* _stringLengthBytes) {
  return exceptionBoundary!(() => {
    auto valueString = outputWChar(value, _valueLengthBytes, _stringLengthBytes);
    with (statementHandle) with (StatementAttribute) {
      switch (attribute) {
      case SQL_ATTR_APP_ROW_DESC:
        value = null;
        break;
      case SQL_ATTR_APP_PARAM_DESC:
        value = null;
        break;
      case SQL_ATTR_IMP_ROW_DESC:
        value = null;
        break;
      case SQL_ATTR_IMP_PARAM_DESC:
        value = null;
        break;
      default:
        return SQL_ERROR;
      }
    }
    logMessage("SQLGetStmtAttr (unimplemented)", attribute);
    return SQL_SUCCESS;
  }());
}

///// SQLSetStmtAttr /////

SQLRETURN SQLSetStmtAttrW(
  OdbcStatement statementHandle,
  StatementAttribute attribute,
  in SQLPOINTER _value,
  SQLINTEGER _valueLengthBytes) {
  return exceptionBoundary!(() => {
    logMessage("SQLSetStmtAttr (unimplemented)", attribute);
    with (statementHandle) with (StatementAttribute) {
      switch (attribute) {
      default:
        logMessage("SQLGetInfo: Unhandled case:", attribute);
        break;
      }
    }
    return SQL_SUCCESS;
  }());
}

///// SQLBulkOperations /////

SQLRETURN SQLBulkOperations(
    OdbcStatement statementHandle,
    BulkOperation operation) {
  return exceptionBoundary!(() => {
    with (statementHandle) {
      logMessage("SQLBulkOperations (unimplemented)", operation);
      return SQL_SUCCESS;
    }
  }());
}
