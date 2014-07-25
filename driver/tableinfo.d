/**
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
module driver.tableinfo;

import std.array : front, empty, popFront;
import std.conv : text, to;
import std.variant : Variant;

import odbc.sqlext;
import odbc.odbcinst;

import driver.handles : OdbcStatement;
import driver.bindings : OdbcResult, OdbcResultRow;
import driver.util : dllEnforce, logMessage;

final class TableInfoResult : OdbcResult {
  this(OdbcStatement statementHandle) {
    this.statementHandle = statementHandle;
  }

  void addTable(string name) {
    with (statementHandle) with (connection) {
      results ~= new TableInfoResultRow(catalog, schema, name);
    }
  }

  override bool empty() const {
    return results.empty;
  }

  override inout(TableInfoResultRow) front() inout {
    assert(!empty);
    return results.front;
  }

  override void popFront() {
    results.popFront;
  }

  override size_t numberOfColumns() {
    return TableInfoResultColumns.max;
  }

private:
  OdbcStatement statementHandle;
  TableInfoResultRow[] results;
}


// http://msdn.microsoft.com/en-us/library/ms711831%28v=vs.85%29.aspx
final class TableInfoResultRow : OdbcResultRow {
  this(string catalogName, string schemaName, string tableName) {
    this.catalogName = catalogName;
    this.schemaName = schemaName;
    this.tableName = tableName;
  }

  override Variant dataAt(int column) {
    with (TableInfoResultColumns) {
      switch (column) {
      case TABLE_CATALOG:
        return Variant(catalogName);
      case TABLE_SCHEMA:
        return Variant(schemaName);
      case TABLE_NAME:
        return Variant(tableName);
      case TABLE_TYPE:
        return Variant("TABLE");
      case REMARKS:
        return Variant("A faux table for testing");
      default:
        dllEnforce(false, "Non-existant column " ~ text(cast(TableInfoResultColumns) column));
        assert(false, "Silence compiler errors about not returning");
      }
    }
  }
private:
  string catalogName;
  string schemaName;
  string tableName;
}

enum TableInfoResultColumns {
  TABLE_CATALOG = 1,
  TABLE_SCHEMA,
  TABLE_NAME,
  TABLE_TYPE,
  REMARKS
}
