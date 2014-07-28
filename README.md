# [Presto](http://prestodb.io) ODBC Driver

ODBC is a C API that provides a standard way of communicating with anything that accepts SQL-like input; the Presto ODBC Driver lets you communicate with Presto via this standard. The high-level goal is to be able to communicate with Presto from MS Query, MS Excel, and Tableau.

This driver is written in the [D Programming Language](http://dlang.org)

## Current Status

* Only works on Windows
* Many functions are not implemented, the driver does *not* meet the "Core" level of [ODBC conformance](odbc-conformance.md)
* The only error handling in place is a "catch and log" strategy
* Most queries will work as expected
* Tableau works correctly for the cases we have tried
* MS Query is tested and will work as soon as we write a simple GUI

## Goals

* Full ODBC 3.51 conformance
* Full support on Windows/Mac/Linux
* Seamless integration with Tableau

## Development Environment Setup

### Installation Prerequisites

1. Cygwin with the GNU make package
1. [MSVC 64-bit linker](http://www.visualstudio.com) (download and install the free Express 2013 edition for Windows Desktop)
1. dmd (D Language Compiler), tested with [dmd 2.065](http://dlang.org/download) (note: this must be installed *after*  Visual Studio)
1. Access to a running [Presto](http://prestodb.io) instance

### Building and Registering the Driver

1. Build the Presto ODBC Driver
  1. Launch the Cygwin terminal
  1. Navigate to your checkout of this repo (e.g. `cd /cygdrive/c/presto-odbc`)
  1. `make clean install` -- builds the driver, runs tests, copies the driver and libcurl to `C:\temp` and backs up the log files
1. Register the Presto ODBC Driver by double clicking the `register_driver.reg` file in the main directory of this repo
1. Setup a data source for the driver
  1. Open Control Panel and choose `Set up ODBC data sources (64-bit)`
  1. Sanity Check: Look at the `Drivers` tab, make sure you see `Presto ODBC Driver`
  1. Enable the Driver Manager Logfile (from the ODBC Data Sources window)
    1. Go to the `Tracing` tab
    1. Set the `Log File Path` to `C:\temp\SQL.LOG`
    1. Click `Start Tracing Now`
    1. Click Ok to close the program

### Using the driver with Tableau

1. Open Tableau
1. Click `Connect to data`
  1. At the bottom, select `Other Database (ODBC)`
  1. Click the radio button for `Driver`
  1. Select `Presto ODBC Driver`
  1. Click `Connect`
  1. Fill in the server, port, and database (catalog) information
  1. In the `String Extras` box, enter the server with `server=server_url` and a schema using the format `schema=schema_name`
  1. Tableau will perform a bunch of fake queries to analyze the ODBC driver, this may take a while to complete but only needs to happen once
1. On the new screen:
  1. Click `Select Schema`, then press the search icon, then select the schema you entered on the previous screen
  1. Search for `tables` (or press enter to see all of them) and drag any table you wish to use to the right
  1. Click `Go to Worksheet`
  1. Click `OK` to go past the warning dialog
1. Analyze!

## Coding Conventions

Not all of the conventions have been applied to the source yet.

* 4 space indentation
* Try to limit to 120 columns
* Prefer `myHttpFunction` to `myHTTPFunction`
* All ODBC functions must have their contents wrapped with a call to `exceptionBoundary`
* As appropriate, change integer types to enum types (use `StatementAttribute` instead of `SQLSMALLINT`, etc)
* Always wrap C types with safer D abstractions (see `toDString` and `OutputWChar`); prefix the C-style variables with an underscore
* Also prefix variables with an underscore to express that the variable should be cast/converted to or encapsulated in another type before use
* Use `dllEnforce` instead of `assert`
* Avoid fully qualifying enum values (`MyEnumType.MyEnumValue`); use a `with` statement instead
* Always use a `with` statement when accessing ODBC handles
* Always specify whether lengths are in bytes or characters as part of a variable's name

## References

* [ODBC 3.x Requirements](http://msdn.microsoft.com/en-us/library/ms713848%28v=vs.85%29.aspx)
* [ODBC Function Summary](http://msdn.microsoft.com/en-us/library/ms712628%28v=vs.85%29.aspx)
* [ODBC C Data Types Table](http://msdn.microsoft.com/en-us/library/ms714556%28v=vs.85%29.aspx)
* [ODBC SQL Data Types Table](http://msdn.microsoft.com/en-us/library/ms710150%28v=vs.85%29.aspx)
* [Interfacing from D to C](http://dlang.org/interfaceToC)
