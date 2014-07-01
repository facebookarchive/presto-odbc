
import std.array : front, empty, popFront;
import std.conv : text, to;
import std.variant : Variant;

import sqlext;
import odbcinst;

import bindings : OdbcResult, OdbcResultRow;
import util : dllEnforce, logMessage;

final class TableInfoResult : OdbcResult {
  void addTable(string name) {
    results ~= new TableInfoResultRow(name);
  }

  @property {
    bool empty() {
      return results.empty;
    }

    TableInfoResultRow front() {
      assert(!empty);
      return results.front;
    }

    void popFront() {
      results.popFront;
    }

    uint numberOfColumns() {
      return TableInfoResultColumns.max;
    }
  }

private:
  TableInfoResultRow[] results;
}

final class TableInfoResultRow : OdbcResultRow {
  this(string tableName) {
    this.tableName = tableName;
  }

  Variant dataAt(int column) {
    with (TableInfoResultColumns) {
      switch (column) {
      case TABLE_CAT:
        return Variant("tpch");
      case TABLE_SCHEM:
        return Variant("tiny");
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
  string tableName;
}

enum TableInfoResultColumns {
  TABLE_CAT = 1,
  TABLE_SCHEM,
  TABLE_NAME,
  TABLE_TYPE,
  REMARKS
}
