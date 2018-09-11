//
//  BimDawg_LocationTests
//  BimDawg Tests
//
//  Created by Chris on 25.09.18.
//  Copyright © 2018 chrispysoft. All rights reserved.
//

import XCTest

class BimDawg_ExtensionsTests: XCTestCase {
	
	func testArrayRegexFilter() {
		let lines = ["1", "2", "3a", "4*", "N80", "N82", "70", "71", "79", "100", "101", "107", "191"]
		let filtered = lines.filterd(byRegex: ["!?[7][0-9]", "!?[1][0-9][0-9]"])
		XCTAssertEqual(["1", "2", "3a", "4*", "N80", "N82"], filtered)
	}
	
}
