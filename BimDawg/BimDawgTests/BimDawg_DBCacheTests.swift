//
//  BimDawg_DBCacheTests.swift
//  BimDawg
//
//  Created by Chris on 27.10.18.
//  Copyright © 2018 chrispysoft. All rights reserved.
//

import XCTest
import BimDawg

class BimDawg_DBCacheTests: XCTestCase {
	
	func test_createDatabase() {
		let cache = EFADBCache()
		XCTAssertNoThrow(
			try cache.prepareDatabase()
		)
		cache.closeDatabase()
	}
	
	func test_insertUpdateAndRead() {
		let cache = EFADBCache()
		let stopID = 666
		let lines1 = ["1", "2", "38"]
		let lines2 = ["2", "3", "39"]
		let expectedLines = lines2
		var returnedLines = [String]()
		XCTAssertNoThrow(
			try cache.prepareDatabase()
		)
		XCTAssertNoThrow(
			try cache.insert(lines: lines1, stopID: stopID)
		)
		XCTAssertNoThrow(
			try cache.insert(lines: lines2, stopID: stopID)
		)
		XCTAssertNoThrow(
			returnedLines = try cache.lines(for: stopID)
		)
		cache.closeDatabase()
		
		XCTAssertEqual(returnedLines, expectedLines)
	}
}
