//
//  EditableLocationData.swift
//  ShoppingList
//
//  Created by Jerry on 8/1/20.
//  Copyright © 2020 Jerry. All rights reserved.
//

import Foundation
import SwiftUI

struct EditableLocationData {
	// all of the values here provide suitable defaults for a new Location
	var locationName: String = ""
	var visitationOrder: Int = 50
	var red: Double = 0.25
	var green: Double = 0.25
	var blue: Double = 0.25
	var opacity: Double = 0.40
	
	// this copies all the editable data from an incoming Location
	init(location: Location) {
		locationName = location.name
		visitationOrder = Int(location.visitationOrder)
		red = location.red_
		green = location.green_
		blue = location.blue_
		opacity = location.opacity_
	}
	
	mutating func updateColor(from color: Color) {
		if let components = color.cgColor?.components {
			red = Double(components[0])
			green = Double(components[1])
			blue = Double(components[2])
			opacity = Double(components[3])
		}
	}
	
	// provides simple, default init with values specified above
	init() { }
	
}

