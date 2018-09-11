//
//  IndicatorView.swift
//  BimDawg
//
//  Created by Chris on 28.10.18.
//  Copyright © 2018 chrispysoft. All rights reserved.
//

import UIKit

class IndicatorView: UIView {
	let strokeColor = UIColor.lightGray
	let filllColor = UIColor.purple.withAlphaComponent(0.7)
	private let indicationTimeout: TimeInterval = 1.0
	private var inactivationTimer: Timer?
	private var triggerCount = 0
	private var isActive = false { didSet { setNeedsDisplay() } }
	
	
	func trigger() {
		triggerCount += 1
		isActive = true
		inactivationTimer?.invalidate()
		inactivationTimer = Timer.scheduledTimer(timeInterval: indicationTimeout, target: self, selector: #selector(setInactive), userInfo: nil, repeats: false)
	}
	
	@objc func setInactive() {
		isActive = false
		inactivationTimer?.invalidate()
	}
	
	
	override func draw(_ rect: CGRect) {
		let drwRct = self.bounds.insetBy(dx: 7, dy: 7)
		let path = UIBezierPath()
		path.move(to: CGPoint(x: drwRct.minX, y: drwRct.maxY))
		path.addLine(to: CGPoint(x: drwRct.midX, y: drwRct.minY))
		path.addLine(to: CGPoint(x: drwRct.maxX, y: drwRct.maxY))
		path.addLine(to: CGPoint(x: drwRct.minX, y: drwRct.maxY))
		path.close()
		
		strokeColor.setStroke()
		path.stroke()
		
		if isActive {
			filllColor.setFill()
			path.fill()
		}
		
		if triggerCount >= 1 {
			let text = NSString(format: "%d", triggerCount)
			let textStyle = NSMutableParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
			textStyle.alignment = NSTextAlignment.center
			let textAttributes = [
				NSAttributedStringKey.font: UIFont.systemFont(ofSize: 12),
				NSAttributedStringKey.foregroundColor: isActive ? UIColor.white : UIColor.black,
			]
			let textSize = NSAttributedString(string: text as String, attributes: textAttributes).size()
			let drawRect = CGRect(x: self.bounds.midX-textSize.width/2, y: self.bounds.midY-textSize.height/2 + 2, width: textSize.width, height: textSize.height)
			text.draw(in: drawRect, withAttributes: textAttributes)
		}
	}
}
