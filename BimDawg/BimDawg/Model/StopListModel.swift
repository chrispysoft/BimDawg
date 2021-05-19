//
//  StopListModel.swift
//  BimDawg
//
//  Created by Chris on 01.01.18.
//  Copyright © 2018 chrispysoft. All rights reserved.
//

import CoreLocation

class StopListModel: NSObject {
    
    private static let DistanceDelta: CLLocationDistance = 30 // distance from last location when to reload data
	
    
	public var currentLocation: CLLocation? { didSet {
		verifyLocationChange()
	}}
	
	
	// MARK: - Verify Location Change
	private var lastNextStop: Stop?
	
    // reload stops when distance delta > DistanceOffset
	private func verifyLocationChange() {
		guard let currentLocation = currentLocation else { NSLog("currentLocation is nil"); return }
		if let lastClosestStop = actualStops.first {
			let currDistance = currentLocation.distance(from: lastClosestStop.location!)
//			NSLog("last: " + lastActualStop.name + " dist: " + String(format: "%.0f", currDistance))
            if currDistance > StopListModel.DistanceDelta {
				loadStops()
			}
		} else {
			loadStops()
		}
	}
	
	
	// MARK: - Accessors
	var paused: Bool = false
	var numberOfStops: Int {
		return actualStops.count
	}
	
	func stop(at index: Int) -> Stop? {
		guard actualStops.indices.contains(index) else { return nil }
		return actualStops[index]
	}
	
	
	// MARK: - Load Stops
	private var actualStops: [Stop] = []
	private var stopLoadingBusy = false
	
	public func loadStops() {
		if paused { return }
		guard let currentLocation = currentLocation else { NSLog("coordinate is nil"); return }
		guard stopLoadingBusy == false else { NSLog("stopLoadingBusy"); return }
		stopLoadingBusy = true
		
		let client = EFAClient()
		let lat = currentLocation.coordinate.latitude, lon = currentLocation.coordinate.longitude
		client.loadStops(for: .coordinate(latitude: lat, longitude: lon)) { [weak self] (result) in
			switch result {
			case .success(let stops):
				self?.actualStops = stops
				self?.callUpdateHandler(with: .success)
				
			case .failure(let error):
				self?.actualStops = []
				self?.callUpdateHandler(with: .failure(error))
			}
			
			self?.stopLoadingBusy = false
		}
	}
	
	
	// MARK: - Update Handler
	enum UpdateResult {
		case success
		case failure(Error)
	}
	typealias UpdateHandler = (UpdateResult) -> Void
	
	public var updateHandler: UpdateHandler?
	
	private func callUpdateHandler(with result: UpdateResult) {
		updateHandler?(result)
	}
	
	
	
	/*
	typealias StopInfoCompletion = ([Line]) -> Void
	
	class StopInfoCache {
		static let shared = StopInfoCache()
		var requestedStops: [Stop] = []
		var stopLines: [Stop : [Line]] = [:]
	}
	
	func loadLines(for stop: Stop, completion: @escaping StopInfoCompletion) {
		let cache = StopInfoCache.shared
		
		if let lines = cache.stopLines[stop] {
			completion(lines)
		}
		else {
			if !cache.requestedStops.contains(stop) {
				cache.requestedStops.append(stop)
				NSLog("Get lines for \(stop.name)")
				let efaClient = EFAClient()
				efaClient.loadLines(for: stop.id) { (result) in
					let lines: [Line]
					
					switch result {
					case .success(let data):
						lines = (data as! [Line]).uniqueElements()
						cache.stopLines[stop] = lines
					case .failure(let error):
						lines = []
						NSLog(error.localizedDescription)
					}
					
					completion(lines)
				}
			}
		}
	}
	*/
}


extension Line: Equatable {
	public static func ==(lhs: Line, rhs: Line) -> Bool {
		return lhs.number == rhs.number
	}
}

extension Stop: Equatable {
	public static func ==(lhs: Stop, rhs: Stop) -> Bool {
		return lhs.id == rhs.id
	}
}

extension Stop: Hashable {
	public var hashValue: Int {
		return id.hashValue ^ name.hashValue
	}
}

extension Array where Element: Equatable {
	func uniqueElements() -> [Element] {
		var uniqueElements = [Element]()
		for element in self {
			if !uniqueElements.contains(element) { uniqueElements.append(element) }
		}
		return uniqueElements
	}
}
