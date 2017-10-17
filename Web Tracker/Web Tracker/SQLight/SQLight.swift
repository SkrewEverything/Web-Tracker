//
//  SQLight.swift
//  
//  SQLight
//
//  Created by Skrew Everything on 29/06/17.
//  Copyright © 2017 SkrewEverything. All rights reserved.
//

import Foundation

public class SQLight
{
    /// Pointer to the opened connection of a database
    internal private(set) var dbPointer: OpaquePointer!
    
    /// Name of the Database
    public private(set) var databaseName: String
    
    /// Current version of the SQLite
    public let SQLiteVersion: String = SQLITE_VERSION
    
    /// Opens a connection to a new or existing SQLite database.
    /// # More Info:
    /// [https://sqlite.org/c3ref/open.html]()
    /// - parameter type: There are 2 possible values.
    ///     * **DBType.inMemory**: Creates Database in RAM
    ///     * **DBType.file(String)**: Creates or opens Database file specified by name as an argument
    /// - returns: Database object which can be used to execute, close.
    /// - throws: If any error occurs while opening the connection to the database.
    init(type: DBType) throws
    {
        switch type
        {
        case .inMemory:
            self.databaseName = ":memory:"
        case .file(let databaseName):
            self.databaseName = databaseName
        }
        
        // Opens a connection to a database mentioned by the DBType
        try self.open()
        
    }
    
    /// Opens a connection to a new or existing SQLite database.
    /// # More Info:
    /// [https://sqlite.org/c3ref/open.html]()
    /// - throws: If any error occurs while opening the connection to the database.
    private func open() throws
    {
        var db: OpaquePointer? = nil
        let rc = sqlite3_open(self.databaseName, &db)
        if rc != SQLITE_OK
        {
            throw DBError(db: self, ec: rc)
        }
        self.dbPointer = db!
    }
    
    /// Closes the connection to the database.
    /// # More Info:
    /// [https://sqlite.org/c3ref/close.html]()
    /// - throws: If any error occurs while closing the connection to the database.
    public func close() throws
    {
        let rc = sqlite3_close(self.dbPointer)
        if rc != SQLITE_OK
        {
            throw DBError(db: self, ec: rc)
        }
    }
    
}
























