//
//  ChromeBrowser.swift
//  Web Tracker
//
//  Created by Skrew Everything on 12/10/17.
//  Copyright © 2017 SkrewEverything. All rights reserved.
//

import Cocoa
import ScriptingBridge

/// Scans the Chrome Browser and saves the currently opened tabs including incognito windows
public class ChromeBrowser
{
    /// `Timer` object to run the tracker periodically
    private var timer = Timer()
    
    /// Webpage Title
    private var webpageTitle: String = ""
    
    /// Webpage URL
    private var webpageURL: String = ""
    
    /// Date when scan performed
    private var date: String = ""
    
    /// Time when scan performed
    private var time: String = ""
    
    /// 0 for normal window, 1 for incognito window
    private var mode: Int = 0
    
    /// Previous list to check if the current webpages list have duplicates or not
    private var previousList: [String: [Any]] = [:]
    
    /// Current list of tabs in all windows
    private var currentList: [String: [Any]] = [:]
    
    /// Only distinct values after removing duplicates values from previousList and currentList
    private var outputList: [[Any]] = []
    
    /// Database object
    private let DB: SQLight
    
    /// Insert query
    private var query: String = ""
    
    /// Insert query compiled into byte-code. Bind the required parameters
    private var bindQuery: PreparedStatement! = nil
    
    /// Path to database file
    private let pathToDB: String
    
    /// If it's true, then it tries to create a table in the database file
    private var initial: Bool = true
    
    /**
     Starts the Timer to scan the browser
     
     - parameters:
         - time: Time in secs after which the scan should be performed. Default is 5secs
         - pathToDB: Path to the already created or to be created Database file. Default is "web-tracker.db" and it is created in the directory where the executable is present.
             It can take relative path using dot notation but `~` produces error.
     */
    init(time: Double = 5, pathToDB: String = Bundle.main.bundlePath + "/web-tracker.db")
    {
        do
        {
            self.DB = try SQLight(type: .file(pathToDB))
            self.pathToDB = pathToDB
            
        }
        catch let error as DBError
        {
            print("Error message: ",error.message, "\nError code: ",error.errorCode)
            exit(-9) // If the Database fails to open the connection, then close the application
        }
        catch // This catch is just to silent the warning in Xcode
        {
            exit(-9)
        }
        
        // Starts the Timer
        timer = Timer.scheduledTimer(timeInterval: time, target: self, selector: #selector(run), userInfo: nil, repeats: true)
        
    }
    
    /**
     Performes the scan and adds the list to the Database
     */
    @objc private func run()
    {
        let chromeObject: AnyObject = SBApplication.init(bundleIdentifier: "com.google.Chrome")!
        let chromeWindowsList = chromeObject.windows()
        
        self.currentList = [:]
        
        for eachWindow in chromeWindowsList!
        {
            let chromeTabsListInEachWindow = (eachWindow as AnyObject).tabs()
            for j in chromeTabsListInEachWindow!
            {
                self.webpageTitle = (j as AnyObject).title // Always define the data type explicitly to avoid the ambiguous error
                self.webpageURL = (j as AnyObject).url
                let mode: String = (eachWindow as AnyObject).mode
                if mode.caseInsensitiveCompare("incognito") == .orderedSame
                {
                    //print("incognito")
                    self.mode = 1
                }
                else
                {
                    //print("normal")
                    self.mode = 0
                }
                
                self.date = self.getDate()
                self.time = self.getTime()
                
                // Add it to the dictionary
                self.currentList[self.webpageURL] = [self.webpageURL, self.webpageTitle, self.mode, self.time, self.date]
            }
        }
        
        
        if self.previousList.count == 0 // Initial run
        {
            for ( _ , array) in self.currentList // Copy all the entries from currentlist to outputlist and previouslist
            {
                self.outputList.append(array)
            }
        }
        else
        {
            for (url, array) in self.currentList
            {
                if self.previousList[url] == nil // Check if the URL is present in the previous list. If not, then add it to the outputlist
                {
                    self.outputList.append(array)
                }
            }
        }
        
        //print("=======================")
        //print(self.outputList)
        //print("=======================")
        self.previousList = self.currentList
        self.addToDB()

 
    }
    
    /**
     Add the list to the Database
     */
    private func addToDB()
    {
        do
        {
            if self.initial
            {
                self.createTable()
                self.initial = false
                self.query = "insert into data values(@url, @title, @incognito, @time, @date);"
                self.bindQuery = try PreparedStatement(SQLQuery: self.query, SQLightDB: self.DB)
            }

            for row in self.outputList
            {
                try self.bindQuery.bindValues(row)
                let _ = try self.bindQuery.modify() //inserted data into database here
                self.bindQuery.resetBindValues()
            }
            
            // Clear the outputList after the list is inserted into the database
            self.outputList = []
        }
        catch let error as DBError
        {
            print("Error message: ",error.message, "\nError code: ",error.errorCode)
        }
        catch let error // This catch is just to silent the warning in Xcode
        {
            print(error)
        }
    }
    
    /**
     Creates a new table - `data`
     */
    private func createTable()
    {
        do
        {
            let createQuery = "create table data(url varchar, title varchar, incognito int, time varchar, date varchar);"
            let createPS = try PreparedStatement(SQLQuery: createQuery, SQLightDB: self.DB)
            let _ = try createPS.modify()
            
        }
        catch let error as DBError
        {
            if error.message.contains("already exists")
            {
                // Leave it
            }
            else
            {
                print("Error message: ",error.message, "\nError code: ",error.errorCode)
            }
        }
        catch let error // This catch is just to silent the warning in Xcode
        {
            print(error)
        }
    }
    
    /**
     Get the current Date
     
     - returns:
     Current Date as String
     */
    private func getDate() -> String
    {
        let calendar = Calendar.current
        return "\(calendar.component(.day, from: Date()))-\(calendar.component(.month, from: Date()))-\(calendar.component(.year, from: Date()))"
    }
    
    /**
     Get the current Time
     
     - returns:
     Current Time as String
     */
    private func getTime() -> String
    {
        let calendar = Calendar.current
        return "\(calendar.component(.hour, from: Date())):\(calendar.component(.minute, from: Date()))"
    }
    
    deinit {
        try! self.bindQuery.destroy()
        try! self.DB.close()
    }
}
