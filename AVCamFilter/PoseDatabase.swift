//
//  PoseDatabase.swift
//  AVCamFilter
//
//  Created by 권나영 on 2020/11/15.
//  Copyright © 2020 Apple. All rights reserved.
//

import Foundation
import SQLite3

private func createSQLiteFile() {
    let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) .appendingPathComponent("db.sqlite")
    if sqlite3_open(fileURL.path, &db) != SQLITE_OK { print("error opening database") }else{ print("SUCESS opening database") }
    
}



/// Open SQLite Database
private func openSQLite(path: String) -> OpaquePointer? {
    
    var database: OpaquePointer? = nil
    
    // Many of the SQLite functions return an Int32 result code. Most of these codes are defined as constants in the SQLite library. For example, SQLITE_OK represents the result code 0.
    guard sqlite3_open(path, &database) == SQLITE_OK else {
        print("‼️ Unable to open database.")
        return nil
    }
    
    // Success Open SQLite Database
    print("✅ Successfully opened connection to database at \(path)")
    return database
}

/// Create SQLite Database Table
private func createSQLiteTable(database: OpaquePointer, statement: String) -> Bool {
    
    var createStatement: OpaquePointer? = nil
    
    // You must always call sqlite3_finalize() on your compiled statement to delete it and avoid resource leaks.
    defer { sqlite3_finalize(createStatement) }
        
    guard sqlite3_prepare_v2(database, statement, EOF, &createStatement, nil) == SQLITE_OK else {
        print("‼️ CREATE TABLE statement could not be prepared.")
        return false
    }
    
    // sqlite3_step() runs the compiled statement.
    if sqlite3_step(createStatement) == SQLITE_DONE {
        print("✅ Success, Contact table created.")
    } else {
        print("‼️ Fail, Contact table could not be created.")
    }
    
    return true
}

/// Insert Data into SQLite Database Table
private func insertSQLiteTable(database: OpaquePointer, statement: String) -> Bool {
    
    var insertStatement: OpaquePointer? = nil
    
    // You must always call sqlite3_finalize() on your compiled statement to delete it and avoid resource leaks.
    defer { sqlite3_finalize(insertStatement) }
    
    guard sqlite3_prepare_v2(database, statement, EOF, &insertStatement, nil) == SQLITE_OK else {
        print("‼️ Insert TABLE statement could not be prepared.")
        return false
    }
    
    // Use the sqlite3_step() function to execute the statement and verify that it finished.
    if sqlite3_step(insertStatement) == SQLITE_DONE {
        print("✅ Success, Insert Data.")
    } else {
        print("‼️ Fail, Insert Data.")
    }
    
    return true
}

/// Implement Query SQLite
private func qeurySQLite(database: OpaquePointer, statment: String) -> Bool {
    
    var queryStatment: OpaquePointer? = nil
    
    // You must always call sqlite3_finalize() on your compiled statement to delete it and avoid resource leaks.
    defer { sqlite3_finalize(queryStatment) }
    
    guard sqlite3_prepare_v2(database, statment, EOF, &queryStatment, nil) == SQLITE_OK else {
        print("‼️ Query statement could not be prepared.")
        return false
    }
    
    while sqlite3_step(queryStatment) == SQLITE_ROW {
        
        let id = sqlite3_column_int(queryStatment, 0)
        let name = sqlite3_column_text(queryStatment, 1)
        
        print("→ \(id) | \(String(describing: name))")
    }
    
    return true
}

func initDB() {
    guard let db = openSQLite(path: "./pose.db") else {
        assert(false, "‼️ Fail, Open SQLite Database.")
    }

    /*
    let createStatment: String = """
    
    """
    
    //background landscape = 1, street = 2, wall = 3, mirror = 4, sunset = 5
    //style all = 0, normal =1 , funny=2, cool = 3
    //etc none =0,  heatt 1 , selfie 2 sitdown 3
    

    if createSQLiteTable(database: db, statement: createStatment) {
        print("✅ Success, Create SQLite Table.")
    }

    let insertStatment: String = "INSERT INTO pose (id, filename, persons, background, style, etc) VALUES (0, \"pose0.png\", 1, 1,1,0 );"
    if insertSQLiteTable(database: db, statement: insertStatment) {
        print("✅ Success, Insert data into SQLite Table.")
    }
    
    let queryStatment: String = "SELECT * FROM Contact;"
    if qeurySQLite(database: db, statment: queryStatment) {
        print("✅ Success, Query SQLite.")
    }
     */
}


