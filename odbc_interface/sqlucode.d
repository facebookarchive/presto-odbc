/*
 *  Copyright (C) 1996-2014 by OpenLink Software <iodbc@openlinksw.com>
 *  All Rights Reserved.
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions
 *  are met:
 *
 *  1. Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *  2. Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in
 *     the documentation and/or other materials provided with the
 *     distribution.
 *  3. Neither the name of OpenLink Software Inc. nor the names of its
 *     contributors may be used to endorse or promote products derived
 *     from this software without specific prior written permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 *  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL OPENLINK OR
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
module odbc_interface.sqlucode;

import odbc_interface.sqlext;

//Size of SQLSTATE - Unicode
enum SQL_SQLSTATE_SIZEW  = 10;

// Mapping aliases for Unicode
version(UNICODE) {
    alias SQLColAttribute = SQLColAttributeW;
    alias SQLColAttributes = SQLColAttributesW;
    alias SQLConnect = SQLConnectW;
    alias SQLDescribeCol = SQLDescribeColW;
    alias SQLError = SQLErrorW;
    alias SQLExecDirect = SQLExecDirectW;
    alias SQLGetConnectAttr = SQLGetConnectAttrW;
    alias SQLGetCursorName = SQLGetCursorNameW;
    alias SQLGetDescField = SQLGetDescFieldW;
    alias SQLGetDescRec = SQLGetDescRecW;
    alias SQLGetDiagField = SQLGetDiagFieldW;
    alias SQLGetDiagRec = SQLGetDiagRecW;
    alias SQLPrepare = SQLPrepareW;
    alias SQLSetConnectAttr = SQLSetConnectAttrW;
    alias SQLSetCursorName = SQLSetCursorNameW;
    alias SQLSetDescField = SQLSetDescFieldW;
    alias SQLSetStmtAttr = SQLSetStmtAttrW;
    alias SQLGetStmtAttr = SQLGetStmtAttrW;
    alias SQLColumns = SQLColumnsW;
    alias SQLGetConnectOption = SQLGetConnectOptionW;
    alias SQLGetInfo = SQLGetInfoW;
    alias SQLGetTypeInfo = SQLGetTypeInfoW;
    alias SQLSetConnectOption = SQLSetConnectOptionW;
    alias SQLSpecialColumns = SQLSpecialColumnsW;
    alias SQLStatistics = SQLStatisticsW;
    alias SQLTables = SQLTablesW;
    alias SQLDataSources = SQLDataSourcesW;
    alias SQLDriverConnect = SQLDriverConnectW;
    alias SQLBrowseConnect = SQLBrowseConnectW;
    alias SQLColumnPrivileges = SQLColumnPrivilegesW;
    alias SQLForeignKeys = SQLForeignKeysW;
    alias SQLNativeSql = SQLNativeSqlW;
    alias SQLPrimaryKeys = SQLPrimaryKeysW;
    alias SQLProcedureColumns = SQLProcedureColumnsW;
    alias SQLProcedures = SQLProceduresW;
    alias SQLTablePrivileges = SQLTablePrivilegesW;
    alias SQLDrivers = SQLDriversW;
}

extern(System):

//Function Prototypes - Unicode
SQLRETURN SQLColAttributeW(
    SQLHSTMT hstmt,
    SQLUSMALLINT iCol,
    SQLUSMALLINT iField,
    SQLPOINTER pCharAttr,
    SQLSMALLINT cbDescMax,
    SQLSMALLINT *pcbCharAttr,
    SQLLEN *pNumAttr);

SQLRETURN SQLColAttributesW(
    SQLHSTMT hstmt,
    SQLUSMALLINT icol,
    SQLUSMALLINT fDescType,
    SQLPOINTER rgbDesc,
    SQLSMALLINT cbDescMax,
    SQLSMALLINT *pcbDesc,
    SQLLEN *pfDesc);

SQLRETURN SQLConnectW(
    SQLHDBC hdbc,
    SQLWCHAR* szDSN,
    SQLSMALLINT cbDSN,
    SQLWCHAR* szUID,
    SQLSMALLINT cbUID,
    SQLWCHAR* szAuthStr,
    SQLSMALLINT cbAuthStr);

SQLRETURN SQLDescribeColW(
    SQLHSTMT hstmt,
    SQLUSMALLINT icol,
    SQLWCHAR* szColName,
    SQLSMALLINT cbColNameMax,
    SQLSMALLINT* pcbColName,
    SQLSMALLINT* pfSqlType,
    SQLULEN* pcbColDef,
    SQLSMALLINT* pibScale,
    SQLSMALLINT* pfNullable);

SQLRETURN SQLErrorW(
    SQLHENV henv,
    SQLHDBC hdbc,
    SQLHSTMT hstmt,
    SQLWCHAR* szSqlState,
    SQLINTEGER* pfNativeError,
    SQLWCHAR* szErrorMsg,
    SQLSMALLINT cbErrorMsgMax,
    SQLSMALLINT* pcbErrorMsg);

SQLRETURN SQLExecDirectW(
    SQLHSTMT hstmt,
    SQLWCHAR* szSqlStr,
    SQLINTEGER TextLength);

SQLRETURN SQLGetConnectAttrW(
    SQLHDBC hdbc,
    SQLINTEGER fAttribute,
    SQLPOINTER rgbValue,
    SQLINTEGER cbValueMax,
    SQLINTEGER* pcbValue);

SQLRETURN SQLGetCursorNameW(
    SQLHSTMT hstmt,
    SQLWCHAR* szCursor,
    SQLSMALLINT cbCursorMax,
    SQLSMALLINT* pcbCursor);

SQLRETURN SQLSetDescFieldW(
    SQLHDESC DescriptorHandle,
    SQLSMALLINT RecNumber,
    SQLSMALLINT FieldIdentifier,
    SQLPOINTER Value,
    SQLINTEGER BufferLength);

SQLRETURN SQLSetDescFieldA(
    SQLHDESC DescriptorHandle,
    SQLSMALLINT RecNumber,
    SQLSMALLINT FieldIdentifier,
    SQLPOINTER Value,
    SQLINTEGER BufferLength);

SQLRETURN SQLGetDescFieldW(
    SQLHDESC hdesc,
    SQLSMALLINT iRecord,
    SQLSMALLINT iField,
    SQLPOINTER rgbValue,
    SQLINTEGER cbValueMax,
    SQLINTEGER* pcbValue);

SQLRETURN SQLGetDescRecW(
    SQLHDESC hdesc,
    SQLSMALLINT iRecord,
    SQLWCHAR* szName,
    SQLSMALLINT cbNameMax,
    SQLSMALLINT* pcbName,
    SQLSMALLINT* pfType,
    SQLSMALLINT* pfSubType,
    SQLLEN* pLength,
    SQLSMALLINT* pPrecision,
    SQLSMALLINT* pScale,
    SQLSMALLINT* pNullable);

SQLRETURN SQLGetDiagFieldW
    (
        SQLSMALLINT fHandleType,
        SQLHANDLE handle,
        SQLSMALLINT iRecord,
        SQLSMALLINT fDiagField,
        SQLPOINTER rgbDiagInfo,
        SQLSMALLINT cbBufferLength,
        SQLSMALLINT* pcbDiagInfo);

SQLRETURN SQLGetDiagRecW(
    SQLSMALLINT fHandleType,
    SQLHANDLE handle,
    SQLSMALLINT iRecord,
    SQLWCHAR* szSqlState,
    SQLINTEGER* pfNativeError,
    SQLWCHAR* szErrorMsg,
    SQLSMALLINT cbErrorMsgMax,
    SQLSMALLINT* pcbErrorMsg);

SQLRETURN SQLPrepareW(
    SQLHSTMT hstmt,
    SQLWCHAR* szSqlStr,
    SQLINTEGER cbSqlStr);

SQLRETURN SQLSetConnectAttrW(
    SQLHDBC hdbc,
    SQLINTEGER fAttribute,
    SQLPOINTER rgbValue,
    SQLINTEGER cbValue);

SQLRETURN SQLSetCursorNameW(
    SQLHSTMT hstmt,
    SQLWCHAR* szCursor,
    SQLSMALLINT cbCursor);

SQLRETURN SQLColumnsW(
    SQLHSTMT hstmt,
    SQLWCHAR* szCatalogName,
    SQLSMALLINT cbCatalogName,
    SQLWCHAR* szSchemaName,
    SQLSMALLINT cbSchemaName,
    SQLWCHAR* szTableName,
    SQLSMALLINT cbTableName,
    SQLWCHAR* szColumnName,
    SQLSMALLINT cbColumnName);

SQLRETURN SQLGetConnectOptionW(
    SQLHDBC hdbc,
    SQLUSMALLINT fOption,
    SQLPOINTER pvParam);

SQLRETURN SQLGetInfoW(
    SQLHDBC hdbc,
    SQLUSMALLINT fInfoType,
    SQLPOINTER rgbInfoValue,
    SQLSMALLINT cbInfoValueMax,
    SQLSMALLINT* pcbInfoValue);

SQLRETURN SQLGetTypeInfoW(
    SQLHSTMT StatementHandle,
    SQLSMALLINT DataType);

SQLRETURN SQLSetConnectOptionW(
    SQLHDBC hdbc,
    SQLUSMALLINT fOption,
    SQLULEN vParam);

SQLRETURN SQLSpecialColumnsW(
    SQLHSTMT hstmt,
    SQLUSMALLINT fColType,
    SQLWCHAR* szCatalogName,
    SQLSMALLINT cbCatalogName,
    SQLWCHAR* szSchemaName,
    SQLSMALLINT cbSchemaName,
    SQLWCHAR* szTableName,
    SQLSMALLINT cbTableName,
    SQLUSMALLINT fScope,
    SQLUSMALLINT fNullable);

SQLRETURN SQLStatisticsW(
    SQLHSTMT hstmt,
    SQLWCHAR* szCatalogName,
    SQLSMALLINT cbCatalogName,
    SQLWCHAR* szSchemaName,
    SQLSMALLINT cbSchemaName,
    SQLWCHAR* szTableName,
    SQLSMALLINT cbTableName,
    SQLUSMALLINT fUnique,
    SQLUSMALLINT fAccuracy);

SQLRETURN SQLTablesW(
    SQLHSTMT hstmt,
    SQLWCHAR* szCatalogName,
    SQLSMALLINT cbCatalogName,
    SQLWCHAR* szSchemaName,
    SQLSMALLINT cbSchemaName,
    SQLWCHAR* szTableName,
    SQLSMALLINT cbTableName,
    SQLWCHAR* szTableType,
    SQLSMALLINT cbTableType);

SQLRETURN SQLDataSourcesW(
    SQLHENV henv,
    SQLUSMALLINT fDirection,
    SQLWCHAR* szDSN,
    SQLSMALLINT cbDSNMax,
    SQLSMALLINT* pcbDSN,
    SQLWCHAR* szDescription,
    SQLSMALLINT cbDescriptionMax,
    SQLSMALLINT* pcbDescription);

SQLRETURN SQLDriverConnectW(
    SQLHDBC hdbc,
    SQLHWND hwnd,
    SQLWCHAR* szConnStrIn,
    SQLSMALLINT cbConnStrIn,
    SQLWCHAR* szConnStrOut,
    SQLSMALLINT cbConnStrOutMax,
    SQLSMALLINT* pcbConnStrOut,
    SQLUSMALLINT fDriverCompletion
    );

SQLRETURN SQLBrowseConnectW(
    SQLHDBC hdbc,
    SQLWCHAR* szConnStrIn,
    SQLSMALLINT cbConnStrIn,
    SQLWCHAR* szConnStrOut,
    SQLSMALLINT cbConnStrOutMax,
    SQLSMALLINT* pcbConnStrOut);

SQLRETURN SQLColumnPrivilegesW(
    SQLHSTMT hstmt,
    SQLWCHAR* szCatalogName,
    SQLSMALLINT cbCatalogName,
    SQLWCHAR* szSchemaName,
    SQLSMALLINT cbSchemaName,
    SQLWCHAR* szTableName,
    SQLSMALLINT cbTableName,
    SQLWCHAR* szColumnName,
    SQLSMALLINT cbColumnName);

SQLRETURN SQLGetStmtAttrW(
    SQLHSTMT hstmt,
    SQLINTEGER fAttribute,
    SQLPOINTER rgbValue,
    SQLINTEGER cbValueMax,
    SQLINTEGER* pcbValue);

SQLRETURN SQLSetStmtAttrW(
    SQLHSTMT hstmt,
    SQLINTEGER fAttribute,
    SQLPOINTER rgbValue,
    SQLINTEGER cbValueMax);

SQLRETURN SQLForeignKeysW(
    SQLHSTMT hstmt,
    SQLWCHAR* szPkCatalogName,
    SQLSMALLINT cbPkCatalogName,
    SQLWCHAR* szPkSchemaName,
    SQLSMALLINT cbPkSchemaName,
    SQLWCHAR* szPkTableName,
    SQLSMALLINT cbPkTableName,
    SQLWCHAR* szFkCatalogName,
    SQLSMALLINT cbFkCatalogName,
    SQLWCHAR* szFkSchemaName,
    SQLSMALLINT cbFkSchemaName,
    SQLWCHAR* szFkTableName,
    SQLSMALLINT cbFkTableName);

SQLRETURN SQLNativeSqlW(
    SQLHDBC hdbc,
    SQLWCHAR* szSqlStrIn,
    SQLINTEGER cbSqlStrIn,
    SQLWCHAR* szSqlStr,
    SQLINTEGER cbSqlStrMax,
    SQLINTEGER* pcbSqlStr);

SQLRETURN SQLPrimaryKeysW(
    SQLHSTMT hstmt,
    SQLWCHAR* szCatalogName,
    SQLSMALLINT cbCatalogName,
    SQLWCHAR* szSchemaName,
    SQLSMALLINT cbSchemaName,
    SQLWCHAR* szTableName,
    SQLSMALLINT cbTableName);

SQLRETURN SQLProcedureColumnsW(
    SQLHSTMT hstmt,
    SQLWCHAR* szCatalogName,
    SQLSMALLINT cbCatalogName,
    SQLWCHAR* szSchemaName,
    SQLSMALLINT cbSchemaName,
    SQLWCHAR* szProcName,
    SQLSMALLINT cbProcName,
    SQLWCHAR* szColumnName,
    SQLSMALLINT cbColumnName);

SQLRETURN SQLProceduresW(
    SQLHSTMT hstmt,
    SQLWCHAR* szCatalogName,
    SQLSMALLINT cbCatalogName,
    SQLWCHAR* szSchemaName,
    SQLSMALLINT cbSchemaName,
    SQLWCHAR* szProcName,
    SQLSMALLINT cbProcName);

SQLRETURN SQLTablePrivilegesW(
    SQLHSTMT hstmt,
    SQLWCHAR* szCatalogName,
    SQLSMALLINT cbCatalogName,
    SQLWCHAR* szSchemaName,
    SQLSMALLINT cbSchemaName,
    SQLWCHAR* szTableName,
    SQLSMALLINT cbTableName);

SQLRETURN SQLDriversW(
    SQLHENV henv,
    SQLUSMALLINT fDirection,
    SQLWCHAR* szDriverDesc,
    SQLSMALLINT cbDriverDescMax,
    SQLSMALLINT* pcbDriverDesc,
    SQLWCHAR* szDriverAttributes,
    SQLSMALLINT cbDrvrAttrMax,
    SQLSMALLINT* pcbDrvrAttr);

//Function prototypes - ANSI
SQLRETURN SQLColAttributeA(
    SQLHSTMT hstmt,
    SQLSMALLINT iCol,
    SQLSMALLINT iField,
    SQLPOINTER pCharAttr,
    SQLSMALLINT cbCharAttrMax,
    SQLSMALLINT* pcbCharAttr,
    SQLLEN* pNumAttr);

SQLRETURN SQLColAttributesA(
    SQLHSTMT hstmt,
    SQLUSMALLINT icol,
    SQLUSMALLINT fDescType,
    SQLPOINTER rgbDesc,
    SQLSMALLINT cbDescMax,
    SQLSMALLINT* pcbDesc,
    SQLLEN* pfDesc);

SQLRETURN SQLConnectA(
    SQLHDBC hdbc,
    SQLCHAR* szDSN,
    SQLSMALLINT cbDSN,
    SQLCHAR* szUID,
    SQLSMALLINT cbUID,
    SQLCHAR* szAuthStr,
    SQLSMALLINT cbAuthStr);

SQLRETURN SQLDescribeColA(
    SQLHSTMT hstmt,
    SQLUSMALLINT icol,
    SQLCHAR* szColName,
    SQLSMALLINT cbColNameMax,
    SQLSMALLINT* pcbColName,
    SQLSMALLINT* pfSqlType,
    SQLULEN* pcbColDef,
    SQLSMALLINT* pibScale,
    SQLSMALLINT* pfNullable);

SQLRETURN SQLErrorA(
    SQLHENV henv,
    SQLHDBC hdbc,
    SQLHSTMT hstmt,
    SQLCHAR* szSqlState,
    SQLINTEGER* pfNativeError,
    SQLCHAR* szErrorMsg,
    SQLSMALLINT cbErrorMsgMax,
    SQLSMALLINT* pcbErrorMsg);

SQLRETURN SQLExecDirectA(
    SQLHSTMT hstmt,
    SQLCHAR* szSqlStr,
    SQLINTEGER cbSqlStr);

SQLRETURN SQLGetConnectAttrA(
    SQLHDBC hdbc,
    SQLINTEGER fAttribute,
    SQLPOINTER rgbValue,
    SQLINTEGER cbValueMax,
    SQLINTEGER* pcbValue);

SQLRETURN SQLGetCursorNameA(
    SQLHSTMT hstmt,

    SQLCHAR* szCursor,
    SQLSMALLINT cbCursorMax,
    SQLSMALLINT* pcbCursor);

SQLRETURN SQLGetDescFieldA(
    SQLHDESC hdesc,
    SQLSMALLINT iRecord,
    SQLSMALLINT iField,
    SQLPOINTER rgbValue,
    SQLINTEGER cbBufferLength,
    SQLINTEGER* StringLength);

SQLRETURN SQLGetDescRecA(
    SQLHDESC hdesc,
    SQLSMALLINT iRecord,
    SQLCHAR* szName,
    SQLSMALLINT cbNameMax,
    SQLSMALLINT* pcbName,
    SQLSMALLINT* pfType,
    SQLSMALLINT* pfSubType,
    SQLLEN* pLength,
    SQLSMALLINT* pPrecision,
    SQLSMALLINT* pScale,
    SQLSMALLINT* pNullable);

SQLRETURN SQLGetDiagFieldA(
    SQLSMALLINT fHandleType,
    SQLHANDLE handle,
    SQLSMALLINT iRecord,
    SQLSMALLINT fDiagField,
    SQLPOINTER rgbDiagInfo,
    SQLSMALLINT cbDiagInfoMax,
    SQLSMALLINT* pcbDiagInfo);

SQLRETURN SQLGetDiagRecA(
    SQLSMALLINT fHandleType,
    SQLHANDLE handle,
    SQLSMALLINT iRecord,
    SQLCHAR* szSqlState,
    SQLINTEGER* pfNativeError,
    SQLCHAR* szErrorMsg,
    SQLSMALLINT cbErrorMsgMax,
    SQLSMALLINT* pcbErrorMsg);

SQLRETURN SQLPrepareA(
    SQLHSTMT hstmt,
    SQLCHAR* szSqlStr,
    SQLINTEGER cbSqlStr);

SQLRETURN SQLSetConnectAttrA(
    SQLHDBC hdbc,
    SQLINTEGER fAttribute,
    SQLPOINTER rgbValue,
    SQLINTEGER cbValue);

SQLRETURN SQLSetCursorNameA(
    SQLHSTMT hstmt,
    SQLCHAR* szCursor,
    SQLSMALLINT cbCursor);

SQLRETURN SQLColumnsA(
    SQLHSTMT hstmt,
    SQLCHAR* szCatalogName,
    SQLSMALLINT cbCatalogName,
    SQLCHAR* szSchemaName,
    SQLSMALLINT cbSchemaName,
    SQLCHAR* szTableName,
    SQLSMALLINT cbTableName,
    SQLCHAR* szColumnName,
    SQLSMALLINT cbColumnName);

SQLRETURN SQLGetConnectOptionA(
    SQLHDBC hdbc,
    SQLUSMALLINT fOption,
    SQLPOINTER pvParam);

SQLRETURN SQLGetInfoA(
    SQLHDBC hdbc,
    SQLUSMALLINT fInfoType,
    SQLPOINTER rgbInfoValue,
    SQLSMALLINT cbInfoValueMax,
    SQLSMALLINT* pcbInfoValue);

SQLRETURN SQLGetTypeInfoA(
    SQLHSTMT StatementHandle,
    SQLSMALLINT DataType);

SQLRETURN SQLSetConnectOptionA(
    SQLHDBC hdbc,
    SQLUSMALLINT fOption,
    SQLULEN vParam);

SQLRETURN SQLSpecialColumnsA(
    SQLHSTMT hstmt,
    SQLUSMALLINT fColType,
    SQLCHAR* szCatalogName,
    SQLSMALLINT cbCatalogName,
    SQLCHAR* szSchemaName,
    SQLSMALLINT cbSchemaName,
    SQLCHAR* szTableName,
    SQLSMALLINT cbTableName,
    SQLUSMALLINT fScope,
    SQLUSMALLINT fNullable);

SQLRETURN SQLStatisticsA(
    SQLHSTMT hstmt,
    SQLCHAR* szCatalogName,
    SQLSMALLINT cbCatalogName,
    SQLCHAR* szSchemaName,
    SQLSMALLINT cbSchemaName,
    SQLCHAR* szTableName,
    SQLSMALLINT cbTableName,
    SQLUSMALLINT fUnique,
    SQLUSMALLINT fAccuracy);

SQLRETURN SQLTablesA(
    SQLHSTMT hstmt,
    SQLCHAR* szCatalogName,
    SQLSMALLINT cbCatalogName,
    SQLCHAR* szSchemaName,
    SQLSMALLINT cbSchemaName,
    SQLCHAR* szTableName,
    SQLSMALLINT cbTableName,
    SQLCHAR* szTableType,
    SQLSMALLINT cbTableType);

SQLRETURN SQLDataSourcesA(
    SQLHENV henv,
    SQLUSMALLINT fDirection,
    SQLCHAR* szDSN,
    SQLSMALLINT cbDSNMax,
    SQLSMALLINT* pcbDSN,
    SQLCHAR* szDescription,
    SQLSMALLINT cbDescriptionMax,
    SQLSMALLINT* pcbDescription);

SQLRETURN SQLDriverConnectA(
    SQLHDBC hdbc,
    SQLHWND hwnd,
    SQLCHAR* szConnStrIn,
    SQLSMALLINT cbConnStrIn,
    SQLCHAR* szConnStrOut,
    SQLSMALLINT cbConnStrOutMax,
    SQLSMALLINT* pcbConnStrOut,
    SQLUSMALLINT fDriverCompletion);

SQLRETURN SQLBrowseConnectA(
    SQLHDBC hdbc,
    SQLCHAR* szConnStrIn,
    SQLSMALLINT cbConnStrIn,
    SQLCHAR* szConnStrOut,
    SQLSMALLINT cbConnStrOutMax,
    SQLSMALLINT* pcbConnStrOut);

SQLRETURN SQLColumnPrivilegesA(
    SQLHSTMT hstmt,
    SQLCHAR* szCatalogName,
    SQLSMALLINT cbCatalogName,
    SQLCHAR* szSchemaName,
    SQLSMALLINT cbSchemaName,
    SQLCHAR* szTableName,
    SQLSMALLINT cbTableName,
    SQLCHAR* szColumnName,
    SQLSMALLINT cbColumnName);

SQLRETURN SQLGetStmtAttrA(
    SQLHSTMT hstmt,
    SQLINTEGER fAttribute,
    SQLPOINTER rgbValue,
    SQLINTEGER cbValueMax,
    SQLINTEGER* pcbValue);

SQLRETURN SQLForeignKeysA(
    SQLHSTMT hstmt,
    SQLCHAR* szPkCatalogName,
    SQLSMALLINT cbPkCatalogName,
    SQLCHAR* szPkSchemaName,
    SQLSMALLINT cbPkSchemaName,
    SQLCHAR* szPkTableName,
    SQLSMALLINT cbPkTableName,
    SQLCHAR* szFkCatalogName,
    SQLSMALLINT cbFkCatalogName,
    SQLCHAR* szFkSchemaName,
    SQLSMALLINT cbFkSchemaName,
    SQLCHAR* szFkTableName,
    SQLSMALLINT cbFkTableName);

SQLRETURN SQLNativeSqlA(
    SQLHDBC hdbc,
    SQLCHAR* szSqlStrIn,
    SQLINTEGER cbSqlStrIn,
    SQLCHAR* szSqlStr,
    SQLINTEGER cbSqlStrMax,
    SQLINTEGER* pcbSqlStr);

SQLRETURN SQLPrimaryKeysA(
    SQLHSTMT hstmt,
    SQLCHAR* szCatalogName,
    SQLSMALLINT cbCatalogName,
    SQLCHAR* szSchemaName,
    SQLSMALLINT cbSchemaName,
    SQLCHAR* szTableName,
    SQLSMALLINT cbTableName);

SQLRETURN SQLProcedureColumnsA(
    SQLHSTMT hstmt,
    SQLCHAR* szCatalogName,
    SQLSMALLINT cbCatalogName,
    SQLCHAR* szSchemaName,
    SQLSMALLINT cbSchemaName,
    SQLCHAR* szProcName,
    SQLSMALLINT cbProcName,
    SQLCHAR* szColumnName,
    SQLSMALLINT cbColumnName);

SQLRETURN SQLProceduresA(
    SQLHSTMT hstmt,
    SQLCHAR* szCatalogName,
    SQLSMALLINT cbCatalogName,
    SQLCHAR* szSchemaName,
    SQLSMALLINT cbSchemaName,
    SQLCHAR* szProcName,
    SQLSMALLINT cbProcName);

SQLRETURN SQLTablePrivilegesA(
    SQLHSTMT hstmt,
    SQLCHAR* szCatalogName,
    SQLSMALLINT cbCatalogName,
    SQLCHAR* szSchemaName,
    SQLSMALLINT cbSchemaName,
    SQLCHAR* szTableName,
    SQLSMALLINT cbTableName);

SQLRETURN SQLDriversA(
    SQLHENV henv,
    SQLUSMALLINT fDirection,
    SQLCHAR* szDriverDesc,
    SQLSMALLINT cbDriverDescMax,
    SQLSMALLINT* pcbDriverDesc,
    SQLCHAR* szDriverAttributes,
    SQLSMALLINT cbDrvrAttrMax,
    SQLSMALLINT* pcbDrvrAttr);
