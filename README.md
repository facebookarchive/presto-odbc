
# [Presto](http://prestodb.io) ODBC Driver

ODBC is a C API that provides a standard way of communicating with anything that accepts SQL-like input; the Presto ODBC Driver lets you communicate with Presto via this standard. The high-level goal is to be able to communicate with Presto from MS Query, MS Excel, and Tableau.

This driver is written in the [D Programming Language](http://dlang.org)

## Current State of Affairs:

* Only works on Windows
* Many functions are unimplemented
* Most functions are not *fully* implemented
* The only error handling in place is a "catch and log" strategy
* Only queries with bigints, varchars, and doubles are supported
* Most queries will work as expected

## Goals:

* Full ODBC 3.0 (possibly 3.8) comformance
* Full support on Windows/Mac/Linux
* Seamless integration with Tableau

# Setting up the development environmnet:

## Installation Prerequisites:
1. Cygwin with the GNUMake package
2. [dmd 2.065](http://dlang.org/downloads)
3. [MSVC 64-bit linker](http://www.visualstudio.com) (download and install the free Express 2013 edition for Windows Desktop)
4. Acess to a running [Presto](http://prestodb.io) instance

## Manual Labor:
1. Add `C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\bin` to `PATH`
2. Copy `C:\D\dmd2\windows\bin64\libcurl.dll` into `C:\temp\` (make this directory if it does not exist)
3. Register the Presto ODBC Driver by double clicking the `register_driver.reg` file in the main directory of this repo
4. Press the Windows key and search for `ODBC Data Sources`; open the 64 bit version
  1. Sanity Check: Look at the `Drivers` tab, make sure you see `Presto ODBC Driver` (if not, try rebooting)
  2. Go to the `File DSN` tab
  3. Click Add
  4. Select `Presto ODBC Driver`
  5. Click Next
  6. Click Browse
  7. Enter a name for your driver DSN. `PrestoDriver.dsn` should be fine.
  8. Click Next/Ok/Yes until it goes back to the main window
5. Enabling the Driver Manager Logfile (from the ODBC Data Sources window):
  1. Go to the `Tracing` tab
  2. Set the `Log File Path` to `C:\temp\SQL.LOG`
  3. Click `Start Tracing Now`
  4. Click Ok to close the program
5. Change the IP in the `runQuery` function in `util.d` to point at your Presto instance
6. Build the Presto ODBC Driver
  1. Navigate to your checkout of this repo
  2. `cd driver`
  3. `make clean; make` - builds the driver
  4. `make copy` - copies the DLL to `C:\temp\` and backs up the log files
7. Start `C:\Program Files\Microsoft Office\Office15\MSQRY32.EXE`
  1. Go to File->New
  2. Click Browse, and select `PrestoDriver.dsn`
  3. Click Ok
  4. Run a query!

# Coding Conventions:

Not all of the conventions have been applied to the source yet.

* 4 space indentation
* Limited to 120 columns
* Prefer `myHttpFunction` to `myHTTPFunction`
* All ODBC functions must have their contents wrapped with a call to `exceptionBoundary`
* As appropriate, change integer types to enum types (use `StatementAttribute` instead of `SQLSMALLINT`, etc)
* Always wrap C types with safer D abstractions (see `toDString` and `OutputWChar`); prefix the C-style variables with an underscore
* Use dllEnforce instead of assert
* Avoid fully qualifying enum values (`MyEnumType.MyEnumValue`); use a `with` statement instead
* Always use a `with` statement when accessing ODBC handles

# References:

* [ODBC 3.x Requirements](http://msdn.microsoft.com/en-us/library/ms713848%28v=vs.85%29.aspx)
* [ODBC Function Summary](http://msdn.microsoft.com/en-us/library/ms712628%28v=vs.85%29.aspx)
* [ODBC C Data Types Table](http://msdn.microsoft.com/en-us/library/ms714556%28v=vs.85%29.aspx)
* [ODBC SQL Data Types Table](http://msdn.microsoft.com/en-us/library/ms710150%28v=vs.85%29.aspx)
* [Interfacing from D to C](http://dlang.org/interfaceToC)
