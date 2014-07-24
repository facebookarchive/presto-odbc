# Driver Conformance to the ODBC Standard

## Near-fully implemented functions:
* SQLBindCol
* SQLColumns
* SQLExecDirect
* SQLExecute
* SQLFetch
* SQLGetInfo
* SQLGetTypeInfo
* SQLNumResultCols
* SQLPrepare
* SQLTables
* SQLBindParameter
* SQLColAttribute
* SQLSpecialColumns
* SQLDescribeCol
* SQLRowCount
* SQLGetData
* SQLForeignKeys
* SQLPrimaryKeys
* SQLNativeSql

## Partially-implemented or mocked functions:
* SQLAllocHandle
* SQLConnect
* SQLDisconnect
* SQLDriverConnect
* SQLFreeHandle
* SQLFreeStmt
* SQLGetDiagField
* SQLGetDiagRec
* SQLGetConnectAttr
* SQLGetStmtAttr
* SQLGetEnvAttr
* SQLSetConnectAttr
* SQLSetEnvAttr
* SQLSetStmtAttr
* SQLEndTran

## Unimplemented Functions:

These functions are unimplemented because our target ODBC applications have not been proven to exercise them.

### Necessary for the "Core" conformance level of ODBC

Data Fetching:
* SQLStatistics

Cursors:
* SQLCloseCursor
* SQLGetCursorName
* SQLSetCursorName
* SQLFetchScroll (Tableau's data sheet says it might need this)

Parameters:
* SQLNumParams
* SQLParamData
* SQLPutData
* SQLCancel (Tableau's data sheet says it might need this)

Descriptor Fields (see [handles.d](driver/handles.d)):
* SQLCopyDesc
* SQLGetDescField
* SQLGetDescRec
* SQLSetDescRec
* SQLSetDescField

### Necessary for "Level 1" conformance:

* SQLBrowseConnect
* SQLBulkOperations
* SQLMoreResults
* SQLProcedureColumns
* SQLProcedures
* SQLSetPos

### Necessary for "Level 2" conformance:

* SQLColumnPrivileges
* SQLDescribeParam
* SQLTablePrivileges
