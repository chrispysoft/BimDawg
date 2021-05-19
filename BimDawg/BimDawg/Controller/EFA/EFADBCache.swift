//
//  EFADBCache.swift
//  BimDawg
//
//  Created by Chris on 27.10.18.
//  Copyright © 2018 chrispysoft. All rights reserved.
//

import Foundation
import SQLite3

public class EFADBCache {
	
	let sqliteFileName = "BimDawgCache.sqlite"
	
	public init() {
		
	}
	
	private var dbPtr: OpaquePointer?
	public func prepareDatabase() throws {
		let fileURL = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(sqliteFileName)
		guard sqlite3_open(fileURL.path, &dbPtr) == SQLITE_OK else { throw EFADBCacheError.errorOpeningSQLFile }
		
		let query = """
		CREATE TABLE IF NOT EXISTS StopLines (
			stop_id INTEGER,
			lines TEXT,
			UNIQUE(stop_id)
		);
		"""
		guard sqlite3_exec(dbPtr, query, nil, nil, nil) == SQLITE_OK else {
			let errmsg = String(cString: sqlite3_errmsg(dbPtr)!)
			throw EFADBCacheError.errorCreatingTable(errmsg)
		}
	}
	
	public func closeDatabase() {
		let result = sqlite3_close(dbPtr)
		if result != SQLITE_OK {
			let errmsg = String(cString: sqlite3_errmsg(dbPtr)!)
			NSLog("Error closing database: \(errmsg)")
		}
	}
	
	public func insert(lines: [String], stopID: Int) throws {
		let linesCSV = lines.joined(separator: ",")
		let query = String(format: "BEGIN TRANSACTION; INSERT OR REPLACE INTO StopLines (stop_id, lines) VALUES (%d, '%@'); COMMIT TRANSACTION", stopID, linesCSV)
		guard sqlite3_exec(dbPtr, query, nil, nil, nil) == SQLITE_OK else {
			let errmsg = String(cString: sqlite3_errmsg(dbPtr)!)
			throw EFADBCacheError.insertLinesFailed(errmsg)
		}
	}
	
	public func lines(for stopID: Int) throws -> [String] {
		let query = String(format: "SELECT lines FROM StopLines WHERE stop_id = %d", stopID)
		var statement: OpaquePointer?
		guard sqlite3_prepare(dbPtr, query, -1, &statement, nil) == SQLITE_OK else {
			let errmsg = String(cString: sqlite3_errmsg(dbPtr)!)
			throw EFADBCacheError.selectLinesFailed(errmsg)
		}
		
		var lines = [String]()
		
		if sqlite3_step(statement) == SQLITE_ROW {
			let linesCSV = String(cString: sqlite3_column_text(statement, 0))
			lines = linesCSV.components(separatedBy: ",")
		}
		
		return lines
	}
}

public enum EFADBCacheError: Error {
	case errorOpeningSQLFile
	case errorCreatingTable(String)
	case insertLinesFailed(String)
	case selectLinesFailed(String)
}
