
import std.array : front, empty, popFront;
import std.conv : text, to;
import std.variant : Variant;
import facebook.json : JSONValue, JSON_TYPE;

import sqlext;
import odbcinst;

import bindings : OdbcResult, OdbcResultRow;
import util : dllEnforce, logMessage;

void addToPrestoResultRow(JSONValue columnData, PrestoResultRow result) {
  final switch (columnData.type) {
  case JSON_TYPE.STRING:
    result.addNextValue(Variant(columnData.str));
    break;
  case JSON_TYPE.INTEGER:
    result.addNextValue(Variant(columnData.integer));
    break;
  case JSON_TYPE.FLOAT:
    result.addNextValue(Variant(columnData.floating));
    break;
  case JSON_TYPE.TRUE:
    result.addNextValue(Variant(true));
    break;
  case JSON_TYPE.FALSE:
    result.addNextValue(Variant(false));
    break;
  case JSON_TYPE.NULL:
    result.addNextValue(Variant(null));
    break;
  case JSON_TYPE.OBJECT:
  case JSON_TYPE.ARRAY:
  case JSON_TYPE.UINTEGER:
    dllEnforce(false, "Unexpected JSON type: " ~ text(columnData.type));
    break;
  }
}

final class PrestoResult : OdbcResult {
  void addRow(PrestoResultRow r) {
    dllEnforce(r.numberOfColumns() != 0, "Row has at least 1 column");
    results_ ~= r;
    numberOfColumns_ = r.numberOfColumns();
  }

  @property {
    bool empty() {
      return results_.empty;
    }

    PrestoResultRow front() {
      assert(!empty);
      return results_.front;
    }

    void popFront() {
      results_.popFront();
    }

    uint numberOfColumns() {
      return numberOfColumns_;
    }

    void columnMetadata(immutable(ColumnMetadata)[] data) {
      if (!columnMetadata_) {
        columnMetadata_ = data;
      }
    }

    auto columnMetadata() const {
      return columnMetadata_;
    }
  }

private:
  PrestoResultRow[] results_;
  immutable(ColumnMetadata)[] columnMetadata_ = null;
  uint numberOfColumns_ = 0;
}

final class PrestoResultRow : OdbcResultRow {
  void addNextValue(Variant v) {
    data ~= v;
  }

  Variant dataAt(int column) {
    assert(column >= 1);
    return data[column - 1];
  }

  uint numberOfColumns() {
    dllEnforce(!data.empty, "Row has 0 columns");
    return cast(uint) data.length;
  }
private:
  Variant[] data;
}
