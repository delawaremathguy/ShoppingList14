//
//  String+Extnesions.swift
//  ShoppingList
//
//  Created by Jerry on 11/18/20.
//  Copyright © 2020 Jerry. All rights reserved.
//

import Foundation

extension String {
	func appearsIn(_ str: String) -> Bool {
		let cleanedSearchText = self.trimmingCharacters(in: .whitespacesAndNewlines)
		if cleanedSearchText.isEmpty {
			return true
		}
		return str.localizedCaseInsensitiveContains(cleanedSearchText)
	}
}
