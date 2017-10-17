//
//  main.swift
//  Web Tracker
//
//  Created by Skrew Everything on 12/10/17.
//  Copyright © 2017 SkrewEverything. All rights reserved.
//

import Foundation


let args = CommandLine.arguments

if args.count == 3 // If time and path both are specified
{
    if let time = Double(args[1]) // If first argument is time
    {
        let _ = ChromeBrowser(time: time, pathToDB: args[2])
    }
    else if let time = Double(args[2]) // If second argument is time
    {
        let _ = ChromeBrowser(time: time, pathToDB: args[1])
    }
}
else if args.count == 2 // If only one of them is specified
{
    if let time = Double(args[1]) // Time is specified
    {
        let _ = ChromeBrowser(time: time)
    }
    else // Path is specified
    {
        let _ = ChromeBrowser(pathToDB: args[1])
    }
}
else  // Nothing is specified
{
    let _ = ChromeBrowser()
}

RunLoop.main.run()
