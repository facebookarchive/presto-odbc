
import core.runtime;

import std.array : front, popFront, empty;
import std.algorithm;
import std.stdio : writeln;

import std.c.stdio;
import std.c.stdlib;
import std.c.string;
import std.c.windows.windows;

import sqlext;
import odbcinst;

import util : logMessage, copyToBuffer, makeWithoutGC;
import bindings;

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
    SQLWCHAR* connStrIn,
    SQLSMALLINT connStrInLen,
    SQLWCHAR* connStrOut,
    SQLSMALLINT connStrOutMaxLen,
    SQLSMALLINT* connStrOutLen,
    SQLUSMALLINT driverCompletion) {

  logMessage("SQLDriverConnect ", connStrIn, connStrInLen, connStrOut, connStrOutMaxLen, connStrOutLen, driverCompletion);

  if (connStrIn == null) {
    return SQL_SUCCESS;
  }

  if (connStrInLen == SQL_NTS) {
    connStrInLen = cast(SQLSMALLINT) strlen(cast(const char*)(connStrIn));
  }

  //Copy input string to output string
  if (connStrOut && connStrOutMaxLen > 0) {
    auto connStr = connStrIn[0 .. connStrInLen];
    auto numCopied = copyToBuffer(connStr, connStrOut, connStrOutMaxLen);

    if (connStrOutLen) {
      *connStrOutLen = numCopied;
    }

  }

  return SQL_SUCCESS;
}

///// SQLExecDirect /////

SQLRETURN SQLExecDirectW(
    SQLHSTMT hstmt,
    SQLWCHAR* szSqlStr,
    SQLINTEGER TextLength) {
  logMessage("SQLExecDirect ", szSqlStr, TextLength);
  return SQL_SUCCESS;
}

///// SQLAllocHandle /////

SQLRETURN SQLAllocHandle(
    SQLSMALLINT	handleType,
    SQLHANDLE handleParent,
    SQLHANDLE* newHandlePointer) {
  assert(newHandlePointer != null);

  switch (cast(SQL_HANDLE_TYPE) handleType) {
  case SQL_HANDLE_TYPE.DBC:
    break;
  case SQL_HANDLE_TYPE.DESC:
    break;
  case SQL_HANDLE_TYPE.ENV:
    break;
  case SQL_HANDLE_TYPE.SENV:
    break;
  case SQL_HANDLE_TYPE.STMT:
    *newHandlePointer = cast(void*) makeWithoutGC!OdbcStatement();
    break;
  default:
    return SQL_ERROR;
  }

  logMessage("SQLAllocHandle ", handleType, newHandlePointer, cast(SQL_HANDLE_TYPE) handleType);

  return SQL_SUCCESS;
}

///// SQLBindCol /////

SQLRETURN SQLBindCol(
    OdbcStatement statementHandle,
    SQLUSMALLINT columnNumber,
    SQLSMALLINT columnType,
    SQLPOINTER outputBuffer,
    SQLLEN bufferLength,
    SQLLEN* numberOfBytesWritten) {

  logMessage("SQLBindCol ", columnNumber, columnType, outputBuffer, bufferLength);
  assert(statementHandle !is null);
  with (statementHandle) {
    if (outputBuffer == null) {
      columnBindings.remove(columnNumber);
      return SQL_SUCCESS;
    }

    if (columnType == SQL_C_DEFAULT) {
      columnType = cast(SQLSMALLINT) SQL_TYPE_ID.SQL_UNKNOWN_TYPE;
    }
    if (columnType > SQL_TYPE_ID.max) {
      logMessage("SQLBindCol: Column type too big: ", columnType);
      return SQL_ERROR;
    }

    auto binding = ColumnBinding(numberOfBytesWritten);
    binding.columnType = cast(SQL_TYPE_ID)columnType;
    binding.outputBuffer = outputBuffer[0 .. max(0, bufferLength)];
    columnBindings[columnNumber] = binding;
  }

  return SQL_SUCCESS;
}

///// SQLCancel /////

SQLRETURN SQLCancel(SQLHSTMT StatementHandle) {
  logMessage("SQLCancel ");
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
  logMessage("SQLConnect ");
  return SQL_SUCCESS;
}

///// SQLDescribeCol /////

SQLRETURN SQLDescribeColW(
    SQLHSTMT hstmt,
    SQLUSMALLINT icol,
    SQLWCHAR* szColName,
    SQLSMALLINT cchColNameMax,
    SQLSMALLINT* pcchColName,
    SQLSMALLINT* pfSqlType,
    SQLULEN* pcbColDef,
    SQLSMALLINT* pibScale,
    SQLSMALLINT* pfNullable) {
  logMessage("SQLDescribeCol ", icol, szColName);
  return SQL_SUCCESS;
}

///// SQLDisconnect /////

SQLRETURN SQLDisconnect(SQLHDBC ConnectionHandle) {
  logMessage("SQLDisconnect ");
  return SQL_SUCCESS;
}

///// SQLExecute /////

SQLRETURN SQLExecute(SQLHSTMT StatementHandle) {
  logMessage("SQLExecute ");
  return SQL_SUCCESS;
}

///// SQLFetch /////

SQLRETURN SQLFetch(OdbcStatement statementHandle) {
  logMessage("SQLFetch ");

  assert(statementHandle !is null);
  with (statementHandle) {
    if (latestOdbcResult.empty) {
      return SQL_NO_DATA;
    }

    logMessage("SQLFetch -- Showing something!");
    try {
      auto row = latestOdbcResult.front;
      latestOdbcResult.popFront;
      foreach (col, binding; statementHandle.columnBindings) {
        if (col > latestOdbcResult.numberOfColumns) {
          return SQL_ERROR;
        }
        dispatchOnSQLType!(copyToOutput)(binding.columnType, row.dataAt(col), binding);
      }
    } catch(Error e) {
      logMessage("SQLFetch ERROR: ", e);
      assert(false);
    }
  }

  return SQL_SUCCESS;
}

///// SQLFreeStmt /////

SQLRETURN SQLFreeStmt(
    SQLHSTMT StatementHandle,
    SQLUSMALLINT Option) {

  logMessage("SQLFreeStmt ", Option);
  return SQL_SUCCESS;
}

///// SQLGetCursorName /////

SQLRETURN SQLGetCursorNameW(
    SQLHSTMT hstmt,
    SQLWCHAR* szCursor,
    SQLSMALLINT cchCursorMax,
    SQLSMALLINT* pcchCursor) {
  logMessage("SQLGetCursorName ", szCursor, cchCursorMax, pcchCursor);
  return SQL_SUCCESS;
}

///// SQLNumResultCols /////

SQLRETURN SQLNumResultCols(
    SQLHSTMT StatementHandle,
    SQLSMALLINT* ColumnCount) {
  logMessage("SQLNumResultCols ", ColumnCount);
  return SQL_SUCCESS;
}

///// SQLPrepare /////

SQLRETURN SQLPrepareW(
    SQLHSTMT hstmt,
    SQLWCHAR* szSqlStr,
    SQLINTEGER cchSqlStr) {
  logMessage("SQLPrepare ");
  return SQL_SUCCESS;
}

///// SQLRowCount /////

SQLRETURN SQLRowCount(
    SQLHSTMT StatementHandle,
    SQLLEN* RowCount) {
  logMessage("SQLRowCount ", RowCount);
  return SQL_SUCCESS;
}

///// SQLSetCursorName /////

SQLRETURN SQLSetCursorNameW(
    SQLHSTMT hstmt,
    SQLWCHAR* szCursor,
    SQLSMALLINT cchCursor) {
  logMessage("SQLSetCursorName ");
  return SQL_SUCCESS;
}

///// SQLColumns /////

SQLRETURN SQLColumnsW(
    SQLHSTMT hstmt,
    SQLWCHAR* szCatalogName,
    SQLSMALLINT cchCatalogName,
    SQLWCHAR* szSchemaName,
    SQLSMALLINT cchSchemaName,
    SQLWCHAR* szTableName,
    SQLSMALLINT cchTableName,
    SQLWCHAR* szColumnName,
    SQLSMALLINT cchColumnName) {
  logMessage("SQLColumns ");
  return SQL_SUCCESS;
}

///// SQLGetData /////

SQLRETURN SQLGetData(
    SQLHSTMT StatementHandle,
    SQLUSMALLINT ColumnNumber,
    SQLSMALLINT TargetType,
    SQLPOINTER TargetValue,
    SQLLEN BufferLength,
    SQLLEN* StrLen_or_IndPtr) {
  logMessage("SQLGetData ");
  return SQL_SUCCESS;
}

///// SQLGetInfo /////

SQLRETURN SQLGetInfoW(
    SQLHDBC ConnectionHandle,
    SQLUSMALLINT InfoType,
    SQLPOINTER InfoValue,
    SQLSMALLINT BufferLength,
    SQLSMALLINT* StringLengthPtr) {

  switch (InfoType) {

  case SQL_DRIVER_ODBC_VER: // 77
    //Latest version of ODBC is 3.8 (as of 6/19/14)
    *StringLengthPtr = copyToBuffer("03.80", InfoValue, BufferLength);
    break;
  case SQL_ASYNC_DBC_FUNCTIONS: //10023
    *cast(SQLUSMALLINT*)(InfoValue) = SQL_ASYNC_DBC_NOT_CAPABLE;
    break;
  case SQL_ASYNC_NOTIFICATION: //10025
    *cast(SQLUSMALLINT*)(InfoValue) = SQL_ASYNC_NOTIFICATION_NOT_CAPABLE;
    break;
  case SQL_CURSOR_COMMIT_BEHAVIOR: //23
    *cast(SQLUSMALLINT*)(InfoValue) = SQL_CB_DELETE;
    break;
  case SQL_CURSOR_ROLLBACK_BEHAVIOR: //24
    *cast(SQLUSMALLINT*)(InfoValue) = SQL_CB_DELETE;
    break;
  case SQL_GETDATA_EXTENSIONS: //81
    *cast(SQLUSMALLINT*)(InfoValue) = SQL_GD_ANY_ORDER;
    break;
  case SQL_DATA_SOURCE_NAME: //2
    *StringLengthPtr = copyToBuffer("", InfoValue, BufferLength);
    break;
  case SQL_MAX_CONCURRENT_ACTIVITIES: //1
    *cast(SQLUSMALLINT*)(InfoValue) = 1;
    break;
  case SQL_DATA_SOURCE_READ_ONLY: //25
    *StringLengthPtr = copyToBuffer("Y", InfoValue, BufferLength);
    break;
  case SQL_DRIVER_NAME: //6
    *StringLengthPtr = copyToBuffer("ODBCDRV0.dll", InfoValue, BufferLength);
    break;
  case SQL_SEARCH_PATTERN_ESCAPE: //14
    *StringLengthPtr = copyToBuffer("%", InfoValue, BufferLength);
    break;
  case SQL_CORRELATION_NAME: //74
    *cast(SQLUSMALLINT*)(InfoValue) = SQL_CN_ANY;
    break;
  case SQL_NON_NULLABLE_COLUMNS: //75
    *cast(SQLUSMALLINT*)(InfoValue) = SQL_NNC_NON_NULL;
    break;
  case SQL_CATALOG_NAME_SEPARATOR: //41
    *StringLengthPtr = copyToBuffer(".", InfoValue, BufferLength);
    break;
  case SQL_FILE_USAGE: //84
    *cast(SQLUSMALLINT*)(InfoValue) = SQL_FILE_USAGE;
    break;
  case SQL_CATALOG_TERM: //42
    *StringLengthPtr = copyToBuffer("catalog", InfoValue, BufferLength);
    break;
  case SQL_DATABASE_NAME: //16
    *StringLengthPtr = copyToBuffer("dbname", InfoValue, BufferLength);
    logMessage("dbname", InfoType, InfoValue, BufferLength, *StringLengthPtr);
    break;
  case SQL_MAX_SCHEMA_NAME_LEN: //32
    *cast(SQLUSMALLINT*)(InfoValue) = 0;
    break;
  case SQL_IDENTIFIER_QUOTE_CHAR: //29
    *StringLengthPtr = copyToBuffer("\"", InfoValue, BufferLength);
    break;
  default:
    logMessage("SQLGetInfo ", InfoType, InfoValue, BufferLength, " ");
  } //switch
  return SQL_SUCCESS;
}

///// SQLGetTypeInfo /////
SQLRETURN SQLGetTypeInfoW(
    OdbcStatement statementHandle,
    SQLSMALLINT dataType) {
  logMessage("SQLGetTypeInfo ", dataType);

  with (statementHandle) {
    switch(cast(SQL_TYPE_ID) dataType) {
    case SQL_TYPE_ID.SQL_UNKNOWN_TYPE:
    case SQL_TYPE_ID.SQL_VARCHAR:
      latestOdbcResult = new TypeInfoResult!VarcharTypeInfoResultRow();
    default:
      logMessage("Unexpected type in GetTypeInfo");
    }
  }

  return SQL_SUCCESS;
}

///// SQLParamData /////

SQLRETURN SQLParamData(
    SQLHSTMT StatementHandle,
    SQLPOINTER *Value) {
  logMessage("SQLParamData ");
  return SQL_SUCCESS;
}

///// SQLPutData /////

SQLRETURN SQLPutData(
    SQLHSTMT StatementHandle,
    SQLPOINTER Data,
    SQLLEN StrLen_or_Ind) {
  logMessage("SQLPutData ");
  return SQL_SUCCESS;
}

///// SQLSpecialColumns /////


SQLRETURN SQLSpecialColumnsW(
    SQLHSTMT hstmt,
    SQLUSMALLINT fColType,
    SQLWCHAR* szCatalogName,
    SQLSMALLINT cchCatalogName,
    SQLWCHAR* szSchemaName,
    SQLSMALLINT cchSchemaName,
    SQLWCHAR* szTableName,
    SQLSMALLINT cchTableName,
    SQLUSMALLINT fScope,
    SQLUSMALLINT fNullable) {
  logMessage("SQLSpecialColumns ");
  return SQL_SUCCESS;
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
  logMessage("SQLStatistics ");
  return SQL_SUCCESS;
}

///// SQLTables /////

SQLRETURN SQLTablesW(
    SQLHSTMT hstmt,
    SQLWCHAR* szCatalogName,
    SQLSMALLINT cchCatalogName,
    SQLWCHAR* szSchemaName,
    SQLSMALLINT cchSchemaName,
    SQLWCHAR* szTableName,
    SQLSMALLINT cchTableName,
    SQLWCHAR* szTableType,
    SQLSMALLINT cchTableType) {

  logMessage("SQLTablesW ");
  return SQL_SUCCESS;
}

///// SQLBrowseConnect /////

SQLRETURN SQLBrowseConnectW(
    SQLHDBC hdbc,
    SQLWCHAR* szConnStrIn,
    SQLSMALLINT cchConnStrIn,
    SQLWCHAR* szConnStrOut,
    SQLSMALLINT cchConnStrOutMax,
    SQLSMALLINT* pcchConnStrOut) {
  logMessage("SQLBrowseConnect ");
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
  logMessage("SQLColumnPrivileges ");
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
  logMessage("SQLDescribeParam ");
  return SQL_SUCCESS;
}

///// SQLExtendedFetch /////

SQLRETURN SQLExtendedFetch(
    SQLHSTMT hstmt,
    SQLUSMALLINT fFetchType,
    SQLLEN irow,
    SQLULEN* pcrow,
    SQLUSMALLINT* rgfRowStatus) {
  logMessage("SQLExtendedFetch ");
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
  logMessage("SQLForeignKeys ");
  return SQL_SUCCESS;
}

///// SQLMoreResults /////
SQLRETURN SQLMoreResults(SQLHSTMT hstmt) {
  logMessage("SQLMoreResults ");
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
  logMessage("SQLNativeSql ");
  return SQL_SUCCESS;
}

///// SQLNumParams /////

SQLRETURN SQLNumParams(
    SQLHSTMT hstmt,
    SQLSMALLINT* pcpar) {
  logMessage("SQLNumParams ");
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
  logMessage("SQLPrimaryKeys ");
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
  logMessage("SQLProcedureColumns ");
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
  logMessage("SQLProcedures ");
  return SQL_SUCCESS;
}

///// SQLSetPos /////

SQLRETURN SQLSetPos(
    SQLHSTMT hstmt,
    SQLSETPOSIROW irow,
    SQLUSMALLINT fOption,
    SQLUSMALLINT       fLock) {
  logMessage("SQLSetPos ");
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
  logMessage("SQLTablePrivileges ");
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
  logMessage("SQLBindParameter ");
  return SQL_SUCCESS;
}

///// SQLCloseCursor /////

SQLRETURN SQLCloseCursor(SQLHSTMT StatementHandle) {
  logMessage("SQLCloseCursor ");
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
  logMessage("SQLColAttribute ");
  return SQL_SUCCESS;
}

///// SQLCopyDesc /////

SQLRETURN SQLCopyDesc(
    SQLHDESC SourceDescHandle,
    SQLHDESC TargetDescHandle) {
  logMessage("SQLCopyDesc ");
  return SQL_SUCCESS;
}

///// SQLEndTran /////
SQLRETURN SQLEndTran(
    SQLSMALLINT HandleType,
    SQLHANDLE Handle,
    SQLSMALLINT CompletionType) {
  logMessage("SQLEndTran ");
  return SQL_SUCCESS;
}

///// SQLFetchScroll /////

SQLRETURN SQLFetchScroll(
    SQLHSTMT StatementHandle,
    SQLSMALLINT FetchOrientation,
    SQLLEN FetchOffset) {
  logMessage("SQLFetchScroll ");
  return SQL_SUCCESS;
}

///// SQLFreeHandle /////

SQLRETURN SQLFreeHandle(SQLSMALLINT HandleType, SQLHANDLE Handle) {
  logMessage("SQLFreeHandle ");
  return SQL_SUCCESS;
}

///// SQLGetConnectAttr /////

SQLRETURN SQLGetConnectAttrW(
    SQLHDBC ConnectionHandle,
    SQLINTEGER Attribute,
    SQLPOINTER Value,
    SQLINTEGER BufferLength,
    SQLINTEGER* StringLengthPtr) {
  logMessage("SQLGetConnectAttr ");
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
  logMessage("SQLGetDescField ");
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
  logMessage("SQLGetDescRec ");
  return SQL_SUCCESS;
}

///// SQLGetDiagField /////

SQLRETURN SQLGetDiagFieldW(
    SQLSMALLINT HandleType,
    SQLHANDLE Handle,
    SQLSMALLINT RecNumber,
    SQLSMALLINT DiagIdentifier,
    SQLPOINTER DiagInfo,
    SQLSMALLINT BufferLength,
    SQLSMALLINT* StringLength) {
  if (DiagInfo) {
    (cast(char*)DiagInfo)[0] = '\0';
  }
  if (StringLength) {
    *StringLength = 0;
  }
  logMessage("SQLGetDiagField ", RecNumber, DiagIdentifier, DiagInfo, BufferLength);
  return SQL_NO_DATA;
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
  logMessage("SQLGetDiagRec ", iRecord, pfNativeError, (szErrorMsg == null), cchErrorMsgMax);
  return SQL_NO_DATA;
}

///// SQLGetEnvAttr /////

SQLRETURN SQLGetEnvAttr(
    SQLHENV EnvironmentHandle,
    SQLINTEGER Attribute,
    SQLPOINTER Value,
    SQLINTEGER BufferLength,
    SQLINTEGER* StringLength) {
  logMessage("SQLGetEnvAttr ");
  return SQL_SUCCESS;
}

///// SQLGetStmtAttr /////

SQLRETURN SQLGetStmtAttrW(
    SQLHSTMT StatementHandle,
    SQLINTEGER Attribute,
    SQLPOINTER Value,
    SQLINTEGER BufferLength,
    SQLINTEGER* StringLength) {
  switch (Attribute) {
  case SQL_ATTR_APP_ROW_DESC:
    Value = null;
    break;
  case SQL_ATTR_APP_PARAM_DESC:
    Value = null;
    break;
  case SQL_ATTR_IMP_ROW_DESC:
    Value = null;
    break;
  case SQL_ATTR_IMP_PARAM_DESC:
    Value = null;
    break;
  default:
    return SQL_ERROR;
  }
  logMessage("SQLGetStmtAttr ", Attribute, Value, BufferLength);
  return SQL_SUCCESS;
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
  logMessage("SQLSetConnectAttr ", Attribute, Value, StringLength);
  return SQL_SUCCESS;
}

///// SQLSetDescField /////

SQLRETURN SQLSetDescFieldW(
    SQLHDESC DescriptorHandle,
    SQLSMALLINT RecNumber,
    SQLSMALLINT FieldIdentifier,
    SQLPOINTER Value,
    SQLINTEGER BufferLength) {
  logMessage("SQLSetDescField ");
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
  logMessage("SQLSetDescRec ");
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

  logMessage("SQLSetEnvAttr ", Attribute, Value, StringLength);
  return SQL_SUCCESS;
}

///// SQLSetStmtAttr /////

SQLRETURN SQLSetStmtAttrW(
    SQLHSTMT StatementHandle,
    SQLINTEGER Attribute,
    SQLPOINTER Value,
    SQLINTEGER StringLength) {
  logMessage("SQLSetStmtAttr ");
  return SQL_SUCCESS;
}


///// SQLBulkOperations /////

SQLRETURN SQLBulkOperations(
    SQLHSTMT StatementHandle,
    SQLSMALLINT Operation) {
  logMessage("SQLBulkOperations ");
  return SQL_SUCCESS;
}
