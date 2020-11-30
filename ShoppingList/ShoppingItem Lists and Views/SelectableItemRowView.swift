//
//  SelectableItemRowView.swift
//  ShoppingList
//
//  Created by Jerry on 11/28/20.
//  Copyright © 2020 Jerry. All rights reserved.
//

import Foundation
import SwiftUI

struct SelectableItemRowView: View {
	
	// on initialization, this collects the item's data, plus the color and name associated
	// with the item's location
	var itemData: EditableItemData
	var locationName: String
	var uiColor: UIColor
	
	// selected is whether the item is selected or not.  executing the respondToTapOnSelector
	// function will cause the parent view's @State variable to redraw its view,
	// re-instantiating this view as well.
	var selected: Bool
	var sfSymbolName: String
	var respondToTapOnSelector: () -> ()
	
	init(item: Item, selected: Bool, sfSymbolName: String, respondToTapOnSelector: @escaping () -> Void) {
		// copy item data to local variables
		itemData = EditableItemData(item: item)
		locationName = item.locationName
		uiColor = item.uiColor
		self.selected = selected
		self.sfSymbolName = sfSymbolName
		self.respondToTapOnSelector = respondToTapOnSelector
		
		//print("SelectableItemRowView instantiated for \(item.name)")
	}
	
	var body: some View {
		HStack {
			SelectionIndicatorView(selected: selected, uiColor: uiColor, sfSymbolName: sfSymbolName)
				.onTapGesture { respondToTapOnSelector() }
			
			// color bar at left
			Color(uiColor)
				.frame(width: 10, height: 36)
			
			VStack(alignment: .leading) {
				
				if itemData.isAvailable {
					Text(itemData.name)
				} else {
					Text(itemData.name)
						.italic()
						.strikethrough()
				}
				
				Text(locationName)
					.font(.caption)
					.foregroundColor(.secondary)
			}
			
			Spacer()
			
			Text("\(itemData.quantity)")
				.font(.headline)
				.foregroundColor(Color.blue)
			
		} // end of HStack
	}
}
