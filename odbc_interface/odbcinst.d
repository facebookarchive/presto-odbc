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
module odbc_interface.odbcinst;

import odbc_interface.sql;

enum USERDSN_ONLY = 0;
enum SYSTEMDSN_ONLY = 1;

//SQLConfigDataSource
enum ODBC_ADD_DSN = 1;
enum ODBC_CONFIG_DSN = 2;
enum ODBC_REMOVE_DSN = 3;

enum ODBC_ADD_SYS_DSN = 4;
enum ODBC_CONFIG_SYS_DSN = 5;
enum ODBC_REMOVE_SYS_DSN = 6;
enum ODBC_REMOVE_DEFAULT_DSN = 7;

//Install request flags
enum ODBC_INSTALL_INQUIRY = 1;
enum ODBC_INSTALL_COMPLETE = 2;

//Config driver flags
enum ODBC_INSTALL_DRIVER = 1;
enum ODBC_REMOVE_DRIVER = 2;
enum ODBC_CONFIG_DRIVER = 3;
enum ODBC_CONFIG_DRIVER_MAX = 100;

//SQLGetConfigMode and SQLSetConfigMode flags
enum ODBC_BOTH_DSN = 0;
enum ODBC_USER_DSN = 1;
enum ODBC_SYSTEM_DSN = 2;

//SQLInstallerError code
enum ODBC_ERROR_GENERAL_ERR = 1;
enum ODBC_ERROR_INVALID_BUFF_LEN = 2;
enum ODBC_ERROR_INVALID_HWND = 3;
enum ODBC_ERROR_INVALID_STR = 4;
enum ODBC_ERROR_INVALID_REQUEST_TYPE = 5;
enum ODBC_ERROR_COMPONENT_NOT_FOUND = 6;
enum ODBC_ERROR_INVALID_NAME = 7;
enum ODBC_ERROR_INVALID_KEYWORD_VALUE = 8;
enum ODBC_ERROR_INVALID_DSN = 9;
enum ODBC_ERROR_INVALID_INF = 10;
enum ODBC_ERROR_REQUEST_FAILED = 11;
enum ODBC_ERROR_INVALID_PATH = 12;
enum ODBC_ERROR_LOAD_LIB_FAILED = 13;
enum ODBC_ERROR_INVALID_PARAM_SEQUENCE = 14;
enum ODBC_ERROR_INVALID_LOG_FILE = 15;
enum ODBC_ERROR_USER_CANCELED = 16;
enum ODBC_ERROR_USAGE_UPDATE_FAILED = 17;
enum ODBC_ERROR_CREATE_DSN_FAILED = 18;
enum ODBC_ERROR_WRITING_SYSINFO_FAILED = 19;
enum ODBC_ERROR_REMOVE_DSN_FAILED = 20;
enum ODBC_ERROR_OUT_OF_MEM = 21;
enum ODBC_ERROR_OUTPUT_STRING_TRUNCATED = 22;
enum ODBC_ERROR_NOTRANINFO = 23;

version(UNICODE) {
    alias SQLInstallODBCW = SQLInstallODBC;
    alias SQLCreateDataSourceW = SQLCreateDataSource;
    alias SQLGetTranslatorW = SQLGetTranslator;
    alias SQLInstallDriverW = SQLInstallDriver;
    alias SQLInstallDriverManagerW = SQLInstallDriverManager;
    alias SQLGetInstalledDriversW = SQLGetInstalledDrivers;
    alias SQLGetAvailableDriversW = SQLGetAvailableDrivers;
    alias SQLConfigDataSourceW = SQLConfigDataSource;
    alias SQLWriteDSNToIniW = SQLWriteDSNToIni;
    alias SQLRemoveDSNFromIniW = SQLRemoveDSNFromIni;
    alias SQLValidDSNW = SQLValidDSN;
    alias SQLWritePrivateProfileStringW = SQLWritePrivateProfileString;
    alias SQLGetPrivateProfileStringW = SQLGetPrivateProfileString;
    alias SQLInstallTranslatorW = SQLInstallTranslator;
    alias SQLRemoveTranslatorW = SQLRemoveTranslator;
    alias SQLRemoveDriverW = SQLRemoveDriver;
    alias SQLConfigDriverW = SQLConfigDriver;
    alias SQLInstallerErrorW = SQLInstallerError;
    alias SQLPostInstallerErrorW = SQLPostInstallerError;
    alias SQLReadFileDSNW = SQLReadFileDSN;
    alias SQLWriteFileDSNW = SQLWriteFileDSN;
    alias SQLInstallDriverExW = SQLInstallDriverEx;
    alias SQLInstallTranslatorExW = SQLInstallTranslatorEx;
}

extern(System):

//Function Prototypes

BOOL SQLGetConfigMode(UWORD* pwConfigMode);

BOOL SQLInstallDriverEx(
    LPCSTR lpszDriver,
    LPCSTR lpszPathIn,
    LPSTR lpszPathOut,
    WORD cbPathOutMax,
    WORD* pcbPathOut,
    WORD fRequest,
    LPDWORD lpdwUsageCount);


BOOL SQLInstallDriverExW(
    LPCWSTR lpszDriver,
    LPCWSTR lpszPathIn,
    LPWSTR lpszPathOut,
    WORD cbPathOutMax,
    WORD* pcbPathOut,
    WORD fRequest,
    LPDWORD lpdwUsageCount);

SQLRETURN SQLInstallerError(
    WORD iError,
    DWORD* pfErrorCode,
    LPSTR lpszErrorMsg,
    WORD cbErrorMsgMax,
    WORD* pcbErrorMsg);

SQLRETURN SQLInstallerErrorW(
    WORD iError,
    DWORD* pfErrorCode,
    LPWSTR lpszErrorMsg,
    WORD cbErrorMsgMax,
    WORD* pcbErrorMsg);

SQLRETURN SQLPostInstallerError(DWORD dwErrorCode, LPCSTR lpszErrMsg);

SQLRETURN SQLPostInstallerErrorW(DWORD dwErrorCode, LPCWSTR lpszErrorMsg);

BOOL SQLInstallTranslatorEx(
    LPCSTR lpszTranslator,
    LPCSTR lpszPathIn,
    LPSTR lpszPathOut,
    WORD cbPathOutMax,
    WORD* pcbPathOut,
    WORD fRequest,
    LPDWORD lpdwUsageCount);


BOOL SQLInstallTranslatorExW(
    LPCWSTR lpszTranslator,
    LPCWSTR lpszPathIn,
    LPWSTR lpszPathOut,
    WORD cbPathOutMax,
    WORD* pcbPathOut,
    WORD fRequest,
    LPDWORD lpdwUsageCount);


BOOL SQLReadFileDSN(
    LPCSTR lpszFileName,
    LPCSTR lpszAppName,
    LPCSTR lpszKeyName,
    LPSTR lpszString,
    WORD cbString,
    WORD* pcbString);

BOOL SQLReadFileDSNW(
    LPCWSTR lpszFileName,
    LPCWSTR lpszAppName,
    LPCWSTR lpszKeyName,
    LPWSTR lpszString,
    WORD cbString,
    WORD* pcbString);

BOOL SQLWriteFileDSN(
    LPCSTR lpszFileName,
    LPCSTR lpszAppName,
    LPCSTR lpszKeyName,
    LPCSTR lpszString);

BOOL SQLWriteFileDSNW(
    LPCWSTR lpszFileName,
    LPCWSTR lpszAppName,
    LPCWSTR lpszKeyName,
    LPCWSTR lpszString);

BOOL SQLSetConfigMode(UWORD wConfigMode);

BOOL SQLInstallODBC(
    HWND hwndParent,
    LPCSTR lpszInfFile,
    LPCSTR lpszSrcPath,
    LPCSTR lpszDrivers);

BOOL SQLInstallODBCW(
    HWND hwndParent,
    LPCWSTR lpszInfFile,
    LPCWSTR lpszSrcPath,
    LPCWSTR lpszDrivers);

BOOL SQLManageDataSources(HWND hwndParent);

BOOL SQLCreateDataSource(HWND hwndParent, LPCSTR lpszDSN);

BOOL SQLCreateDataSourceW(HWND hwndParent, LPCWSTR lpszDSN);

BOOL SQLGetTranslator(
    HWND hwnd,
    LPSTR lpszName,
    WORD cbNameMax,
    WORD* pcbNameOut,
    LPSTR lpszPath,
    WORD cbPathMax,
    WORD* pcbPathOut,
    DWORD* pvOption);

BOOL SQLGetTranslatorW(
    HWND hwnd,
    LPWSTR lpszName,
    WORD cbNameMax,
    WORD* pcbNameOut,
    LPWSTR lpszPath,
    WORD cbPathMax,
    WORD* pcbPathOut,
    DWORD* pvOption);

/*  Low level APIs
 *  NOTE: The high-level APIs should always be used. These APIs
 *        have been left for compatibility.
 */
BOOL SQLInstallDriver(
    LPCSTR lpszInfFile,
    LPCSTR lpszDriver,
    LPSTR lpszPath,
    WORD cbPathMax,
    WORD* pcbPathOut);

BOOL SQLInstallDriverW(
    LPCWSTR lpszInfFile,
    LPCWSTR lpszDriver,
    LPWSTR lpszPath,
    WORD cbPathMax,
    WORD* pcbPathOut);

BOOL SQLInstallDriverManager(
    LPSTR lpszPath,
    WORD cbPathMax,
    WORD* pcbPathOut);

BOOL SQLInstallDriverManagerW(
    LPWSTR lpszPath,
    WORD cbPathMax,
    WORD* pcbPathOut);

BOOL SQLGetInstalledDrivers(
    LPSTR lpszBuf,
    WORD cbBufMax,
    WORD* pcbBufOut);

BOOL SQLGetInstalledDriversW(
    LPWSTR lpszBuf,
    WORD cbBufMax,
    WORD* pcbBufOut);

BOOL SQLGetAvailableDrivers(
    LPCSTR lpszInfFile,
    LPSTR lpszBuf,
    WORD cbBufMax,
    WORD* pcbBufOut);

BOOL SQLGetAvailableDriversW(
    LPCWSTR lpszInfFile,
    LPWSTR lpszBuf,
    WORD cbBufMax,
    WORD* pcbBufOut);

BOOL SQLConfigDataSource(
    HWND hwndParent,
    WORD fRequest,
    LPCSTR lpszDriver,
    LPCSTR lpszAttributes);

BOOL SQLConfigDataSourceW(
    HWND hwndParent,
    WORD fRequest,
    LPCWSTR lpszDriver,
    LPCWSTR lpszAttributes);

BOOL SQLRemoveDefaultDataSource();

BOOL SQLWriteDSNToIni(LPCSTR lpszDSN, LPCSTR lpszDriver);

BOOL SQLWriteDSNToIniW(LPCWSTR lpszDSN, LPCWSTR lpszDriver);

BOOL SQLRemoveDSNFromIni(LPCSTR lpszDSN);

BOOL SQLRemoveDSNFromIniW(LPCWSTR lpszDSN);

BOOL SQLValidDSN(LPCSTR lpszDSN);

BOOL SQLValidDSNW(LPCWSTR lpszDSN);

BOOL SQLWritePrivateProfileString(
    LPCSTR lpszSection,
    LPCSTR lpszEntry,
    LPCSTR lpszString,
    LPCSTR lpszFilename);

BOOL SQLWritePrivateProfileStringW(
    LPCWSTR lpszSection,
    LPCWSTR lpszEntry,
    LPCWSTR lpszString,
    LPCWSTR lpszFilename);

int SQLGetPrivateProfileString(
    LPCSTR lpszSection,
    LPCSTR lpszEntry,
    LPCSTR lpszDefault,
    LPSTR lpszRetBuffer,
    int cbRetBuffer,
    LPCSTR lpszFilename);

int SQLGetPrivateProfileStringW(
    LPCWSTR lpszSection,
    LPCWSTR lpszEntry,
    LPCWSTR lpszDefault,
    LPWSTR lpszRetBuffer,
    int cbRetBuffer,
    LPCWSTR lpszFilename);

BOOL SQLRemoveDriverManager(LPDWORD lpdwUsageCount);

BOOL SQLInstallTranslator(
    LPCSTR lpszInfFile,
    LPCSTR lpszTranslator,
    LPCSTR lpszPathIn,
    LPSTR lpszPathOut,
    WORD cbPathOutMax,
    WORD* pcbPathOut,
    WORD fRequest,
    LPDWORD lpdwUsageCount);

BOOL SQLInstallTranslatorW(
    LPCWSTR lpszInfFile,
    LPCWSTR lpszTranslator,
    LPCWSTR lpszPathIn,
    LPWSTR lpszPathOut,
    WORD cbPathOutMax,
    WORD* pcbPathOut,
    WORD fRequest,
    LPDWORD lpdwUsageCount);

BOOL SQLRemoveTranslator(LPCSTR lpszTranslator, LPDWORD lpdwUsageCount);

BOOL SQLRemoveTranslatorW(LPCWSTR lpszTranslator, LPDWORD lpdwUsageCount);

BOOL SQLRemoveDriver(
    LPCSTR lpszDriver,
    BOOL fRemoveDSN,
    LPDWORD lpdwUsageCount);

BOOL SQLRemoveDriverW(
    LPCWSTR lpszDriver,
    BOOL fRemoveDSN,
    LPDWORD lpdwUsageCount);

BOOL SQLConfigDriver(
    HWND hwndParent,
    WORD fRequest,
    LPCSTR lpszDriver,
    LPCSTR lpszArgs,
    LPSTR lpszMsg,
    WORD cbMsgMax,
    WORD* pcbMsgOut);

BOOL ConfigDSN(
    HWND hwndParent,
    WORD fRequest,
    LPCSTR lpszDriver,
    LPCSTR lpszAttributes);

BOOL ConfigDSNW(
    HWND hwndParent,
    WORD fRequest,
    LPCWSTR lpszDriver,
    LPCWSTR lpszAttributes);

BOOL ConfigTranslator(
    HWND hwndParent,
    DWORD* pvOption);

BOOL ConfigDriver(
    HWND hwndParent,
    WORD fRequest,
    LPCSTR lpszDriver,
    LPCSTR lpszArgs,
    LPSTR lpszMsg,
    WORD cbMsgMax,
    WORD* pcbMsgOut);

BOOL ConfigDriverW(
    HWND hwndParent,
    WORD fRequest,
    LPCWSTR lpszDriver,
    LPCWSTR lpszArgs,
    LPWSTR lpszMsg,
    WORD cbMsgMax,
    WORD* pcbMsgOut);
