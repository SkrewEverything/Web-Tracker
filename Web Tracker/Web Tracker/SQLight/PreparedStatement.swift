//
//  PreparedStatement.swift
//  SQLight
//
//  Created by Skrew Everything on 30/06/17.
//  Copyright © 2017 SkrewEverything. All rights reserved.
//

import Foundation

public class PreparedStatement
{
    /// SQL Query of the prepared statement
    public let SQLQuery: String
    
    /// Compiled SQL Query: byte-code
    internal var preparedStatement: OpaquePointer!
    
    /// Database connection currently opened where queries need to be executed
    private let db: SQLight
    
    /// Compiles SQL query into a byte-code for execution.
    /// - Note: To execute an SQL query, it must first be compiled into a byte-code program
    /// - parameter SQLQuery: Any SQL query
    /// - parameter SQLightDB: Object returned from SQLight(type:)
    /// - throws: If any error occurs during compiling. Mostly syntax errors.
    init(SQLQuery: String, SQLightDB: SQLight) throws
    {
        self.SQLQuery = SQLQuery
        self.db = SQLightDB
        self.preparedStatement = try self.prepareStatement()
        
    }
    
    /// Compiles SQL query into a byte-code for execution.
    /// - Note: To execute an SQL query, it must first be compiled into a byte-code program
    /// # More Info:
    /// [https://sqlite.org/c3ref/prepare.html]()
    ///
    /// Using: `sqlite3_prepare_v2()`
    /// - returns: Compiled SQL Query which can be used to execute
    /// - throws: If any error occurs during compiling. Mostly syntax errors.
    private func prepareStatement() throws -> OpaquePointer
    {
        /// Temporary prepared statement(byte-code) to return
        var pStmt: OpaquePointer? = nil
        // Third parameter can be -1 but giving length of string can increase performance slightly
        let rc = sqlite3_prepare_v2(self.db.dbPointer, self.SQLQuery, -1, &pStmt, nil)
        if rc != SQLITE_OK
        {
            throw DBError(db: self.db, ec: rc)
        }
        if pStmt == nil
        {
            throw DBError(db: self.db, ec: rc)
        }

        return pStmt!
    }
    
    /// Bind values from left to right in prepared statement.
    /// - parameter elements: All the values/elements to bind to prepared statement
    /// - throws: If any error occurs while binding values
    public func bindValues(_ elements: [Any]) throws
    {
        var parameterIndexesandElements = [Int:Any]()
        var index = 1
        for i in elements
        {
            parameterIndexesandElements[index] = i
            index += 1
        }
        try self.bind(parameterIndexesandElements)
    }
    
    /// Bind values based on parameter name.
    /// - parameter parameterNamesandElements: Parameter name as key and Binding value as value in the form of dictionary
    /// - throws: If any error occurs while binding values
    public func bindValues(_ parameterNamesandElements: [String:Any]) throws
    {
        var parameterIndexesandElements = [Int:Any]()
        for i in parameterNamesandElements
        {
            parameterIndexesandElements[self.getParameterIndex(parameterName: i.key)] = i.value
        }
        try self.bind(parameterIndexesandElements)
    }
    
    /// Bind values based on parameter index.
    /// - parameter parameterIndexesandElements: Parameter index as key and Binding value as value in the form of dictionary
    /// - throws: If any error occurs while binding values
    public func bindValues(_ parameterIndexesandElements: [Int:Any]) throws
    {
        try self.bind(parameterIndexesandElements)
    }
    
    /// Bind values based on parameter index.
    /// - parameter parameterIndexesandElements: Parameter index as key and Binding value as value in the form of dictionary
    /// - throws: If any error occurs while binding values
    private func bind(_ parameterIndexesandElements: [Int:Any]) throws
    {
        var rc: Int32 = 0
        for i in parameterIndexesandElements
        {
            if i.value is Int
            {
                rc = sqlite3_bind_int(self.preparedStatement, Int32(i.key), Int32(i.value as! Int))
            }
            else if i.value is String
            {
                rc = sqlite3_bind_text(self.preparedStatement, Int32(i.key), i.value as! String, Int32((i.value as! String).lengthOfBytes(using: .utf8)), SQLITE_TRANSIENT)
            }
            else if i.value is Double
            {
                rc = sqlite3_bind_double(self.preparedStatement, Int32(i.key), i.value as! Double)
            }
            else
            {
                print("Unknown datatype")
                throw DBError(db: self.db, ec: 0, customMessage: "Unknown type or blob and null not supported")
            }
            
            if rc != SQLITE_OK
            {
                throw DBError(db: self.db, ec: rc)
            }
        }
    }
    
    /// Number of bind parameters in a prepared statement.
    /// - returns: Number of bind parameters.
    public func getParameterCount() -> Int
    {
        let count = sqlite3_bind_parameter_count(self.preparedStatement)
        return Int(count)
    }
    
    /// Get the parameter index using parameter name
    /// - note: Index starts from **1**, not from **0**.
    /// - parameter parameterName: Name of the parameter
    /// - returns: Index of the specified parameter.
    public func getParameterIndex(parameterName: String) -> Int
    {
        let id = sqlite3_bind_parameter_index(self.preparedStatement, parameterName)
        return Int(id)
    }
    
    /// Parameter name specified by index
    /// - note: Index starts from **1**, not from **0**.
    /// - parameter parameterIndex: Index of the required bind paramter.
    /// - returns: Parameter name or nil.
    public func getParameterName(parameterIndex: Int) -> String?
    {
        if let name = sqlite3_bind_parameter_name(self.preparedStatement, Int32(parameterIndex))
        {
            return String(cString: name)
        }
        else
        {
            return nil
        }
    }
    
    /// Returns column names in `SELECT` statement.
    /// - returns: Column names as `String` array. If the statement is not `SELECT` then `nil` is returned.
    public func getColumnNames() -> [String]?
    {
        if SQLQuery.lowercased().contains("select")
        {
            var columns = [String]()
            for i in 0..<sqlite3_column_count(self.preparedStatement)
            {
                columns.append(String(cString: sqlite3_column_name(self.preparedStatement, Int32(i))))
            }
            return columns
        }
        else
        {
            return nil
        }
    }
    
    
    /// Executes all types of SQL queries.
    /// - note: Doesn't support binding of values.
    /// # More Info:
    /// [https://sqlite.org/c3ref/exec.html]()
    /// - parameter callbackForSelectQuery: Closure or func literal which is called for every row retrieved for SELECT command.
    ///   Pass nil for other commands. callback is used for SELECT commands only.
    /// - throws: If any error occurs while exeuting the command/query.
    public func execute(callbackForSelectQuery callback: SQLiteExecCallBack?) throws
    {
        var zErrMsg:UnsafeMutablePointer<Int8>? = nil
        var rc: Int32 = 0
        rc = sqlite3_exec(self.db.dbPointer, self.SQLQuery, callback ?? nil , nil, &zErrMsg)

        if rc != SQLITE_OK
        {
            let msg = String(cString: zErrMsg!)
            sqlite3_free(zErrMsg)
            throw DBError(db: self.db, ec: rc, customMessage: msg)
        }
    }
    
    /// Executes a query (which modifies the table like `UPDATE`, `INSERT`, `DELETE` etc).
    /// - note: Use `fetchAllRows(preparedStatement:)` or `fetchNextRow(preparedStatement:)` to execute queries with **SELECT**.
    /// - returns: Number of rows changed.
    /// - throws: If any error occurs while exeuting the command/query.
    public func modify() throws -> Int
    {
        let rc = sqlite3_step(self.preparedStatement)
        if rc == SQLITE_DONE // SQLITE_DONE is returned for sql queries other than select query(it returns SQLITE_ROW)
        {

            /*
             The sqlite3_reset() function is called to reset a prepared statement object back to its initial state, ready to be re-executed.
             It does not change the values of any bindings on the prepared statement
             Use sqlite3_clear_bindings() to reset the bindings.
             */
            try self.reset()
            return Int(sqlite3_changes(self.db.dbPointer))
        }
        else
        {
            try self.reset()
            throw DBError(db: self.db, ec: rc, customMessage: "")
        }
        
    }
    
    /// Executes and returns all the rows while using `SELECT` query.
    /// - warning: If the data being retrieved is large, it is advised not to use this method as all the retrieved rows are stored in the memory and returned. Use `fetchNextRow(preparedStatement:)` as it returns only 1 row at a time or use `execute(SQLQuery:callbackForSelectQuery:)` which uses closure
    /// - returns: All the retrieved rows and columns as a 2D Array
    /// - throws: If any error occurs while exeuting the command/query.
    public func fetchAllRows() throws -> [[Any]]
    {
        var data = [[Any]]()
        var data1 = [Any]()
        while true
        {
            let rc = sqlite3_step(self.preparedStatement)
            if  rc == SQLITE_ROW // SQLITE_ROW is returned for select query. Other queries returns SQLITE_DONE
            {
                for i in 0..<sqlite3_column_count(self.preparedStatement)
                {
                    let type = sqlite3_column_type(self.preparedStatement, i)
                    switch type
                    {
                    case SQLiteDataType.integer.rawValue:
                        data1.append(sqlite3_column_int(self.preparedStatement, i))
                    case SQLiteDataType.float.rawValue:
                        data1.append(sqlite3_column_double(self.preparedStatement, i))
                    case SQLiteDataType.text.rawValue:
                        data1.append(String(cString: sqlite3_column_text(self.preparedStatement, i)))
                    case SQLiteDataType.blob.rawValue:
                        print("It is BLOB!") // should do something
                    case SQLiteDataType.null.rawValue:
                        print("It is NULL!")
                    default:
                        print("Just to stop crying of swift.")
                    }
                }
                data.append(data1)
                data1.removeAll()
            }
            else if rc == SQLITE_DONE
            {
                break;
            }
            else
            {
                try self.reset()
                throw DBError(db: self.db, ec: rc)
            }
        }
        /*
         The sqlite3_reset() function is called to reset a prepared statement object back to its initial state, ready to be re-executed.
         It does not change the values of any bindings on the prepared statement
         Use sqlite3_clear_bindings() to reset the bindings.
         */
        try self.reset()
        return data
        
    }
    
    /// Executes and returns 1 row for every call while using `SELECT` query.
    /// - returns: A row is returned as an array. If there is no row left to return, nil is returned.
    /// - throws: If any error occurs while exeuting the command/query.
    public func fetchNextRow() throws -> [Any]?
    {
        var data = [Any]()
        let rc = sqlite3_step(self.preparedStatement)
        if  rc == SQLITE_ROW // SQLITE_ROW is returned for select query. Other queries returns SQLITE_DONE
        {
            for i in 0..<sqlite3_column_count(self.preparedStatement)
            {
                let type = sqlite3_column_type(self.preparedStatement, i)
                switch type
                {
                case SQLiteDataType.integer.rawValue:
                    data.append(sqlite3_column_int(self.preparedStatement, i))
                case SQLiteDataType.float.rawValue:
                    data.append(sqlite3_column_double(self.preparedStatement, i))
                case SQLiteDataType.text.rawValue:
                    data.append(String(cString: sqlite3_column_text(self.preparedStatement, i)))
                case SQLiteDataType.blob.rawValue:
                    print("It is BLOB!") // should do something
                case SQLiteDataType.null.rawValue:
                    print("It is NULL!")
                default:
                    print("Just to stop crying of swift.")
                }
            }
            
        }
        else if rc == SQLITE_DONE
        {
            try self.reset()
            return nil
        }
        else
        {
            try self.reset()
            throw DBError(db: self.db, ec: rc)
        }
        
        return data
        
    }
    /// Resets a prepared statement object back to its initial state, ready to be re-executed.
    /// - note: It does not change the values of any bindings on the prepared statement. Use sqlite3_clear_bindings() to reset the bindings.
    /// # More Info:
    /// [https://sqlite.org/c3ref/reset.html]()
    /// - throws: If any error occurs while resetting the prepared statement.
    public func reset() throws
    {
        let rc = sqlite3_reset(self.preparedStatement)
        if rc != SQLITE_OK
        {
            throw DBError(db: self.db, ec: rc)
        }
    }
    
    /// Removes all the bindings on a prepared statement
    public func resetBindValues()
    {
        sqlite3_clear_bindings(self.preparedStatement)
    }
    
    /// The application must destroy every prepared statement in order to avoid resource leaks.
    /// - warning: It is a grievous error for the application to try to use a prepared statement after it has been finalized. Any use of a prepared statement after it has been finalized can result in undefined and undesirable behavior such as segfaults and heap corruption.
    /// # More Info :
    /// [https://sqlite.org/c3ref/finalize.html]()
    /// - throws: If any error occurs while destroying the prepared statement.
    public func destroy() throws
    {
        let rc = sqlite3_finalize(self.preparedStatement)
        if rc != SQLITE_OK
        {
            throw DBError(db: self.db, ec: rc)
        }
    }


}
