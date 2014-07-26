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
module presto.odbcdriver.prestoresults;

import std.array : front, empty, popFront;
import std.conv : text, to;
import std.variant : Variant;
import facebook.json : JSONValue, JSON_TYPE;

import odbc.sqlext;
import odbc.odbcinst;

import presto.client.queryresults : ColumnMetadata;

import presto.odbcdriver.bindings : OdbcResult, OdbcResultRow;
import presto.odbcdriver.util : dllEnforce, logMessage;

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

    override bool empty() const {
        return results_.empty;
    }

    override inout(PrestoResultRow) front() inout {
        assert(!empty);
        return results_.front;
    }

    override void popFront() {
        results_.popFront();
    }

    override size_t numberOfColumns() {
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

private:
    PrestoResultRow[] results_;
    immutable(ColumnMetadata)[] columnMetadata_ = null;
    size_t numberOfColumns_ = 0;
}

final class PrestoResultRow : OdbcResultRow {
    void addNextValue(Variant v) {
        data ~= v;
    }

    override Variant dataAt(int column) {
        dllEnforce(column >= 1);
        return data[column - 1];
    }

    size_t numberOfColumns() {
        dllEnforce(!data.empty, "Row has 0 columns");
        return cast(uint) data.length;
    }
private:
    Variant[] data;
}
