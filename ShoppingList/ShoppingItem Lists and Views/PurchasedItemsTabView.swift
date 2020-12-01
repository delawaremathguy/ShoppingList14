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
	@State private var isDeleteItemAlertShowing: Bool = false
	@State private var itemToDelete: Item?
	@State private var isAddNewItemSheetShowing = false

	@State private var itemsChecked = [Item]()
	
	
	var body: some View {
		NavigationView {
			VStack(spacing: 0) {
				SearchBarView(text: $searchText)
				
				// 1. add new item "button" is at top.  note that this will put up the AddorModifyItemView
				// inside its own NavigationView (so the Picker will work!)
				Button(action: { isAddNewItemSheetShowing = true }) {
					Text("Add New Item")
						.foregroundColor(Color.blue)
						.padding(10)
				}
				.sheet(isPresented: $isAddNewItemSheetShowing) {
					NavigationView {
						AddorModifyItemView(addItemToShoppingList: false)
					}
				}

				Rectangle()
					.frame(minWidth: 0, maxWidth: .infinity, minHeight: 1, idealHeight: 1, maxHeight: 1)

				// 2. purchased items in two sections (today's purchases and everything else)
				if purchasedItems.count == 0 {
					EmptyListView(listName: "Purchased")
				} else {
					Form {
						ForEach(sectionData()) { sectionData in
							Section(header: Text(sectionData.title).textCase(.none)) {
								ForEach(sectionData.items) { item in
									NavigationLink(destination: AddorModifyItemView(editableItem: item)) {
										SelectableItemRowView(item: item, selected: itemsChecked.contains(item),
																					sfSymbolName: "cart",
																					respondToTapOnSelector: { handleItemTapped(item) })
											.contextMenu {
												itemContextMenu(item: item,
																				deletionTrigger: {
																					itemToDelete = item
																					isDeleteItemAlertShowing = true
																				})
											} // end of contextMenu
									} // end of NavigationLink
								} // end of ForEach
							} // end of Section
						} // end of ForEach						
					}  // end of Form
					.alert(isPresented: $isDeleteItemAlertShowing) {
						Alert(title: Text("Delete \'\(itemToDelete!.name)\'?"),
									message: Text("Are you sure you want to delete this item?"),
									primaryButton: .cancel(Text("No")),
									secondaryButton: .destructive(Text("Yes"),
																		action: { Item.delete(itemToDelete!) })
						)}
					//.listStyle(PlainListStyle())
					
				} // end of if-else
			} // end of VStack
			.navigationBarTitle("Purchased List")
			.toolbar { toolbarButton() }
			
		} // end of NavigationView
		.navigationViewStyle(StackNavigationViewStyle())
		.onAppear {
			print("PurchasedTabView appear")
			searchText = ""			//viewModel.loadItems()
		}
		.onDisappear { print("PurchasedTabView disappear") }
	}
		
	func toolbarButton() -> some View {
		Button(action: { isAddNewItemSheetShowing = true }) {
			Image(systemName: "plus")
				.resizable()
				.frame(width: 20, height: 20)
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
		
		// break these out according to Today and eall the others
		let startOfToday = Calendar.current.startOfDay(for: Date())
		let itemsToday = searchQualifiedItems.filter({ $0.dateLastPurchased >= startOfToday })
		let allOlderItems = searchQualifiedItems.filter({ $0.dateLastPurchased < startOfToday })
		
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

