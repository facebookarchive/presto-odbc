
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
import util : OutputWChar, wcharsToBytes, runQuery;
import bindings;
import prestoresults;

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

SQLRETURN SQLDriverConnectW(
    SQLHDBC hdbc,
    SQLHWND hwnd,
    in SQLWCHAR* _connStrIn,
    SQLSMALLINT _connStrInChars,
    SQLWCHAR* _connStrOut,
    SQLSMALLINT _connStrOutMaxChars,
    SQLSMALLINT* connStrOutChars,
    SQLUSMALLINT driverCompletion) {
  return exceptionBoundary!(() => {
    auto connStr = toDString(_connStrIn, _connStrInChars);
    auto connStrOut = OutputWChar(_connStrOut, _connStrOutMaxChars * wchar.sizeof);
    if (connStrOutChars) {
      *connStrOutChars = 0;
    }
    logMessage("SQLDriverConnect", connStr, _connStrInChars, _connStrOutMaxChars, connStrOutChars, driverCompletion);

    if (connStr == null) {
      return SQL_SUCCESS;
    }

    //Copy input string to output string
    if (connStrOut) {
      auto numCharsCopied = copyToBuffer(connStr, connStrOut);

      if (connStrOutChars) {
        *connStrOutChars = numCharsCopied;
      }

    }

    return SQL_SUCCESS;
  }());
}

///// SQLExecDirect /////

SQLRETURN SQLExecDirectW(
    SQLHSTMT hstmt,
    SQLWCHAR* szSqlStr,
    SQLINTEGER TextLength) {
  logMessage("SQLExecDirect", szSqlStr, TextLength);
  return SQL_SUCCESS;
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

SQLRETURN SQLCancel(SQLHSTMT StatementHandle) {
  logMessage("SQLCancel");
  return SQL_SUCCESS;
}

///// SQLConnect /////

SQLRETURN SQLConnectW(
    SQLHDBC hdbc,
    SQLWCHAR* szDSN,
    SQLSMALLINT cchDSN,
    SQLWCHAR* szUID,
    SQLSMALLINT cchUID,
    SQLWCHAR* szAuthStr,
    SQLSMALLINT cchAuthStr) {
  logMessage("SQLConnect");
  return SQL_SUCCESS;
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
    auto columnName = OutputWChar(_columnName, _columnNameMaxLengthChars * wchar.sizeof);
    assert(columnName);
    assert(_columnNameLengthChars);
    assert(sqlDataTypeOfColumn);
    assert(columnSize);
    assert(decimalDigits);
    assert(nullable);
    logMessage("SQLDescribeCol", columnNumber);
    with (statementHandle) {
      *_columnNameLengthChars = copyToBuffer("amount"w, columnName);
      *sqlDataTypeOfColumn = SQL_TYPE_ID.SQL_INTEGER;
      *columnSize = 10;
      *decimalDigits = 0;
      *nullable = Nullability.SQL_NO_NULLS;
    }
    return SQL_SUCCESS;
  }());
}

///// SQLDisconnect /////

SQLRETURN SQLDisconnect(SQLHDBC ConnectionHandle) {
  logMessage("SQLDisconnect");
  return SQL_SUCCESS;
}

///// SQLExecute /////

SQLRETURN SQLExecute(OdbcStatement statementHandle) {
  return exceptionBoundary!(() => {
    logMessage("SQLExecute");
    with (statementHandle) {
      import bindings;
      auto client = runQuery(text(query));
      auto result = makeWithoutGC!PrestoResult();
      foreach (batchNumber, resultBatch; client) {
        logMessage("SQLExecute working on result batch", batchNumber);
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
    with (statementHandle) {
      with (FreeStmtOptions) {
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
      logMessage("SQLFreeStmt", option);
    }

    return SQL_SUCCESS;
  }());
}

///// SQLGetCursorName /////

SQLRETURN SQLGetCursorNameW(
    SQLHSTMT hstmt,
    SQLWCHAR* szCursor,
    SQLSMALLINT cchCursorMax,
    SQLSMALLINT* pcchCursor) {
  logMessage("SQLGetCursorName", szCursor, cchCursorMax, pcchCursor);
  return SQL_SUCCESS;
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
    SQLHSTMT StatementHandle,
    SQLLEN* RowCount) {
  logMessage("SQLRowCount", RowCount);
  return SQL_SUCCESS;
}

///// SQLSetCursorName /////

SQLRETURN SQLSetCursorNameW(
    SQLHSTMT hstmt,
    SQLWCHAR* szCursor,
    SQLSMALLINT cchCursor) {
  logMessage("SQLSetCursorName");
  return SQL_SUCCESS;
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

    with (statementHandle) {
      logMessage("SQLColumns", catalogName, schemaName, tableName, columnName);
      latestOdbcResult = new ColumnsResult();
      return SQL_SUCCESS;
    }
  }());
}

///// SQLGetData /////

SQLRETURN SQLGetData(
    SQLHSTMT StatementHandle,
    SQLUSMALLINT ColumnNumber,
    SQLSMALLINT TargetType,
    SQLPOINTER TargetValue,
    SQLLEN BufferLength,
    SQLLEN* StrLen_or_IndPtr) {
  logMessage("SQLGetData");
  return SQL_SUCCESS;
}

///// SQLGetInfo /////

SQLRETURN SQLGetInfoW(
    SQLHDBC connectionHandle,
    OdbcInfo infoType,
    SQLPOINTER _infoValue,
    SQLSMALLINT bufferLengthBytes,
    SQLSMALLINT* stringLengthBytes) {
  return exceptionBoundary!(() => {
    dllEnforce(bufferLengthBytes % 2 == 0);
    auto stringResult = OutputWChar(_infoValue, bufferLengthBytes);
    with (OdbcInfo) {
      if (stringLengthBytes) {
        *stringLengthBytes = 0;
      }
      switch (infoType) {

      case SQL_DRIVER_ODBC_VER: // 77
        //Latest version of ODBC is 3.8 (as of 6/19/14)
        *stringLengthBytes = wcharsToBytes(copyToBuffer(""w, stringResult));
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
        *stringLengthBytes = wcharsToBytes(copyToBuffer(""w, stringResult));
        break;
      case SQL_MAX_CONCURRENT_ACTIVITIES: //1
        *cast(SQLUSMALLINT*)(_infoValue) = 1;
        break;
      case SQL_DATA_SOURCE_READ_ONLY: //25
        *stringLengthBytes = wcharsToBytes(copyToBuffer("Y"w, stringResult));
        break;
      case SQL_DRIVER_NAME: //6
        *stringLengthBytes = wcharsToBytes(copyToBuffer("ODBCDRV0.dll"w, stringResult));
        break;
      case SQL_SEARCH_PATTERN_ESCAPE: //14
        *stringLengthBytes = wcharsToBytes(copyToBuffer("%"w, stringResult));
        break;
      case SQL_CORRELATION_NAME: //74
        *cast(SQLUSMALLINT*)(_infoValue) = SQL_CN_ANY;
        break;
      case SQL_NON_NULLABLE_COLUMNS: //75
        *cast(SQLUSMALLINT*)(_infoValue) = SQL_NNC_NON_NULL;
        break;
      case SQL_CATALOG_NAME_SEPARATOR: //41
        *stringLengthBytes = wcharsToBytes(copyToBuffer("."w, stringResult));
        break;
      case SQL_FILE_USAGE: //84
        *cast(SQLUSMALLINT*)(_infoValue) = SQL_FILE_CATALOG;
        break;
      case SQL_CATALOG_TERM: //42
        *stringLengthBytes = wcharsToBytes(copyToBuffer("catalog"w, stringResult));
        break;
      case SQL_DATABASE_NAME: //16
        *stringLengthBytes = wcharsToBytes(copyToBuffer("dbname"w, stringResult));
        break;
      case SQL_MAX_SCHEMA_NAME_LEN: //32
        *cast(SQLUSMALLINT*)(_infoValue) = 0;
        break;
      case SQL_IDENTIFIER_QUOTE_CHAR: //29
        *stringLengthBytes = wcharsToBytes(copyToBuffer("\""w, stringResult));
        break;
      case SQL_OWNER_TERM: //39
        *stringLengthBytes = wcharsToBytes(copyToBuffer("schema"w, stringResult));
        break;
      default:
        logMessage("SQLGetInfo: Unhandled case: ", infoType);
        break;
      } //switch
    }
    logMessage("SQLGetInfo", infoType, bufferLengthBytes);
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
    SQLHSTMT StatementHandle,
    SQLPOINTER *Value) {
  logMessage("SQLParamData");
  return SQL_SUCCESS;
}

///// SQLPutData /////

SQLRETURN SQLPutData(
    SQLHSTMT StatementHandle,
    SQLPOINTER Data,
    SQLLEN StrLen_or_Ind) {
  logMessage("SQLPutData");
  return SQL_SUCCESS;
}

///// SQLSpecialColumns /////


SQLRETURN SQLSpecialColumnsW(
    OdbcStatement statementHandle,
    SQL_SPECIAL_COLUMN_REQUEST_TYPE identifierType,
    SQLWCHAR* _catalogName,
    SQLSMALLINT _catalogNameLength,
    SQLWCHAR* _schemaName,
    SQLSMALLINT _schemaNameLength,
    SQLWCHAR* _tableName,
    SQLSMALLINT _tableNameLength,
    SQLUSMALLINT minScope,
    SQLUSMALLINT nullable) {
  return exceptionBoundary!(() => {
    auto catalogName = toDString(_catalogName, _catalogNameLength);
    auto schemaName = toDString(_schemaName, _schemaNameLength);
    auto tableName = toDString(_tableName, _tableNameLength);
    with (statementHandle) {
      with (SQL_SPECIAL_COLUMN_REQUEST_TYPE) {
        logMessage("SQLSpecialColumns", identifierType, catalogName, schemaName, tableName, minScope, nullable);
        final switch (identifierType) {
        case SQL_BEST_ROWID:
          latestOdbcResult = new EmptyOdbcResult();
          break;
        case SQL_ROWVER:
          latestOdbcResult = new EmptyOdbcResult();
          break;
        }
      }
    }
    return SQL_SUCCESS;
  }());
}

///// SQLStatistics /////

SQLRETURN SQLStatisticsW(
    SQLHSTMT hstmt,
    SQLWCHAR* szCatalogName,
    SQLSMALLINT cchCatalogName,
    SQLWCHAR* szSchemaName,
    SQLSMALLINT cchSchemaName,
    SQLWCHAR* szTableName,
    SQLSMALLINT cchTableName,
    SQLUSMALLINT fUnique,
    SQLUSMALLINT fAccuracy) {
  logMessage("SQLStatistics");
  return SQL_SUCCESS;
}

///// SQLTables /////

SQLRETURN SQLTablesW(
    OdbcStatement statementHandle,
    in SQLWCHAR* _catalogName,
    SQLSMALLINT _catalogNameLength,
    in SQLWCHAR* _schemaName,
    SQLSMALLINT _schemaNameLength,
    in SQLWCHAR* _tableName,
    SQLSMALLINT _tableNameLength,
    in SQLWCHAR* _tableType,
    SQLSMALLINT _tableTypeLength) {
  return exceptionBoundary!(() => {
    auto catalogName = toDString(_catalogName, _catalogNameLength);
    auto schemaName = toDString(_schemaName, _schemaNameLength);
    auto tableName = toDString(_tableName, _tableNameLength);
    auto tableType = toDString(_tableType, _tableTypeLength);
    with (statementHandle) {
      logMessage("SQLTablesW", catalogName, schemaName, tableName, tableType);
      latestOdbcResult = new TableInfoResult();
      return SQL_SUCCESS;
    }
  }());
}

///// SQLBrowseConnect /////

SQLRETURN SQLBrowseConnectW(
    SQLHDBC hdbc,
    SQLWCHAR* szConnStrIn,
    SQLSMALLINT cchConnStrIn,
    SQLWCHAR* szConnStrOut,
    SQLSMALLINT cchConnStrOutMax,
    SQLSMALLINT* pcchConnStrOut) {
  logMessage("SQLBrowseConnect");
  return SQL_SUCCESS;
}

///// SQLColumnPrivileges /////

SQLRETURN SQLColumnPrivilegesW(
    SQLHSTMT hstmt,
    SQLWCHAR* szCatalogName,
    SQLSMALLINT cchCatalogName,
    SQLWCHAR* szSchemaName,
    SQLSMALLINT cchSchemaName,
    SQLWCHAR* szTableName,
    SQLSMALLINT cchTableName,
    SQLWCHAR* szColumnName,
    SQLSMALLINT cchColumnName) {
  logMessage("SQLColumnPrivileges");
  return SQL_SUCCESS;
}

///// SQLDescribeParam /////

SQLRETURN SQLDescribeParam(
    SQLHSTMT hstmt,
    SQLUSMALLINT ipar,
    SQLSMALLINT* pfSqlType,
    SQLULEN* pcbParamDef,
    SQLSMALLINT* pibScale,
    SQLSMALLINT* pfNullable) {
  logMessage("SQLDescribeParam");
  return SQL_SUCCESS;
}

///// SQLExtendedFetch /////

SQLRETURN SQLExtendedFetch(
    SQLHSTMT hstmt,
    SQLUSMALLINT fFetchType,
    SQLLEN irow,
    SQLULEN* pcrow,
    SQLUSMALLINT* rgfRowStatus) {
  logMessage("SQLExtendedFetch");
  return SQL_SUCCESS;
}

///// SQLForeignKeys /////

SQLRETURN SQLForeignKeysW(
    SQLHSTMT hstmt,
    SQLWCHAR* szPkCatalogName,
    SQLSMALLINT cchPkCatalogName,
    SQLWCHAR* szPkSchemaName,
    SQLSMALLINT cchPkSchemaName,
    SQLWCHAR* szPkTableName,
    SQLSMALLINT cchPkTableName,
    SQLWCHAR* szFkCatalogName,
    SQLSMALLINT cchFkCatalogName,
    SQLWCHAR* szFkSchemaName,
    SQLSMALLINT cchFkSchemaName,
    SQLWCHAR* szFkTableName,
    SQLSMALLINT cchFkTableName) {
  logMessage("SQLForeignKeys");
  return SQL_SUCCESS;
}

///// SQLMoreResults /////
SQLRETURN SQLMoreResults(SQLHSTMT hstmt) {
  logMessage("SQLMoreResults");
  return SQL_SUCCESS;
}

///// SQLNativeSql /////

SQLRETURN SQLNativeSqlW(
    SQLHDBC hdbc,
    SQLWCHAR* szSqlStrIn,
    SQLINTEGER cchSqlStrIn,
    SQLWCHAR* szSqlStr,
    SQLINTEGER cchSqlStrMax,
    SQLINTEGER* pcchSqlStr) {
  logMessage("SQLNativeSql");
  return SQL_SUCCESS;
}

///// SQLNumParams /////

SQLRETURN SQLNumParams(
    SQLHSTMT hstmt,
    SQLSMALLINT* pcpar) {
  logMessage("SQLNumParams");
  return SQL_SUCCESS;
}

///// SQLPrimaryKeys /////

SQLRETURN SQLPrimaryKeysW(
    SQLHSTMT hstmt,
    SQLWCHAR* szCatalogName,
    SQLSMALLINT cchCatalogName,
    SQLWCHAR* szSchemaName,
    SQLSMALLINT cchSchemaName,
    SQLWCHAR* szTableName,
    SQLSMALLINT cchTableName) {
  logMessage("SQLPrimaryKeys");
  return SQL_SUCCESS;
}

///// SQLProcedureColumns /////

SQLRETURN SQLProcedureColumnsW(
    SQLHSTMT hstmt,
    SQLWCHAR* szCatalogName,
    SQLSMALLINT cchCatalogName,
    SQLWCHAR* szSchemaName,
    SQLSMALLINT cchSchemaName,
    SQLWCHAR* szProcName,
    SQLSMALLINT cchProcName,
    SQLWCHAR* szColumnName,
    SQLSMALLINT cchColumnName) {
  logMessage("SQLProcedureColumns");
  return SQL_SUCCESS;
}

///// SQLProcedures /////

SQLRETURN SQLProceduresW(
    SQLHSTMT hstmt,
    SQLWCHAR* szCatalogName,
    SQLSMALLINT cchCatalogName,
    SQLWCHAR* szSchemaName,
    SQLSMALLINT cchSchemaName,
    SQLWCHAR* szProcName,
    SQLSMALLINT cchProcName) {
  logMessage("SQLProcedures");
  return SQL_SUCCESS;
}

///// SQLSetPos /////

SQLRETURN SQLSetPos(
    SQLHSTMT hstmt,
    SQLSETPOSIROW irow,
    SQLUSMALLINT fOption,
    SQLUSMALLINT       fLock) {
  logMessage("SQLSetPos");
  return SQL_SUCCESS;
}

///// SQLTablePrivileges /////

SQLRETURN SQLTablePrivilegesW(
    SQLHSTMT hstmt,
    SQLWCHAR* szCatalogName,
    SQLSMALLINT cchCatalogName,
    SQLWCHAR* szSchemaName,
    SQLSMALLINT cchSchemaName,
    SQLWCHAR* szTableName,
    SQLSMALLINT cchTableName) {
  logMessage("SQLTablePrivileges");
  return SQL_SUCCESS;
}

///// SQLBindParameter /////

SQLRETURN SQLBindParameter(
    SQLHSTMT hstmt,
    SQLUSMALLINT ipar,
    SQLSMALLINT fParamType,
    SQLSMALLINT fCType,
    SQLSMALLINT fSqlType,
    SQLULEN cbColDef,
    SQLSMALLINT ibScale,
    SQLPOINTER rgbValue,
    SQLLEN cbValueMax,
    SQLLEN* pcbValue) {
  logMessage("SQLBindParameter");
  return SQL_SUCCESS;
}

///// SQLCloseCursor /////

SQLRETURN SQLCloseCursor(SQLHSTMT StatementHandle) {
  logMessage("SQLCloseCursor");
  return SQL_SUCCESS;
}

///// SQLColAttribute /////

SQLRETURN SQLColAttributeW(
    SQLHSTMT StatementHandle,
    SQLUSMALLINT ColumnNumber,
    SQLUSMALLINT FieldIdentifier,
    SQLPOINTER CharacterAttribute,
    SQLSMALLINT BufferLength,
    SQLSMALLINT* StringLength,
    SQLLEN* NumericAttribute) {
  logMessage("SQLColAttribute");
  return SQL_SUCCESS;
}

///// SQLCopyDesc /////

SQLRETURN SQLCopyDesc(
    SQLHDESC SourceDescHandle,
    SQLHDESC TargetDescHandle) {
  logMessage("SQLCopyDesc");
  return SQL_SUCCESS;
}

///// SQLEndTran /////
SQLRETURN SQLEndTran(
    SQLSMALLINT HandleType,
    SQLHANDLE Handle,
    SQLSMALLINT CompletionType) {
  logMessage("SQLEndTran");
  return SQL_SUCCESS;
}

///// SQLFetchScroll /////

SQLRETURN SQLFetchScroll(
    SQLHSTMT StatementHandle,
    SQLSMALLINT FetchOrientation,
    SQLLEN FetchOffset) {
  logMessage("SQLFetchScroll");
  return SQL_SUCCESS;
}

///// SQLFreeHandle /////

SQLRETURN SQLFreeHandle(SQL_HANDLE_TYPE handleType, SQLHANDLE handle) {
  return exceptionBoundary!(() => {
    logMessage("SQLFreeHandle", handleType);

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
    SQLHDBC ConnectionHandle,
    SQLINTEGER Attribute,
    SQLPOINTER Value,
    SQLINTEGER BufferLength,
    SQLINTEGER* StringLengthPtr) {
  logMessage("SQLGetConnectAttr");
  return SQL_SUCCESS;
}

///// SQLGetDescField /////

SQLRETURN SQLGetDescFieldW(
    SQLHDESC DescriptorHandle,
    SQLSMALLINT RecNumber,
    SQLSMALLINT FieldIdentifier,
    SQLPOINTER Value,
    SQLINTEGER BufferLength,
    SQLINTEGER* StringLength) {
  logMessage("SQLGetDescField");
  return SQL_SUCCESS;
}

///// SQLGetDescRec /////

SQLRETURN SQLGetDescRecW(
    SQLHDESC hdesc,
    SQLSMALLINT iRecord,
    SQLWCHAR* szName,
    SQLSMALLINT cchNameMax,
    SQLSMALLINT* pcchName,
    SQLSMALLINT* pfType,
    SQLSMALLINT* pfSubType,
    SQLLEN* pLength,
    SQLSMALLINT* pPrecision,
    SQLSMALLINT* pScale,
    SQLSMALLINT* pNullable) {
  logMessage("SQLGetDescRec");
  return SQL_SUCCESS;
}

///// SQLGetDiagField /////

SQLRETURN SQLGetDiagFieldW(
    SQLSMALLINT handleType,
    SQLHANDLE handle,
    SQLSMALLINT recNumber,
    SQLSMALLINT diagIdentifier,
    SQLPOINTER _diagInfo,
    SQLSMALLINT _diagInfoLengthBytes,
    SQLSMALLINT* stringLength) {
  return exceptionBoundary!(() => {
    auto diagInfo = OutputWChar(_diagInfo, _diagInfoLengthBytes);
    if (diagInfo) {
      diagInfo[0] = '\0';
    }
    if (stringLength) {
      *stringLength = 0;
    }
    logMessage("SQLGetDiagField", recNumber, diagIdentifier, diagInfo.length);
    return SQL_NO_DATA;
  }());
}

///// SQLGetDiagRec /////

SQLRETURN SQLGetDiagRecW(
    SQLSMALLINT fHandleType,
    SQLHANDLE handle,
    SQLSMALLINT iRecord,
    SQLWCHAR* szSqlState,
    SQLINTEGER* pfNativeError,
    SQLWCHAR* szErrorMsg,
    SQLSMALLINT cchErrorMsgMax,
    SQLSMALLINT* pcchErrorMsg) {
  logMessage("SQLGetDiagRec", iRecord, pfNativeError, (szErrorMsg == null), cchErrorMsgMax);
  return SQL_NO_DATA;
}

///// SQLGetEnvAttr /////

SQLRETURN SQLGetEnvAttr(
    SQLHENV EnvironmentHandle,
    SQLINTEGER Attribute,
    SQLPOINTER Value,
    SQLINTEGER BufferLength,
    SQLINTEGER* StringLength) {
  logMessage("SQLGetEnvAttr");
  return SQL_SUCCESS;
}

///// SQLGetStmtAttr /////

SQLRETURN SQLGetStmtAttrW(
    OdbcStatement statementHandle,
    StatementAttribute attribute,
    SQLPOINTER value,
    SQLINTEGER valueLengthBytes,
    SQLINTEGER* stringLength) {
  return exceptionBoundary!(() => {
    auto valueString = OutputWChar(value, valueLengthBytes);
    with (statementHandle) {
      with (StatementAttribute) {
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
    }
    logMessage("SQLGetStmtAttr", attribute);
    return SQL_SUCCESS;
  }());
}

///// SQLSetConnectAttr /////

SQLRETURN SQLSetConnectAttrW(
    SQLHDBC ConnectionHandle,
    SQLINTEGER Attribute,
    SQLPOINTER Value,
    SQLINTEGER StringLength) {
  switch (Attribute) {
  case SQL_LOGIN_TIMEOUT:
    break;
  default:
    return SQL_ERROR;
  }
  logMessage("SQLSetConnectAttr", Attribute, Value, StringLength);
  return SQL_SUCCESS;
}

///// SQLSetDescField /////

SQLRETURN SQLSetDescFieldW(
    SQLHDESC DescriptorHandle,
    SQLSMALLINT RecNumber,
    SQLSMALLINT FieldIdentifier,
    SQLPOINTER Value,
    SQLINTEGER BufferLength) {
  logMessage("SQLSetDescField");
  return SQL_SUCCESS;
}

///// SQLSetDescRec /////

SQLRETURN SQLSetDescRec(
    SQLHDESC DescriptorHandle,
    SQLSMALLINT RecNumber,
    SQLSMALLINT Type,
    SQLSMALLINT SubType,
    SQLLEN Length,
    SQLSMALLINT Precision,
    SQLSMALLINT Scale,
    SQLPOINTER Data,
    SQLLEN* StringLength,
    SQLLEN* Indicator) {
  logMessage("SQLSetDescRec");
  return SQL_SUCCESS;
}

///// SQLSetEnvAttr /////

SQLRETURN SQLSetEnvAttr(
    SQLHENV EnvironmentHandle,
    SQLINTEGER Attribute,
    SQLPOINTER Value,
    SQLINTEGER StringLength) {
  switch (Attribute) {
  case SQL_ATTR_ODBC_VERSION:

    break;
  default:
    return SQL_ERROR;
  }

  logMessage("SQLSetEnvAttr", Attribute, Value, StringLength);
  return SQL_SUCCESS;
}

///// SQLSetStmtAttr /////

SQLRETURN SQLSetStmtAttrW(
  OdbcStatement statementHandle,
  StatementAttribute attribute,
  in SQLPOINTER _value,
  SQLINTEGER _valueLengthBytes) {
  return exceptionBoundary!(() => {
        //dllEnforce(_valueLengthBytes % 2 == 0);
        //auto stringValue = toDString(cast(wchar*) _value, _valueLengthBytes / wchar.sizeof);
    with (statementHandle) {
      logMessage("SQLSetStmtAttr", attribute);
      with (StatementAttribute) {
        switch (attribute) {
        default:
          logMessage("SQLGetInfo: Unhandled case:", attribute);
          break;
        }
      }
    }
    return SQL_SUCCESS;
  }());
}


///// SQLBulkOperations /////

SQLRETURN SQLBulkOperations(
    SQLHSTMT StatementHandle,
    SQLSMALLINT Operation) {
  logMessage("SQLBulkOperations");
  return SQL_SUCCESS;
}
