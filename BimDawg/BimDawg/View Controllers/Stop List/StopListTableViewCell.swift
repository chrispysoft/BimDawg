//
//  StopListTableViewCell.swift
//  BimDawg
//
//  Created by Chris on 17.11.18.
//  Copyright © 2018 chrispysoft. All rights reserved.
//

import UIKit

class StopListTableViewCell: UITableViewCell {
	@IBOutlet var stopNameLabel: UILabel!
	@IBOutlet var distanceLabel: UILabel!
	weak var stopListModel: StopListModel?
	var stop: Stop? { didSet {
		updateLabels()
	}}
	
	private func updateLabels() {
		if let stop = stop  {
			stopNameLabel.text = stop.name
			distanceLabel.text = String(stop.distance ?? 0) + " m"
        } else {
            stopNameLabel.text = ""
            distanceLabel.text = ""
        }
		
	}
}
