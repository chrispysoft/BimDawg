//
//  Array+RegexFilter.swift
//  BimDawg
//
//  Created by Chris on 25.09.18.
//  Copyright © 2018 chrispysoft. All rights reserved.
//

import Foundation

public extension Sequence where Element == String {
	public func filterd(byRegex expressions: [String]) -> [String] {
		var result = [String]()
		for string in self {
			var tempReplace = string
			for expr in expressions {
				guard let regex = try? NSRegularExpression(pattern: expr) else { return [] }
				tempReplace = regex.stringByReplacingMatches(in: tempReplace, options: [], range: NSRange(location: 0, length: tempReplace.count), withTemplate: "")
			}
			if tempReplace.count > 0 {
				result.append(tempReplace)
			}
		}
		return result
	}
}
