//
//  PurchasedItemView.swift
//  ShoppingList
//
//  Created by Jerry on 5/14/20.
//  Copyright © 2020 Jerry. All rights reserved.
//

import SwiftUI

// a simple list of items that are not on the current shopping list
// these are the items that were on the shopping list at some time and
// were later removed -- items we purchased.  you could also call it a
// catalog, of sorts, although we only show items that we know about
// that are not already on the shopping list.

struct PurchasedItemsTabView: View {
	
	// this is the @FetchRequest that ties this view to CoreData
	@FetchRequest(fetchRequest: Item.fetchAllItems(onList: false))
	private var purchasedItems: FetchedResults<Item>
	
	// the usual @State variables to handle the Search field and control
	// the action of the confirmation alert that you really do want to
	// delete an item
	@State private var searchText: String = ""

	// parameters to control triggering an Alert and defining what action
	// to take upon confirmation
	@State private var confirmationAlert = ConfirmationAlert(type: .none)
	@State private var isAddNewItemSheetShowing = false
	
	// local state for are we a multisection display or not.  the default here is false,
	// but an eager developer could easily store this default value in UserDefaults (?)
	@State var multiSectionDisplay: Bool = false

	// link in to what is the start of today
	@EnvironmentObject var today: Today
	//@State private var startOfToday = Calendar.current.startOfDay(for: Date())
	
	@State private var itemsChecked = [Item]()
	
	
	var body: some View {
		NavigationView {
			VStack(spacing: 0) {
				
/* ---------
1. search bar & add new item "button" is at top.  note that the button action will put up the
AddorModifyItemView inside its own NavigationView (so the Picker will work!)
---------- */

				SearchBarView(text: $searchText)

				Button(action: { isAddNewItemSheetShowing = true }) {
					Text("Add New Item")
						.foregroundColor(Color.blue)
						.padding(10)
				}
				.sheet(isPresented: $isAddNewItemSheetShowing) {
					NavigationView { AddorModifyItemView() }
				}

				Rectangle()
					.frame(minWidth: 0, maxWidth: .infinity, minHeight: 1, idealHeight: 1, maxHeight: 1)

/* ---------
2. we display either a "List is Empty" view, or the sectioned list of purchased
items.  there is some complexity here, so review the ShoppingListDisplay.swift code
for more discussion about sectioning
---------- */

				if purchasedItems.count == 0 {
					EmptyListView(listName: "Purchased")
				} else {
					// notice use of sectioning strategy that is described in ShoppingListDisplay.swift
					Form {
						ForEach(sectionData()) { section in
							Section(header: Text(section.title).sectionHeader()) {
								ForEach(section.items) { item in
									// display of a single item
									NavigationLink(destination: AddorModifyItemView(editableItem: item)) {
										SelectableItemRowView(item: item,
																					selected: itemsChecked.contains(item),
																					sfSymbolName: "cart",
																					respondToTapOnSelector: { handleItemTapped(item) })
											.contextMenu {
												itemContextMenu(item: item,
																				deletionTrigger: {
																					confirmationAlert.trigger(type: .deleteItem(item))
																				})
											} // end of contextMenu
									} // end of NavigationLink
								} // end of ForEach
							} // end of Section
						} // end of ForEach						
					}  // end of Form
				} // end of if-else
			} // end of VStack
			.navigationBarTitle("Purchased List")
			.toolbar {
				ToolbarItem(placement: .navigationBarLeading, content: sectionDisplayButton)
				ToolbarItem(placement: .navigationBarTrailing, content: addNewButton)
			}
			.alert(isPresented: $confirmationAlert.isShowing) { confirmationAlert.alert() }

		} // end of NavigationView
		.navigationViewStyle(StackNavigationViewStyle())
		.onAppear(perform: handleOnAppear)
		.onDisappear() { print("PurchasedTabView disappear") }
	}
	
	func handleOnAppear() {
		print("PurchasedTabView appear")
		// clear searchText, get a clean screen
		searchText = ""
		// and also recompute what "today" means, so the sectioning is correct
		today.update()
	}
		
	// makes a simple "+" to add a new item
	func addNewButton() -> some View {
		Button(action: { isAddNewItemSheetShowing = true }) {
			Image(systemName: "plus")
				.font(.title2)
		}
	}
	
	// a toggle button to change section display mechanisms
	func sectionDisplayButton() -> some View {
		Button(action: { multiSectionDisplay.toggle() }) {
			Image(systemName: multiSectionDisplay ? "tray.2" : "tray")
				.font(.title2)
		}
	}

	
	func handleItemTapped(_ item: Item) {
		if !itemsChecked.contains(item) {
			// put into our list of what's about to be removed, and because
			// itemsChecked is a @State variable, we will see a momentary
			// animation showing the change.
			itemsChecked.append(item)
			// queue the removal to allow animation to run
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.40) {
				item.toggleOnListStatus()
				itemsChecked.removeAll(where: { $0 == item })
			}
		}
	}
	
	// the idea of this function is to break out the purchased Items into
	// 2 sections: those purchased today, and everything else
	func sectionData() -> [SectionData] {
		// reduce items by search criteria
		let searchQualifiedItems = purchasedItems.filter({ searchText.appearsIn($0.name) })
		
		// do we show one big section, or Today and then everything else?  one big section
		// is pretty darn easy:
		if !multiSectionDisplay {
			if searchText.isEmpty {
				return [SectionData(title: "Items Purchased: \(purchasedItems.count)",
														items: purchasedItems.map({ $0 }))]
			}
			return [SectionData(title: "Items Purchased containing: \"\(searchText)\": \(searchQualifiedItems.count)",
													items: searchQualifiedItems)]
		}
		
		// break these out according to Today and all the others
		let itemsToday = searchQualifiedItems.filter({ $0.dateLastPurchased >= today.start })
		let allOlderItems = searchQualifiedItems.filter({ $0.dateLastPurchased < today.start })
		
		// determine titles
		var section1Title = "Items Purchased Today: \(itemsToday.count)"
		if !searchText.isEmpty {
			section1Title = "Items Purchased Today containing \"\(searchText)\": \(itemsToday.count)"
		}
		var section12Title = "Items Purchased Earlier: \(allOlderItems.count)"
		if !searchText.isEmpty {
			section12Title = "Items Purchased Earlier containing \"\(searchText)\": \(allOlderItems.count)"
		}
		
		// return two sections only
		return [SectionData(title: section1Title, items: itemsToday),
						SectionData(title: section12Title,items: allOlderItems)
		]
	}

}
