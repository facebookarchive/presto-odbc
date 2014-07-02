
# Presto ODBC Driver

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

## Manual Labor:
1. Add `C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\bin` to `PATH`
2. Copy `C:\D\dmd2\windows\bin64\libcurl.dll` into `C:\temp\` (make this directory if it does not exist)
3. Register the Presto ODBC Driver
  1. Open `regedit.exe`
  2. Navigate to the `HKEY_LOCAL_MACHINE\SOFTWARE\ODBC\ODBCINST.INI` key in regedit
  3. Right click the key and add a new->key. Name this key `Presto ODBC Driver`
  4. Right click `Presto ODBC Driver` and add:
    1. A new `string value` named `Driver`
    2. A new `string value` named `Setup`
    3. A new `DWORD value` named `UsageCount`
  5. Double click each of the new values and set:
    1. `Driver` to `C:\temp\PrestoOdbc.dll`
    2. `Setup` to `C:\temp\PrestoOdbc.dll`
    3. `UsageCount` to `1`
  6. In the `HKEY_LOCAL_MACHINE\SOFTWARE\ODBC\ODBCINST.INI\ODBC Drivers` key:
    1. Add a new `string value`: `Presto ODBC Driver`
    2. Set its value to `Installed`
5. Press the Windows key and search for `ODBC Data Sources`; open the 64 bit version
  1. Sanity Check: Look at the `Drivers` tab, make sure you see `Presto ODBC Driver` (if not, try rebooting)
  2. Go to the `File DSN` tab
  3. Click Add
  4. Select `Presto ODBC Driver`
  5. Click Next
  6. Click Browse
  7. Enter a name for your driver DSN. `PrestoDriver.dsn` should be fine.
  8. Click Next/Ok/Yes until it goes back to the main window
6. Enabling the Driver Manager Logfile (from the ODBC Data Sources window):
  1. Go to the `Tracing` tab
  2. Set the `Log File Path` to `C:\temp\SQL.LOG`
  3. Click `Start Tracing Now`
  4. Click Ok to close the program
7. Start `C:\Program Files\Microsoft Office\Office15\MSQRY32.EXE`
  1. Go to File->New
  2. Click Browse, and select `PrestoDriver.dsn`
  3. Click Ok
  4. Run a query!