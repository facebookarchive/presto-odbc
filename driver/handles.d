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

import sqlext;

import bindings : ColumnBinding, OdbcResult, EmptyOdbcResult;
import util;

/**
 * APD
 * Information about application buffers bound to the parameters in an SQL statement
 * such as their addresses, lengths, and C datatypes
 */
final class ApplicationParameterDescriptor : OdbcDescriptorImpl {
  this(OdbcConnection connection) {
    super(connection);
  }
}

/**
 * IPD
 * Information about parameters in an SQL statement,
 * such as their datatypes, lengths, and nullability
 */
final class ImplementationParameterDescriptor : OdbcDescriptorImpl {
  this(OdbcConnection connection) {
    super(connection);
  }
}

/**
 * ARD
 * Information about application buffers bound to the columns in a result set,
 * such as their addresses, lengths, and C datatypes
 */
final class ApplicationRowDescriptor : OdbcDescriptorImpl {
  this(OdbcConnection connection) {
    super(connection);
  }

  ColumnBinding[uint] columnBindings;
}

/**
 * IRD
 * Information about columns in a result set,
 * such as their datatypes, lengths, and nullability
 */
final class ImplementationRowDescriptor : OdbcDescriptorImpl {
  this(OdbcConnection connection) {
    super(connection);
  }
}

/**
 * An OdbcDescriptor is a handle to a specific type of descriptor. In particular, one of:
 *  1. Application Parameter Descriptor (APD)
 *  2. Implementation Parameter Descriptor (IPD)
 *  3. Application Row Descriptor (ARD)
 *  4. Implementation Row Descriptor (IRD)
 * It does not know which type it is at construction.
 */
final class OdbcDescriptor {
  this(OdbcConnection connection) {
    dllEnforce(connection !is null);
    this.connection = connection;
    connection.explicitlyAllocatedDescriptors[this] = true;
  }

  private this(OdbcConnection connection, OdbcDescriptorImpl impl) {
    dllEnforce(connection !is null);
    this.connection = connection;
    this.impl = impl;
  }

  void setThisDescriptorAs();

  OdbcConnection connection;
  OdbcDescriptorImpl impl = null;
}

private abstract class OdbcDescriptorImpl {
  this(OdbcConnection connection) {
    dllEnforce(connection !is null);
    this.connection = connection;
  }

  OdbcDescriptorImpl newImpl(this T)() {
    return T(connection);
  }

  OdbcConnection connection;
}


/**
 * An OdbcStatement handle object is allocated for each HSTATEMENT requested by the driver/client.
 */
final class OdbcStatement {
  this(OdbcConnection connection) {
    dllEnforce(connection !is null);
    this.connection = connection;
    this.latestOdbcResult = new EmptyOdbcResult();
    this.applicationParameterDescriptor = new ApplicationParameterDescriptor(connection);
    this.implementationParameterDescriptor = new ImplementationParameterDescriptor(connection);
    this.applicationRowDescriptor = new ApplicationRowDescriptor(connection);
    this.implementationRowDescriptor = new ImplementationRowDescriptor(connection);
  }

  OdbcConnection connection;

  wstring query() {
    return query_;
  }

  void query(wstring query) {
    executedQuery = false;
    query_ = query;
  }

  private wstring query_;
  bool executedQuery;
  OdbcResult latestOdbcResult;
  OdbcException[] errors;
  SQLULEN rowArraySize = 1;
  SQLULEN* rowsFetched;
  RowStatus* rowStatusPtr;


  void applicationParameterDescriptor(ApplicationParameterDescriptor apd) {
    applicationParameterDescriptor_ = new OdbcDescriptor(connection, apd);
  }

  void implementationParameterDescriptor(ImplementationParameterDescriptor ipd) {
    implementationParameterDescriptor_ = new OdbcDescriptor(connection, ipd);
  }

  void applicationRowDescriptor(ApplicationRowDescriptor ard) {
    applicationRowDescriptor_ = new OdbcDescriptor(connection, ard);
  }

  void implementationRowDescriptor(ImplementationRowDescriptor ird) {
    implementationRowDescriptor_ = new OdbcDescriptor(connection, ird);
  }

  ApplicationParameterDescriptor applicationParameterDescriptor() {
    return cast(ApplicationParameterDescriptor) applicationParameterDescriptor_.impl;
  }

  ImplementationParameterDescriptor implementationParameterDescriptor() {
    return cast(ImplementationParameterDescriptor) implementationParameterDescriptor_.impl;
  }

  ApplicationRowDescriptor applicationRowDescriptor() {
    return cast(ApplicationRowDescriptor) applicationRowDescriptor_.impl;
  }

  ImplementationRowDescriptor implementationRowDescriptor() {
    return cast(ImplementationRowDescriptor) implementationRowDescriptor_.impl;
  }

  OdbcDescriptor applicationParameterDescriptor_;
  OdbcDescriptor implementationParameterDescriptor_;
  OdbcDescriptor applicationRowDescriptor_;
  OdbcDescriptor implementationRowDescriptor_;
}

final class OdbcConnection {
  this(OdbcEnvironment environment) {
    dllEnforce(environment !is null);
    this.environment = environment;
  }

  OdbcEnvironment environment;
  bool[OdbcDescriptor] explicitlyAllocatedDescriptors;
}

final class OdbcEnvironment {

}
