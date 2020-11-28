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
	
	@ObservedObject var item: ShoppingItem
	var selected: Bool
	var respondToTapOnSelector: (ShoppingItem) -> Void
	
	var body: some View {
		HStack {
			SelectionIndicatorView(selected: selected, uiColor: item.backgroundColor, sfSymbolName: "cart")
				.onTapGesture { respondToTapOnSelector(item) }
			ShoppingItemRowView(itemData: ShoppingItemRowData(item: item))
		} // end of HStack
	}
}
