/*
 *  Copyright (C) 1995 by Ke Jin <kejin@empress.com>
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

version(Windows) {
  public import std.c.windows.windows;
} else {
  alias VOID = void;
  enum TRUE = 1;
  enum FALSE = 0;

  alias BYTE = ubyte;
  alias CHAR = char;
  alias WORD = ushort;
  alias DWORD = uint;
  alias LPSTR = char*;
  alias LPCSTR = const(char)*;
  alias LPTSTR = TCHAR*;
  alias LPDWORD = DWORD*;
  alias BOOL = int;
}

nothrow:

//API declaration data types
alias SQLCHAR = ubyte;
alias SQLSMALLINT = short;
alias SQLUSMALLINT = ushort;
alias SQLINTEGER = int;
alias SQLUINTEGER = uint;
alias SQLPOINTER = void*;
alias SQLSCHAR = byte;
alias SQLDATE = ubyte;
alias SQLDECIMAL = ubyte;
alias SQLNUMERIC = ubyte;
alias SQLDOUBLE = double;
alias SQLFLOAT = double;
alias SQLREAL = float;
alias SQLTIME = ubyte;
alias SQLTIMESTAMP = ubyte;
alias SQLVARCHAR = ubyte;

version(Win64) {
  alias SQLLEN = long;
  alias SQLULEN = ulong;
  alias SQLSETPOSIROW = ulong;
} else {
  alias SQLLEN = int;
  alias SQLULEN = uint;
  alias SQLSETPOSIROW = ushort;
}

//Backward compatibility with older platform sdks
alias SQLROWCOUNT = SQLULEN;
alias SQLROWSETSIZE = SQLULEN;
alias SQLTRANSID = SQLULEN;
alias SQLROWOFFSET = SQLLEN;

//Generic pointer types
alias PTR = void*;
alias SQLHANDLE = void*;

//Handles

alias HENV = void*;
alias HDBC = void*;
alias HSTMT = void*;
alias SQLHENV = SQLHANDLE;
alias SQLHDBC = SQLHANDLE;
alias SQLHSTMT = SQLHANDLE;
alias SQLHDESC = SQLHANDLE;

//Window Handle
version(Win32) {
  alias SQLHWND = HWND;
} else version(OSX) {
  alias HWND = WindowPtr;
  alias SQLHWND = HWND;
} else {
  alias SQLHWND = SQLPOINTER;
}

//SQL portable types for C
alias UCHAR = ubyte;
alias SCHAR = byte;
alias SWORD = short;
alias UWORD = ushort;
alias SDWORD = int;
alias UDWORD = uint;

alias SSHORT = short;
alias USHORT = ushort;
alias SLONG = int;
alias ULONG = uint;
alias SFLOAT = float;
alias SDOUBLE = double;
alias LDOUBLE = double;

//Return type for functions
alias RETCODE = short;
alias SQLRETURN = SQLSMALLINT;

//SQL portable types for C - DATA, TIME, TIMESTAMP, and BOOKMARK
alias BOOKMARK = SQLULEN;

struct DATE_STRUCT {
  SQLSMALLINT year;
  SQLUSMALLINT month;
  SQLUSMALLINT day;
}
alias SQL_DATE_STRUCT = DATE_STRUCT;

struct TIME_STRUCT {
  SQLUSMALLINT hour;
  SQLUSMALLINT minute;
  SQLUSMALLINT second;
}
alias SQL_TIME_STRUCT = TIME_STRUCT;

struct TIMESTAMP_STRUCT {
  SQLSMALLINT year;
  SQLUSMALLINT month;
  SQLUSMALLINT day;
  SQLUSMALLINT hour;
  SQLUSMALLINT minute;
  SQLUSMALLINT second;
  SQLUINTEGER fraction;
}
alias SQL_TIMESTAMP_STRUCT = TIMESTAMP_STRUCT;

/*
 *  Enumeration for DATETIME_INTERVAL_SUBCODE values for interval data types
 *
 *  These values are from SQL-92
 */

enum SQLINTERVAL {
  SQL_IS_YEAR = 1,
  SQL_IS_MONTH,
  SQL_IS_DAY,
  SQL_IS_HOUR,
  SQL_IS_MINUTE,
  SQL_IS_SECOND,
  SQL_IS_YEAR_TO_MONTH,
  SQL_IS_DAY_TO_HOUR,
  SQL_IS_DAY_TO_MINUTE,
  SQL_IS_DAY_TO_SECOND,
  SQL_IS_HOUR_TO_MINUTE,
  SQL_IS_HOUR_TO_SECOND,
  SQL_IS_MINUTE_TO_SECOND
}

struct SQL_YEAR_MONTH_STRUCT {
  SQLUINTEGER year;
  SQLUINTEGER month;
}

struct SQL_DAY_SECOND_STRUCT {
  SQLUINTEGER day;
  SQLUINTEGER our;
  SQLUINTEGER minute;
  SQLUINTEGER second;
  SQLUINTEGER fraction;
}

struct SQL_INTERVAL_STRUCT {
  SQLINTERVAL interval_type;
  SQLSMALLINT interval_sign;
  TimeRep intval;

  union TimeRep {
    SQL_YEAR_MONTH_STRUCT year_month;
    SQL_DAY_SECOND_STRUCT day_second;
  }
}

//The ODBC C types for SQL_C_SBIGINT and SQL_C_UBIGINT
alias ODBCINT64 = long;
alias SQLBIGINT = ODBCINT64;
alias SQLUBIGINT = ulong;

//The internal representation of the numeric data type
enum SQL_MAX_NUMERIC_LEN    = 16;
struct SQL_NUMERIC_STRUCT {
  SQLCHAR  precision;
  SQLSCHAR scale;
  SQLCHAR  sign;   //0 for negative, 1 for positive
  SQLCHAR  val[SQL_MAX_NUMERIC_LEN];
}

struct SQLGUID {
  DWORD Data1;
  WORD Data2;
  WORD Data3;
  BYTE Data4[8]; //BYTE
}

alias SQLWCHAR = wchar;
version (Windows) {} else {
  static assert(false, "Investigate what wchar should be");
}

version(UNICODE) {
  alias SQLTCHAR = SQLWCHAR;
} else {
  alias SQLTCHAR = SQLCHAR;
}
