//
//  DepartureDetailController.swift
//  BimDawg
//
//  Created by Chris on 26.10.18.
//  Copyright © 2018 chrispysoft. All rights reserved.
//

import UIKit

class DepartureDetailController: UIViewController {
	@IBOutlet var numberLabel: UILabel!
	@IBOutlet var directionLabel: UILabel!
	@IBOutlet var scheduleTimeLabel: UILabel!
	@IBOutlet var realTimeLabel: UILabel!
	@IBOutlet var delayInfoLabel: UILabel!
	@IBOutlet var departureExpiredLabel: UILabel!
	
	var departure: Departure? {
		didSet {
			updateLabels()
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		updateLabels()
	}
	
	private func updateLabels() {
		guard self.isViewLoaded else { return }
		
		if let departure = departure {
			numberLabel.text = departure.servingLine.number
			directionLabel.text = departure.servingLine.cleanDirection
			scheduleTimeLabel.text = departure.dateTime.timeString
			realTimeLabel.text = departure.realDateTime?.timeString
			
			if departure.servingLine.hasDelay {
				delayInfoLabel.text = "Delayed"
			} else {
				delayInfoLabel.text = nil
			}
			delayInfoLabel.isHidden = !departure.servingLine.hasDelay
		}
		else {
			numberLabel.isHidden = true
			directionLabel.isHidden = true
			scheduleTimeLabel.isHidden = true
			realTimeLabel.isHidden = true
			delayInfoLabel.isHidden = true
			departureExpiredLabel.isHidden = false
		}
	}
}
