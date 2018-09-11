//
//  DepartureListTableViewCell.swift
//  BimDawg
//
//  Created by Chris on 17.11.18.
//  Copyright © 2018 chrispysoft. All rights reserved.
//

import UIKit

class DepartureListTableViewCell: UITableViewCell {
	@IBOutlet weak var numberLabel: UILabel!
	@IBOutlet weak var directionLabel: UILabel!
	@IBOutlet weak var minutesLabel: UILabel!
	@IBOutlet weak var delayImageView: UIImageView!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		numberLabel.font = numberLabel.font.monospaced
		directionLabel.font = directionLabel.font.monospaced
		minutesLabel.font = minutesLabel.font.monospaced
	}
	
	var departure: Departure! {
		didSet {
			numberLabel.text = departure.servingLine.number
			directionLabel.text = departure.servingLine.cleanDirection
			minutesLabel.text = String(departure.countdown)
			
			if departure.isRealtime {
				minutesLabel.textColor = UIColor.black
			} else {
				minutesLabel.textColor = UIColor.blue
			}
			
			delayImageView.isHidden = !departure.servingLine.hasDelay
		}
	}
}



fileprivate extension UIFont {
	var monospaced: UIFont {
		let featureSettings = [[UIFontDescriptor.FeatureKey.featureIdentifier: kNumberSpacingType, UIFontDescriptor.FeatureKey.typeIdentifier: kMonospacedNumbersSelector]]
		let attributes = [UIFontDescriptor.AttributeName.featureSettings: featureSettings]
		let newFontDescriptor = fontDescriptor.addingAttributes(attributes)
		return UIFont(descriptor: newFontDescriptor, size: 0)
	}
}
