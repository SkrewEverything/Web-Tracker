//
//  CustomTypes.swift
//
//  SQLight
//
//  Created by Skrew Everything on 29/06/17.
//  Copyright © 2017 SkrewEverything. All rights reserved.
//

import Foundation


/* https://stackoverflow.com/questions/26883131/sqlite-transient-undefined-in-swift/26884081#26884081
 
 
 */
internal let SQLITE_STATIC = unsafeBitCast(0, to: sqlite3_destructor_type.self)
internal let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)


///Callback closure type
public typealias SQLiteExecCallBack = @convention(c) (_ void: UnsafeMutableRawPointer?, _ columnCount: Int32, _ values: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?, _ columns:UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32


/// Specifies what type of DataBase to use
///
/// There are 2 possible values.
/// * **DBType.inMemory**: Creates Database in RAM
/// * **DBType.file(String)**: Creates or opens Database file specified by name as an argument
public enum DBType
{
    case inMemory
    case file(String)
}

/**
 Required to cast to appropriate data type while using "select" query.
 
 Taken from -> https://sqlite.org/c3ref/c_blob.html
 
 #define SQLITE_INTEGER  1
 #define SQLITE_FLOAT    2
 #define SQLITE_BLOB     4
 #define SQLITE_NULL     5
 #ifdef SQLITE_TEXT
 # undef SQLITE_TEXT
 #else
 # define SQLITE_TEXT     3
 #endif
 #define SQLITE3_TEXT     3
 
 */
internal enum SQLiteDataType: Int32
{
    case integer = 1, float, text, blob, null
}



/// Error thrown by SQLight
public struct DBError: Error
{
    let message: String
    let errorCode: Int32
    
    init(db: SQLight, ec: Int32, customMessage: String? = nil)
    {
        self.errorCode = ec
        if let cm = customMessage
        {
            self.message = cm
        }
        else if String(cString: sqlite3_errmsg(db.dbPointer)) == "not an error"
        {
            self.message = String(cString: sqlite3_errstr(ec))
        }
        else
        {
            self.message = String(cString: sqlite3_errmsg(db.dbPointer))
        }
    }
}

extension DBError: LocalizedError
{
    public var errorDescription: String? {
        return self.message
    }
}








