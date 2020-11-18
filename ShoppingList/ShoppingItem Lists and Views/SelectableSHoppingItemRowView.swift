//
//  SelectableSHoppingItemRowView.swift
//  ShoppingList
//
//  Created by Jerry on 11/18/20.
//  Copyright © 2020 Jerry. All rights reserved.
//

import Foundation
import SwiftUI

struct SelectableShoppingItemRowView: View {
	
	var item: ShoppingItem
	@ObservedObject var viewModel: ShoppingListViewModel
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
