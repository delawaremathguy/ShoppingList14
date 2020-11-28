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
	
	// i want this item to be an ObservedObject so it will get updated properly
	// for changes elsewhere in the program.  however, there's a significant problem
	// when this Core Data object is deleted: this view will still have a reference
	// to the deleted object.  despite forcing a Core Data update with processPendingChanges
	// upon deletions, we may still hold a reference to what is an in-memory representation
	// of the item, in which case, we must be sure that all references below are nil-coalesced.
	//
	// and, once more i am disappointed by this situation, but i see no need to worry
	// about it any more !
	
	@ObservedObject var item: ShoppingItem
	var selected: Bool
	var respondToTapOnSelector: (ShoppingItem) -> Void
	
	var body: some View {
		HStack {
			SelectionIndicatorView(selected: selected, uiColor: item.backgroundColor, sfSymbolName: "cart")
				.onTapGesture { respondToTapOnSelector(item) }
			
			// color bar at left (new in this code)
			Color(item.backgroundColor)
				.frame(width: 10, height: 36)
			
			VStack(alignment: .leading) {
				
				if item.isAvailable {
					Text(item.name)
				} else {
					Text(item.name)
						.italic()
						.foregroundColor(Color(.systemGray3))
						.strikethrough()
				}
				
				Text(item.locationName)
					.font(.caption)
					.foregroundColor(.secondary)
			}
			
			Spacer()
			
			Text("\(item.quantity)")
				.font(.headline)
				.foregroundColor(Color.blue)
			
		} // end of HStack
	}
}
