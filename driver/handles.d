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
 * About Descriptor Handles:
 * 1) There are 4 "sub-handle-types" that fall into this category.
 *    They seem to have very little in common other than they must all produce
 *    answers to the same set of queries from SQLGetDescField and SQLGetDescRec
 *    (and must also work with the setter variants of those functions).
 * 2) Because these sub-handles are queried using the same enum values, but expected
 *    to give distinct answers, I believe that virtual functions are an appropriate
 *    representation.
 *
 * Design complications:
 * 1) An instance of each of the descriptor types is automatically "implicitly" (in ODBC language)
 *     allocated for each OdbcStatement.
 * 2) The application can "explicitly" allocate new ARD or APD sub-handle-types
 *     with AllocHandle and then change the members of an OdbcStatement handle to
 *     those "explicitly" allocated handles instead.
 * 3) Explicitly allocated handles have a lifetime that matches the OdbcConnection
 *     handle it is constructed with, not the OdbcStatement it is assigned to.
 *     Explicitly allocated handles must therefore also tell any OdbcStatement that
 *     is using it that it is being destroyed so they can go back to "implicit" handles.
 * 4) Explicitly allocated handles can be assigned to multiple OdbcStatements.
 * 5) When a handle is "explicitly" allocated, you do not know whether it will become
 *     an ARD or APD until it is assigned to a statement. Because the user may set it
 *     to more than one statement, this means a level of indirection is needed so that
 *     the user can continue using the same pointer that they got from AllocHandle in
 *     the first place. This is why I have an OdbcDescriptorImpl class.
 *
 * Alternative design considered:
 * Could have had all of the required data for each descriptor sub-type in the same class.
 * Could have used a discriminated union. This would mean more switches, but removes the
 * need for the Impl class/indirection/allocation. Could have ignored the need to have a
 * descriptor type at all and jammed everything into OdbcStatement, which is how this
 * project originally grew. I'm still not certain that I fully understand what all descriptor
 * sub-types store and where they would store it. At a minimum, the IPD and IRD types may be
 * much more transparent to the user because they cannot ever be set. One reason to separate
 * these things out is so that implementing the function SQLCopyDesc is easy/maintainable.
 */

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

    this(OdbcConnection connection, OdbcDescriptorImpl impl) {
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
        this.latestOdbcResult = makeWithoutGC!EmptyOdbcResult();
        this.applicationParameterDescriptor = makeWithoutGC!ApplicationParameterDescriptor(connection);
        this.implementationParameterDescriptor = makeWithoutGC!ImplementationParameterDescriptor(connection);
        this.applicationRowDescriptor = makeWithoutGC!ApplicationRowDescriptor(connection);
        this.implementationRowDescriptor = makeWithoutGC!ImplementationRowDescriptor(connection);
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
        applicationParameterDescriptor_ = makeWithoutGC!OdbcDescriptor(connection, apd);
    }

    void implementationParameterDescriptor(ImplementationParameterDescriptor ipd) {
        implementationParameterDescriptor_ = makeWithoutGC!OdbcDescriptor(connection, ipd);
    }

    void applicationRowDescriptor(ApplicationRowDescriptor ard) {
        applicationRowDescriptor_ = makeWithoutGC!OdbcDescriptor(connection, ard);
    }

    void implementationRowDescriptor(ImplementationRowDescriptor ird) {
        implementationRowDescriptor_ = makeWithoutGC!OdbcDescriptor(connection, ird);
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
    string endpoint; //Host and port
    string catalog;
    string schema;
    string userId;
    string authentication;
    OdbcException[] errors;
}

final class OdbcEnvironment {

}
