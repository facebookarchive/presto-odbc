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
import std.regex : ctRegex, matchFirst;

import std.c.stdio;
import std.c.stdlib;
import std.c.string;
import std.c.windows.windows;

import sqlext;
import odbcinst;

import util;
import handles;
import bindings;
import prestoresults;
import columnresults;
import typeinfo;

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
      logMessage("Presto ODBC Driver loaded by application or driver manager");
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
    OdbcConnection connectionHandle,
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
    OdbcConnection connectionHandle,
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
    OdbcConnection connectionHandle,
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
    logMessage("SQLExecDirectW", statementText);
    auto returnCode = SQLPrepareW(statementHandle, _statementText, _textLengthChars);
    if (returnCode != SQL_SUCCESS) {
      return returnCode;
    }
    return SQLExecute(statementHandle);
  }());
}

///// SQLAllocHandle /////

SQLRETURN SQLAllocHandle(
    SQL_HANDLE_TYPE	handleType,
    SQLHANDLE _parentHandle,
    SQLHANDLE* newHandlePointer) {
  dllEnforce(newHandlePointer != null);
  logMessage("SQLAllocHandle", handleType);

  with(SQL_HANDLE_TYPE) {
    switch (handleType) {
    case DBC: //Connection Handle
      auto parentHandle = cast(OdbcEnvironment) _parentHandle;
      *newHandlePointer = cast(void*) makeWithoutGC!OdbcConnection(parentHandle);
      break;
    case DESC: //Descriptor Handle
      auto parentHandle = cast(OdbcConnection) _parentHandle;
      *newHandlePointer = cast(void*) makeWithoutGC!OdbcDescriptor(parentHandle);
      break;
    case ENV: //Environment Handle
      *newHandlePointer = cast(void*) makeWithoutGC!OdbcEnvironment();
      break;
    case SENV: //???? (This might mean 'Shared Environment Handle', not sure)
      logMessage("Unimplemented handle type: SENV");
      break;
    case STMT: //Statement Handle
      auto parentHandle = cast(OdbcConnection) _parentHandle;
      *newHandlePointer = cast(void*) makeWithoutGC!OdbcStatement(parentHandle);
      break;
    default:
      *newHandlePointer = null;
      return SQL_ERROR;
    }
  }
  return SQL_SUCCESS;
}

///// SQLBindCol /////

SQLRETURN SQLBindCol(
    OdbcStatement statementHandle,
    SQLUSMALLINT columnNumber,
    SQL_C_TYPE_ID columnType,
    SQLPOINTER outputBuffer,
    SQLLEN bufferLengthMaxBytes,
    SQLLEN* numberOfBytesWritten) {
  return exceptionBoundary!(() => {
    logMessage("SQLBindCol", columnNumber, columnType, bufferLengthMaxBytes);
    dllEnforce(statementHandle !is null);
    with (statementHandle) with (applicationRowDescriptor) {
      if (outputBuffer == null) {
        columnBindings.remove(columnNumber);
        return SQL_SUCCESS;
      }
      if (bufferLengthMaxBytes < 0) {
        return SQL_ERROR;
      }
      if (numberOfBytesWritten) {
        *numberOfBytesWritten = 0;
      }

      if (columnType > SQL_C_TYPE_ID.max || columnType < SQL_C_TYPE_ID.min) {
        logMessage("SQLBindCol: Column type out of bounds:", columnType);
        return SQL_ERROR;
      }

      auto binding = ColumnBinding(columnType, outputBuffer[0 .. bufferLengthMaxBytes], numberOfBytesWritten);
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

    if (!statementHandle.executedQuery) {
      SQLExecuteImpl(statementHandle);
    }

    return SQL_SUCCESS;
  }());
}

//On the relationship/requirements of SQLPrepare and SQLExecute:
// http://msdn.microsoft.com/en-us/library/ms716365%28v=vs.85%29.aspx

void SQLExecuteImpl(OdbcStatement statementHandle) {
  logMessage("SQLExecuteImpl");
  with (statementHandle) {
    auto client = runQuery(text(query));
    auto result = makeWithoutGC!PrestoResult();
    executedQuery = true;
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
}

///// SQLFetch /////

SQLRETURN SQLFetch(OdbcStatement statementHandle) {
  return exceptionBoundary!(() => {
    logMessage("SQLFetch");

    dllEnforce(statementHandle !is null);
    with (statementHandle) with (applicationRowDescriptor) {
      return bindDataFromColumns(statementHandle, columnBindings);
    }
  }());
}

SQLRETURN bindDataFromColumns(OdbcStatement statementHandle, ColumnBinding[uint] columnBindings) {
  with (statementHandle) {
    if (latestOdbcResult.empty) {
      return SQL_NO_DATA;
    }

    auto row = popAndSave(latestOdbcResult);
    foreach (columnNumber, binding; columnBindings) {
      if (columnNumber > latestOdbcResult.numberOfColumns) {
        throw new OdbcException(statementHandle, StatusCode.GENERAL_ERROR,
            "Column "w ~ wtext(columnNumber) ~ " does not exist"w);
      }
      logMessage("Binding data from column:", columnNumber);
      dispatchOnSqlCType!(copyToOutput)(binding.columnType, row.dataAt(columnNumber), binding);
    }
  }

  enum rowsFetched = 1;
  if (statementHandle.rowsFetched) {
    *statementHandle.rowsFetched = rowsFetched;
  }
  if (statementHandle.rowStatusPtr) {
    foreach (ref status; statementHandle.rowStatusPtr[0 .. rowsFetched]) {
      status = RowStatus.SQL_ROW_SUCCESS;
    }
  }

  return SQL_SUCCESS;
}

///// SQLFreeStmt /////

SQLRETURN SQLFreeStmt(
    OdbcStatement statementHandle,
    FreeStmtOptions option) {
  import std.c.stdlib : free;
  return exceptionBoundary!(() => {
    logMessage("SQLFreeStmt", option);
    with (statementHandle) with (applicationRowDescriptor) with (FreeStmtOptions) {
      final switch(option) {
      case SQL_CLOSE:
        latestOdbcResult = null;
        applicationRowDescriptor = new ApplicationRowDescriptor(connection);
        break;
      case SQL_DROP:
        dllEnforce(false, "Deprecated option: SQL_DROP");
        return SQL_ERROR;
      case SQL_UNBIND:
        applicationRowDescriptor = new ApplicationRowDescriptor(connection);
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
    dllEnforce(columnCount != null);
    with (statementHandle) {
      if (!executedQuery) {
        SQLExecute(statementHandle);
      }
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

    enum regexPattern = r"(?:^|\s)(DROP|CREATE|INDEX|TEMPORARY|INSERT|TOP)\s"w;
    auto regexEngine = ctRegex!regexPattern;
    auto captures = matchFirst(statementText, regexEngine);
    if (!captures.empty) {
      throw new OdbcException(statementHandle, StatusCode.OPTIONAL_FEATURE,
          ("Invalid query ("w ~ wtext(captures.front) ~ ") "w ~ statementText).idup);
    }

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
    logMessage("SQLRowCount");
    *rowCount = 0;
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
    SQLSMALLINT _targetType,
    SQLPOINTER outputBuffer,
    SQLLEN bufferLengthMaxBytes,
    SQLLEN* stringLengthBytes) {
  //Note: Does not support retrieving parameter data
  return exceptionBoundary!(() => {
    with (statementHandle) with (applicationRowDescriptor) {
      auto targetType = getColumnTargetType(statementHandle, columnNumber, _targetType);
      logMessage("SQLGetData (untested)", columnNumber, targetType);

      auto binding = ColumnBinding(targetType, outputBuffer[0 .. bufferLengthMaxBytes], stringLengthBytes);
      return bindDataFromColumns(statementHandle, [ columnNumber : binding ]);
    }
    return SQL_SUCCESS;
  }());
}

SQL_C_TYPE_ID getColumnTargetType(
    OdbcStatement statementHandle,
    SQLUSMALLINT columnNumber,
    SQLSMALLINT _targetType) {
  with (statementHandle) with (applicationRowDescriptor) {
    if (_targetType == SQL_ARD_TYPE) {
      return columnBindings[columnNumber - 1].columnType;
    }
    return cast(SQL_C_TYPE_ID) _targetType;
  }
}

///// SQLGetTypeInfo /////
SQLRETURN SQLGetTypeInfoW(
    OdbcStatement statementHandle,
    SQL_TYPE_ID dataType) {
  return exceptionBoundary!(() => {
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
      logMessage("SQLSpecialColumns", identifierType, catalogName, schemaName, tableName, minScope, nullable);
      final switch (identifierType) {
      case SQL_BEST_ROWID:
      case SQL_ROWVER:
        //For Presto this function will always return the empty set
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

    logMessage("SQLForeignKeys",
        primaryKeyCatalogName, primaryKeySchemaName, primaryKeyTableName,
        foreignKeyCatalogName, foreignKeySchemaName, foreignKeyTableName);
    with (statementHandle) {
      latestOdbcResult = new EmptyOdbcResult();
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
    OdbcConnection connectionHandle,
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

    logMessage("SQLPrimaryKeys", catalogName, schemaName, tableName);
    with (statementHandle) {
      latestOdbcResult = new EmptyOdbcResult();
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
    DescriptorField fieldIdentifier,
    SQLPOINTER _characterAttribute,
    SQLSMALLINT _bufferMaxLengthBytes,
    SQLSMALLINT* _stringLengthBytes,
    SQLLEN* numericAttribute) {
  return exceptionBoundary!(() => {
    auto characterAttribute = outputWChar(_characterAttribute, _bufferMaxLengthBytes, _stringLengthBytes);
    logMessage("SQLColAttribute", columnNumber, fieldIdentifier);
    with (statementHandle) with (DescriptorField) {
      if (fieldIdentifier == SQL_DESC_COUNT) {
        *numericAttribute = latestOdbcResult.numberOfColumns;
        return SQL_SUCCESS;
      }

      dllEnforce(columnNumber != 0, "Have not yet implemented this case");
      auto result = cast(PrestoResult) latestOdbcResult;
      auto columnMetadata = result.columnMetadata[columnNumber - 1];
      auto sqlTypeId = prestoTypeToSqlTypeId(columnMetadata.type);
      logMessage("SQLColAttribute's column type is", sqlTypeId);

      switch (fieldIdentifier) {
      case SQL_COLUMN_DISPLAY_SIZE: //SQL_DESC_DISPLAY_SIZE
        *numericAttribute = toColAttributeSizeUnknownFormat(displaySizeMap[sqlTypeId]);
        break;
      case SQL_DESC_LENGTH:
        *numericAttribute = toColAttributeSizeUnknownFormat(columnSizeMap[sqlTypeId]);
        break;
      case SQL_DESC_OCTET_LENGTH:
        *numericAttribute = toColAttributeSizeUnknownFormat(octetLengthMap[sqlTypeId]);
        break;
      case SQL_COLUMN_AUTO_INCREMENT: //SQL_DESC_AUTO_UNIQUE_VALUE
        *numericAttribute = SQL_FALSE;
        break;
      case SQL_DESC_BASE_COLUMN_NAME:
      case SQL_COLUMN_LABEL: //SQL_DESC_LABEL
        copyToBuffer(wtext(columnMetadata.name), characterAttribute);
        break;
      case SQL_DESC_BASE_TABLE_NAME:
        logMessage("Unhandled case (dummy implementation) SQL_DESC_BASE_COLUMN_NAME");
        copyToBuffer(""w, characterAttribute);
        break;
      case SQL_COLUMN_CASE_SENSITIVE: //SQL_DESC_CASE_SENSITIVE
        *numericAttribute = SQL_FALSE;
        break;
      case SQL_COLUMN_QUALIFIER_NAME: //SQL_DESC_CATALOG_NAME
        copyToBuffer("tpch"w, characterAttribute);
        break;
      case SQL_COLUMN_TYPE: //SQL_DESC_CONCISE_TYPE
        *numericAttribute = sqlTypeId;
        break;
      case SQL_DESC_LITERAL_PREFIX:
      case SQL_DESC_LITERAL_SUFFIX:
        auto literal = isStringTypeId(sqlTypeId) ? "'"w : ""w;
        copyToBuffer(literal, characterAttribute);
      case SQL_DESC_LOCAL_TYPE_NAME:
        copyToBuffer(""w, characterAttribute);
        break;
      case SQL_DESC_NUM_PREC_RADIX:
        *numericAttribute = typeToNumPrecRadix(sqlTypeId);
        break;
      case SQL_COLUMN_OWNER_NAME: //SQL_DESC_SCHEMA_NAME
        copyToBuffer("tiny"w, characterAttribute);
        break;
      case SQL_COLUMN_SEARCHABLE: //SQL_DESC_SEARCHABLE
        *numericAttribute = Searchable.SQL_PRED_SEARCHABLE;
        break;
      case SQL_COLUMN_TABLE_NAME: //SQL_DESC_TABLE_NAME
        logMessage("Unhandled case (dummy implementation) SQL_COLUMN_TABLE_NAME");
        copyToBuffer(""w, characterAttribute);
        break;
      case SQL_COLUMN_TYPE_NAME: //SQL_DESC_TYPE_NAME
        copyToBuffer(wtext(columnMetadata.type), characterAttribute);
        break;
      case SQL_COLUMN_UNSIGNED: //SQL_DESC_UNSIGNED
        *numericAttribute = SQL_FALSE;
        break;
      case SQL_COLUMN_UPDATABLE: //SQL_DESC_UPDATABLE
        *numericAttribute = ColumnUpdatable.SQL_ATTR_READONLY;
        break;
      case SQL_DESC_TYPE:
        *numericAttribute = toVerboseType(sqlTypeId);
        break;
      case SQL_DESC_PRECISION:
        if (!isTimeRelated(sqlTypeId)) {
          *numericAttribute = columnSizeMap[sqlTypeId];
          break;
        }
        logMessage("Unhandled case: SQL_DESC_PRECISION of a time-related type", sqlTypeId);
        break;
      case SQL_DESC_SCALE:
        //TODO: This value is undefined for all but the SQL_NUMERIC and SQL_DECIMAL
        //      types, which are presently unsupported.
        *numericAttribute = 0;
      case SQL_DESC_NULLABLE:
        *numericAttribute = Nullability.SQL_NULLABLE_UNKNOWN;
        break;
      case SQL_DESC_NAME:
        copyToBuffer(wtext(columnMetadata.name), characterAttribute);
        break;
      case SQL_DESC_UNNAMED:
        *numericAttribute = (columnMetadata.name == "") ? SQL_UNNAMED : SQL_NAMED;
        break;
      default:
      case SQL_COLUMN_MONEY: //SQL_DESC_FIXED_PREC_SCALE
        logMessage("SQLColAttribute Unhandled Case:", fieldIdentifier);
        return SQL_ERROR;
      }
    }
    return SQL_SUCCESS;
  }());
}

/*
 * For calls to: SQL_COLUMN_DISPLAY_SIZE SQL_DESC_LENGTH, SQL_DESC_OCTET_LENGTH with string SQL IDs
 *
 * A value of -1 is how I specify that for string types Tableau needs to just "figure it out".
 *
 * The appropriate 'figure it out' value for SQLGetData (for the same stats) is SQL_NO_TOTAL, which has a value of -4.
 * SQL_NO_TOTAL is also the recommended "don't know" value on the specific pages for these various data type sizes
 * If I use that, Tableau gives me buffers of size 1.
 * If I give Tableau -1 for these values, it seems to recognize that and does the right thing.
 *
 * Unfortunately, searching for all named constants -1 in sql.d and sqlext.d does not come up with anything appropriate for this case.
 * This is appears to be a bit of a magic number, and might be an application-specific magic number at that.
 *
 * Reference:
 * http://msdn.microsoft.com/en-us/library/ms713558%28v=vs.85%29.aspx
 * http://msdn.microsoft.com/en-us/library/ms712499%28v=vs.85%29.aspx
 * http://msdn.microsoft.com/en-us/library/ms711786%28v=vs.85%29.aspx
 */
N toColAttributeSizeUnknownFormat(N)(N size) if (isNumeric!N) {
  if (size == SQL_NO_TOTAL) {
    return -1;
  }
  return size;
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
    logMessage("SQLEndTran (pseudo-implemented)", handleType, completionType);
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
    auto sqlState = outputWChar!(void*)(_sqlState, 6 * wchar.sizeof, null);
    auto errorMessage = outputWChar(_errorMessage, _errorMessageMaxLengthChars * wchar.sizeof,
                                                   _errorMessageLengthChars);
    scope (exit) convertPtrBytesToWChars(_errorMessageLengthChars);

    with (SQL_HANDLE_TYPE) {
      switch (handleType) {
      case STMT:
        logMessage("SQLGetDiagRec", handleType, recordNumber);
        with (cast(OdbcStatement) handle) {
          if (recordNumber > errors.length) {
            return SQL_NO_DATA;
          }

          auto error = errors[recordNumber - 1];
          copyToBuffer(error.sqlState, sqlState);
          *nativeError = error.code;
          if (errorMessage) {
            copyToBuffer(error.message, errorMessage);
          }
        }
        break;
      default:
        logMessage("SQLGetDiagRec (unimplemented)", handleType, recordNumber);
        return SQL_NO_DATA;
      }
    }
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
    logMessage("SQLGetStmtAttr (unimplemented)", attribute);
    with (statementHandle) with (StatementAttribute) {
      switch (attribute) {
      case SQL_ATTR_APP_ROW_DESC:
        *(cast(void**) value) = cast(void*) applicationParameterDescriptor_;
        break;
      case SQL_ATTR_APP_PARAM_DESC:
        *(cast(void**) value) = cast(void*) implementationParameterDescriptor_;
        break;
      case SQL_ATTR_IMP_ROW_DESC:
        *(cast(void**) value) = cast(void*) applicationRowDescriptor_;
        break;
      case SQL_ATTR_IMP_PARAM_DESC:
        *(cast(void**) value) = cast(void*) implementationRowDescriptor_;
        break;
      case SQL_ATTR_ROW_ARRAY_SIZE:
        *cast(SQLULEN*) value = rowArraySize;
        break;
      case SQL_ATTR_ROWS_FETCHED_PTR:
        *cast(SQLULEN**) value = rowsFetched;
        break;
      case SQL_ATTR_ROW_STATUS_PTR:
        *cast(RowStatus**) value = rowStatusPtr;
        break;
      default:
        throw new OdbcException(statementHandle, StatusCode.OPTIONAL_FEATURE, "Unsupported attribute"w);
      }
    }
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
      case SQL_ATTR_ASYNC_ENABLE:
        throw new OdbcException(statementHandle, StatusCode.OPTIONAL_FEATURE, "Async not supported"w);
      case SQL_ATTR_ROW_ARRAY_SIZE:
        //This value determines how many rows should be returned at once by fetch. We limit it to 1
        throw new OdbcException(statementHandle,
            StatusCode.MODIFIED_USER_VALUE, "Not allowed to modify this value"w);
      case SQL_ATTR_ROWS_FETCHED_PTR:
        //A pointer in which to store how many rows actually *are* returned during a fetch
        rowsFetched = cast(SQLULEN*) _value;
        break;
      case SQL_ATTR_ROW_STATUS_PTR:
        //A pointer to an array where the driver writes RowStatuses for each of the returned rows
        rowStatusPtr = (cast(RowStatus*) _value);
        break;
      case SQL_ATTR_ROW_BIND_TYPE:
        dllEnforce(false, "Involves a lot of work in SQLBindCol and others");
      case SQL_ATTR_APP_ROW_DESC:
        applicationParameterDescriptor_ = cast(OdbcDescriptor) _value;
        break;
      case SQL_ATTR_APP_PARAM_DESC:
        implementationParameterDescriptor_ = cast(OdbcDescriptor) _value;
        break;
      case SQL_ATTR_IMP_ROW_DESC:
      case SQL_ATTR_IMP_PARAM_DESC:
        throw new OdbcException(statementHandle,
            StatusCode.GENERAL_ERROR, "ODBC disallows modifying the IRD/IPD"w);
      default:
        throw new OdbcException(statementHandle, StatusCode.OPTIONAL_FEATURE, "Unsupported attribute"w);
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
