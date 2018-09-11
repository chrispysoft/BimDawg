//
//  EFA_Tests.swift
//  BimDawgTests
//
//  Created by Chris on 04.11.18.
//  Copyright © 2018 chrispysoft. All rights reserved.
//

import XCTest
import BimDawg
import CoreLocation

class EFA_Tests: XCTestCase {
	
	func test_stopsForLocation() {
		let client = EFAClient()
		let request = EFAClient.StopRequest.coordinate(latitude: 48.327994, longitude: 14.284898)
		let expectation = XCTestExpectation()
		client.loadStops(for: request) { (result) in
			switch result {
			case .success(let stops):
				print(stops.map{$0.name})
			case .failure(let error):
				XCTFail(error.localizedDescription)
			}
			expectation.fulfill()
		}
		wait(for: [expectation], timeout: 10.0)
	}
	
	func test_stopsForName() {
		let client = EFAClient()
		let request = EFAClient.StopRequest.searchText("Harbach")
		let expectation = XCTestExpectation()
		let expectedStops = ["Linz/Donau, Linz Harbach", "Linz/Donau, Linz Harbachschule", "Linz/Donau, Linz Harbachsiedlung", "Linz/Donau, Linz VH Harbach"]
		client.loadStops(for: request) { (result) in
			switch result {
			case .success(let servedStops):
				XCTAssertEqual(expectedStops, servedStops.map{$0.name})
			case .failure(let error):
				XCTFail(error.localizedDescription)
			}
			expectation.fulfill()
		}
		wait(for: [expectation], timeout: 10.0)
	}
	
//	func test_LinesForStop() {
//		let client = EFAClient()
//		let stopID = "60501030"
//		let expectedLineNumbes = ["1", "2", "N82", "38"]
//		let expectation = XCTestExpectation()
//		client.loadLines(for: stopID) { (result) in
//			switch result {
//			case .success(let lines):
//				let loadedLineNumbers = lines.map{$0.number}
//				XCTAssertEqual(loadedLineNumbers, expectedLineNumbes)
//			case .failure(let error):
//				XCTFail(error.localizedDescription)
//			}
//			expectation.fulfill()
//		}
//		wait(for: [expectation], timeout: 10.0)
//	}
	
	func test_departuresForStop() {
		let client = EFAClient()
		let stopID = "60501030"
		let expectation = XCTestExpectation()
		client.loadDepartures(for: stopID) { (result) in
			switch result {
			case .success(let departures):
				print(departures.map{$0.servingLine.number})
			case .failure(let error):
				XCTFail(error.localizedDescription)
			}
			expectation.fulfill()
		}
		wait(for: [expectation], timeout: 10.0)
	}
	
//    func test_stopsForTrip() {
//        let client = EFAClient()
//        let originStopID = "60501030"
//        //let destinationName = "Linz/Donau, Linz solarCity"
//        let destinationStopID = "60500296"
//        let expectation = XCTestExpectation()
//        client.loadTrip(from: originStopID, to: destinationStopID) { (result) in
//            switch result {
//            case .success(let departures):
//                print(departures)
//            case .failure(let error):
//                XCTFail(error.localizedDescription)
//            }
//            expectation.fulfill()
//        }
//        wait(for: [expectation], timeout: 10.0)
//    }
	
}
