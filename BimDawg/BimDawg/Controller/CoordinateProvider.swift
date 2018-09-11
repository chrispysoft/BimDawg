//
//  CoordinateProvider.swift
//  BimDawg
//
//  Created by Chris on 17.09.18.
//  Copyright © 2018 chrispysoft. All rights reserved.
//

import Foundation
import CoreLocation

public class CoordinateProvider: NSObject, CLLocationManagerDelegate {
	enum UpdateResult {
		case success(CLLocation)
		case failure(Error)
	}
	typealias UpdateHandler = (UpdateResult) -> Void
	var updateHandler: UpdateHandler?
	
	private let locationManager = CLLocationManager()
	
	
	public override init() {
		super.init()
		locationManager.desiredAccuracy = kCLLocationAccuracyBest
		locationManager.delegate = self
	}
	
	
	// MARK: - CLLocationManagerDelegate
	private var previousLocation: CLLocation?
	
	public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		guard let newLocation = locations.last else { return }
		if let previousLocation = previousLocation {
			if newLocation.distance(from: previousLocation) > 0 {
				updateHandler?(.success(newLocation))
			}
		} else {
			updateHandler?(.success(newLocation))
		}
		previousLocation = newLocation
	}
	
	public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		updateHandler?(.failure(error))
	}
	
	
	public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
		switch status {
		case .notDetermined:
			locationManager.requestWhenInUseAuthorization()
		case .restricted:
			updateHandler?(.failure(CoordinateProviderError.accessRestricted))
		case .denied:
			updateHandler?(.failure(CoordinateProviderError.accessDenied))
		case .authorizedAlways, .authorizedWhenInUse:
			locationManager.startUpdatingLocation()
		}
	}
}


enum CoordinateProviderError: CustomNSError {
	case accessRestricted
	case accessDenied
	
	var localizedDescription: String {
		switch self {
		case .accessRestricted:
			return "Location Access restricted. Please change privileges."
		case .accessDenied:
			return "Location Access denied. Please change privileges."
		}
	}
	
	var errorUserInfo: [String : Any] {
		return [NSLocalizedDescriptionKey: localizedDescription]
	}
}
