
import core.runtime;

import std.algorithm;
import std.stdio : writeln;

import std.c.stdio;
import std.c.stdlib;
import std.c.string;
import std.c.windows.windows;

import sqlext;
import odbcinst;

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
      MessageBoxW(GetForegroundWindow(),
          "ODBCDRV0 loaded by application or driver manager", "Successful Start", MB_OK);
    } else if (fdwReason == DLL_PROCESS_DETACH) {   // DLL is being unloaded
      Runtime.terminate();
    }

    return TRUE;
  }
}

extern(System):


///// SQLDriverConnect /////

SQLRETURN SQLDriverConnect(
    SQLHDBC hdbc,
    SQLHWND hwnd,
    SQLWCHAR* connStrIn,
    SQLSMALLINT connStrInLen,
    SQLWCHAR* connStrOut,
    SQLSMALLINT connStrOutMaxLen,
    SQLSMALLINT* connStrOutLen,
    SQLUSMALLINT driverCompletion) {

  if (connStrIn == null) {
    return SQL_SUCCESS;
  }

  if (connStrInLen == SQL_NTS) {
    connStrInLen = cast(SQLSMALLINT) strlen(cast(const char*)(connStrIn));
  }

  // copy in conn string to out string
  if (connStrOut && connStrOutMaxLen > 0) {
    auto connStr = makeDString(connStrIn, connStrInLen);
    auto numCopied = copyToBuffer(connStr, connStrOut, connStrOutMaxLen);

    if (connStrOutLen) {
      *connStrOutLen = numCopied;
    }

  }

  return SQL_SUCCESS;
}

void showCalled(Ts...)(Ts vs) if (vs.length > 0) {
  import std.conv : wtext;
  import std.algorithm : map, joiner, equal;

  wstring[] rngOfVs;
  foreach (v; vs) {
    rngOfVs ~= wtext(v);
  }

  auto message = joiner(rngOfVs, " ");
  MessageBoxW(GetForegroundWindow(), (wtext(message) ~ '\0').ptr, "Presto ODBC Driver"w.ptr, MB_OK);
}

unittest {
  showCalled("Hi", "there" , 5);
}

///// SQLExecDirect /////

SQLRETURN SQLExecDirectW(
    SQLHSTMT hstmt,
    SQLWCHAR* szSqlStr,
    SQLINTEGER TextLength) {
  showCalled("SQLExecDirect ", szSqlStr, TextLength);
  return SQL_SUCCESS;
}

///// SQLAllocHandle /////

SQLRETURN SQLAllocHandle(
    SQLSMALLINT	HandleType,
    SQLHANDLE HandleParent,
    SQLHANDLE* NewHandlePointer) {

  string type;
  switch (HandleType) {
  case SQL_HANDLE_DBC:
    type = "SQL_HANDLE_DBC";
    break;
  case SQL_HANDLE_DESC:
    type = "SQL_HANDLE_DESC";
    break;
  case SQL_HANDLE_ENV:
    type = "SQL_HANDLE_ENV";
    break;
  case SQL_HANDLE_SENV:
    type = "SQL_HANDLE_SENV";
    break;
  case SQL_HANDLE_STMT:
    type = "SQL_HANDLE_STMT";
    break;
  default:
    return SQL_ERROR;
  }
  showCalled("SQLAllocHandle ", HandleType, NewHandlePointer, type);

  return SQL_SUCCESS;
}

///// SQLBindCol /////

SQLRETURN SQLBindCol(
    SQLHSTMT StatementHandle,
    SQLUSMALLINT ColumnNumber,
    SQLSMALLINT TargetType,
    SQLPOINTER TargetValue,
    SQLLEN BufferLength,
    SQLLEN* StrLen_or_Ind) {
  showCalled("SQLBindCol ", ColumnNumber, TargetType, TargetValue, BufferLength);
  return SQL_SUCCESS;
}

///// SQLCancel /////

SQLRETURN SQLCancel(SQLHSTMT StatementHandle) {
  showCalled("SQLCancel ");
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
  showCalled("SQLConnect ");
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
  showCalled("SQLDescribeCol ", icol, szColName);
  return SQL_SUCCESS;
}

///// SQLDisconnect /////

SQLRETURN SQLDisconnect(SQLHDBC ConnectionHandle) {
  showCalled("SQLDisconnect ");
  return SQL_SUCCESS;
}

///// SQLExecute /////

SQLRETURN SQLExecute(SQLHSTMT StatementHandle) {
  showCalled("SQLExecute ");
  return SQL_SUCCESS;
}

///// SQLFetch /////

SQLRETURN SQLFetch(HSTMT StatementHandle) {
  showCalled("SQLFetch ");
  return SQL_NO_DATA;
}

///// SQLFreeStmt /////

SQLRETURN SQLFreeStmt(
    SQLHSTMT StatementHandle,
    SQLUSMALLINT Option) {
  showCalled("SQLFreeStmt ");
  return SQL_SUCCESS;
}

///// SQLGetCursorName /////

SQLRETURN SQLGetCursorNameW(
    SQLHSTMT hstmt,
    SQLWCHAR* szCursor,
    SQLSMALLINT cchCursorMax,
    SQLSMALLINT* pcchCursor) {
  showCalled("SQLGetCursorName ", szCursor, cchCursorMax, pcchCursor);
  return SQL_SUCCESS;
}

///// SQLNumResultCols /////

SQLRETURN SQLNumResultCols(
    SQLHSTMT StatementHandle,
    SQLSMALLINT* ColumnCount) {
  showCalled("SQLNumResultCols ", ColumnCount);
  return SQL_SUCCESS;
}

///// SQLPrepare /////

SQLRETURN SQLPrepareW(
    SQLHSTMT hstmt,
    SQLWCHAR* szSqlStr,
    SQLINTEGER cchSqlStr) {
  showCalled("SQLPrepare ");
  return SQL_SUCCESS;
}

///// SQLRowCount /////

SQLRETURN SQLRowCount(
    SQLHSTMT StatementHandle,
    SQLLEN* RowCount) {
  showCalled("SQLRowCount ", RowCount);
  return SQL_SUCCESS;
}

///// SQLSetCursorName /////

SQLRETURN SQLSetCursorNameW(
    SQLHSTMT hstmt,
    SQLWCHAR* szCursor,
    SQLSMALLINT cchCursor) {
  showCalled("SQLSetCursorName ");
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
  showCalled("SQLColumns ");
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
  showCalled("SQLGetData ");
  return SQL_SUCCESS;
}

///// SQLGetInfo /////
import std.traits;
auto makeDString(C, N)(const(C)* src, N length) if (isIntegral!N && isSomeChar!C) {
  import std.array : appender;
  alias StringType = immutable(C)[];

  auto builder = appender!StringType;
  builder.reserve(length);
  foreach(i; 0 .. length) {
    assert(src[i] != '\0');
    builder ~= src[i];
  }
  return builder.data();
}

SQLSMALLINT copyToBuffer(S)(S src, SQLPOINTER dest, SQLSMALLINT destSize) if (isSomeString!S) {
  const(void)[] from = cast(void[]) src;
  const numCopied = cast(SQLSMALLINT) min(from.length, destSize - 1);
  from = from[0 .. numCopied];
  void[] to = dest[0 .. numCopied];
  to[] = from[];
  (cast(ubyte*) dest)[numCopied] = 0;
  return numCopied;
}

SQLRETURN SQLGetInfoW(
    SQLHDBC ConnectionHandle,
    SQLUSMALLINT InfoType,
    SQLPOINTER InfoValue,
    SQLSMALLINT BufferLength,
    SQLSMALLINT* StringLengthPtr) {

  switch (InfoType) {

  case SQL_DRIVER_ODBC_VER: { // 77
    *StringLengthPtr = copyToBuffer("03.80", InfoValue, BufferLength);
    break;
  } case SQL_ASYNC_DBC_FUNCTIONS: //10023
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
  case SQL_DATA_SOURCE_NAME: { //2
    *StringLengthPtr = copyToBuffer("", InfoValue, BufferLength);
    break;
  } case SQL_MAX_CONCURRENT_ACTIVITIES: //1
    *cast(SQLUSMALLINT*)(InfoValue) = 1;
    break;
  case SQL_DATA_SOURCE_READ_ONLY: { //25
    *StringLengthPtr = copyToBuffer("Y", InfoValue, BufferLength);
    break;
  } case SQL_DRIVER_NAME: { //6
    *StringLengthPtr = copyToBuffer("ODBCDRV0.dll", InfoValue, BufferLength);
    break;
  } case SQL_SEARCH_PATTERN_ESCAPE: { //14
    *StringLengthPtr = copyToBuffer("%", InfoValue, BufferLength);
    break;
  } case SQL_CORRELATION_NAME: { //74
    *cast(SQLUSMALLINT*)(InfoValue) = SQL_CN_ANY;
    break;
  } case SQL_NON_NULLABLE_COLUMNS: { //75
    *cast(SQLUSMALLINT*)(InfoValue) = SQL_NNC_NON_NULL;
    break;
  } case SQL_CATALOG_NAME_SEPARATOR: { //41
    *StringLengthPtr = copyToBuffer(".", InfoValue, BufferLength);
    break;
  } case SQL_FILE_USAGE: { //84
    *cast(SQLUSMALLINT*)(InfoValue) = SQL_FILE_USAGE;
    break;
  } case SQL_CATALOG_TERM: { //42
    *StringLengthPtr = copyToBuffer("catalog", InfoValue, BufferLength);
    break;
  } case SQL_DATABASE_NAME: { //16
    *StringLengthPtr = copyToBuffer("dbname", InfoValue, BufferLength);
    showCalled("dbname", InfoType, InfoValue, BufferLength, *StringLengthPtr);
    break;
  } case SQL_MAX_SCHEMA_NAME_LEN: { //32
    *cast(SQLUSMALLINT*)(InfoValue) = 0;
    break;
  } case SQL_IDENTIFIER_QUOTE_CHAR: { //29
    *StringLengthPtr = copyToBuffer("\"", InfoValue, BufferLength);
    break;
  }
  default: {
    showCalled("SQLGetInfo ", InfoType, InfoValue, BufferLength, " ");
  }
  } //switch
  return SQL_SUCCESS;
}

///// SQLGetTypeInfo /////
SQLRETURN SQLGetTypeInfoW(
    SQLHSTMT StatementHandle,
    SQLSMALLINT DataType) {
  showCalled("SQLGetTypeInfo ", DataType);
  return SQL_SUCCESS;
}

///// SQLParamData /////

SQLRETURN SQLParamData(
    SQLHSTMT StatementHandle,
    SQLPOINTER *Value) {
  showCalled("SQLParamData ");
  return SQL_SUCCESS;
}

///// SQLPutData /////

SQLRETURN SQLPutData(
    SQLHSTMT StatementHandle,
    SQLPOINTER Data,
    SQLLEN StrLen_or_Ind) {
  showCalled("SQLPutData ");
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
  showCalled("SQLSpecialColumns ");
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
  showCalled("SQLStatistics ");
  return SQL_SUCCESS;
}

///// SQLTables /////

const(char)* showIfNotNull(SQLWCHAR* ptr) {
  if (ptr != null) {
    return cast(const char*)(ptr);
  }
  enum const(char)* ret = "null".ptr;
  return ret;
}

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
  showCalled("SQLTablesW ");
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
  showCalled("SQLBrowseConnect ");
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
  showCalled("SQLColumnPrivileges ");
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
  showCalled("SQLDescribeParam ");
  return SQL_SUCCESS;
}

///// SQLExtendedFetch /////

SQLRETURN SQLExtendedFetch(
    SQLHSTMT hstmt,
    SQLUSMALLINT fFetchType,
    SQLLEN irow,
    SQLULEN* pcrow,
    SQLUSMALLINT* rgfRowStatus) {
  showCalled("SQLExtendedFetch ");
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
  showCalled("SQLForeignKeys ");
  return SQL_SUCCESS;
}

///// SQLMoreResults /////
SQLRETURN SQLMoreResults(SQLHSTMT hstmt) {
  showCalled("SQLMoreResults ");
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
  showCalled("SQLNativeSql ");
  return SQL_SUCCESS;
}

///// SQLNumParams /////

SQLRETURN SQLNumParams(
    SQLHSTMT hstmt,
    SQLSMALLINT* pcpar) {
  showCalled("SQLNumParams ");
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
  showCalled("SQLPrimaryKeys ");
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
  showCalled("SQLProcedureColumns ");
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
  showCalled("SQLProcedures ");
  return SQL_SUCCESS;
}

///// SQLSetPos /////

SQLRETURN SQLSetPos(
    SQLHSTMT hstmt,
    SQLSETPOSIROW irow,
    SQLUSMALLINT fOption,
    SQLUSMALLINT       fLock) {
  showCalled("SQLSetPos ");
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
  showCalled("SQLTablePrivileges ");
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
  showCalled("SQLBindParameter ");
  return SQL_SUCCESS;
}

///// SQLCloseCursor /////

SQLRETURN SQLCloseCursor(SQLHSTMT StatementHandle) {
  showCalled("SQLCloseCursor ");
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
  showCalled("SQLColAttribute ");
  return SQL_SUCCESS;
}

///// SQLCopyDesc /////

SQLRETURN SQLCopyDesc(
    SQLHDESC SourceDescHandle,
    SQLHDESC TargetDescHandle) {
  showCalled("SQLCopyDesc ");
  return SQL_SUCCESS;
}

///// SQLEndTran /////
SQLRETURN SQLEndTran(
    SQLSMALLINT HandleType,
    SQLHANDLE Handle,
    SQLSMALLINT CompletionType) {
  showCalled("SQLEndTran ");
  return SQL_SUCCESS;
}

///// SQLFetchScroll /////

SQLRETURN SQLFetchScroll(
    SQLHSTMT StatementHandle,
    SQLSMALLINT FetchOrientation,
    SQLLEN FetchOffset) {
  showCalled("SQLFetchScroll ");
  return SQL_SUCCESS;
}

///// SQLFreeHandle /////

SQLRETURN SQLFreeHandle(SQLSMALLINT HandleType, SQLHANDLE Handle) {
  showCalled("SQLFreeHandle ");
  return SQL_SUCCESS;
}

///// SQLGetConnectAttr /////

SQLRETURN SQLGetConnectAttrW(
    SQLHDBC ConnectionHandle,
    SQLINTEGER Attribute,
    SQLPOINTER Value,
    SQLINTEGER BufferLength,
    SQLINTEGER* StringLengthPtr) {
  showCalled("SQLGetConnectAttr ");
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
  showCalled("SQLGetDescField ");
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
  showCalled("SQLGetDescRec ");
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
  showCalled("SQLGetDiagField ", RecNumber, DiagIdentifier, DiagInfo, BufferLength);
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
  showCalled("SQLGetDiagRec ", iRecord, pfNativeError, (szErrorMsg == null), cchErrorMsgMax);
  return SQL_NO_DATA;
}

///// SQLGetEnvAttr /////

SQLRETURN SQLGetEnvAttr(
    SQLHENV EnvironmentHandle,
    SQLINTEGER Attribute,
    SQLPOINTER Value,
    SQLINTEGER BufferLength,
    SQLINTEGER* StringLength) {
  showCalled("SQLGetEnvAttr ");
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
  showCalled("SQLGetStmtAttr ", Attribute, Value, BufferLength);
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
  showCalled("SQLSetConnectAttr ", Attribute, Value, StringLength);
  return SQL_SUCCESS;
}

///// SQLSetDescField /////

SQLRETURN SQLSetDescFieldW(
    SQLHDESC DescriptorHandle,
    SQLSMALLINT RecNumber,
    SQLSMALLINT FieldIdentifier,
    SQLPOINTER Value,
    SQLINTEGER BufferLength) {
  showCalled("SQLSetDescField ");
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
  showCalled("SQLSetDescRec ");
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

  showCalled("SQLSetEnvAttr ", Attribute, Value, StringLength);
  return SQL_SUCCESS;
}

///// SQLSetStmtAttr /////

SQLRETURN SQLSetStmtAttrW(
    SQLHSTMT StatementHandle,
    SQLINTEGER Attribute,
    SQLPOINTER Value,
    SQLINTEGER StringLength) {
  showCalled("SQLSetStmtAttr ");
  return SQL_SUCCESS;
}


///// SQLBulkOperations /////

SQLRETURN SQLBulkOperations(
    SQLHSTMT StatementHandle,
    SQLSMALLINT Operation) {
  showCalled("SQLBulkOperations ");
  return SQL_SUCCESS;
}
