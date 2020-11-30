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
				
				if purchasedItems.count == 0 {
					EmptyListView(listName: "Purchased")
				} else {
					
					Rectangle()
						.frame(minWidth: 0, maxWidth: .infinity, minHeight: 1, idealHeight: 1, maxHeight: 1)
					Form {
						
						// 1. Items purchased today
						Section(header: Text(todaySectionTitle()).textCase(.none)) {
							// think about sorting this section in order of purchase ???
							ForEach(purchasedItems.filter({ qualifiedItem($0, today: true) })) { item in
								NavigationLink(destination: AddorModifyItemView(editableItem: item)) {
									SelectableItemRowView(item: item, selected: itemsChecked.contains(item),
																				sfSymbolName: "cart",
																				respondToTapOnSelector: { handleItemTapped(item) })
										.contextMenu {
											itemContextMenu(item: item, deletionTrigger: {
												itemToDelete = item
												isDeleteItemAlertShowing = true
											})
										} // end of contextMenu
								} // end of NavigationLink
							} // end of ForEach
						} // end of Section
						
						// 2. all items purchased earlier
						Section(header: Text(otherPurchasesSectionTitle()).textCase(.none)) {
							ForEach(purchasedItems.filter({ qualifiedItem($0, today: false) })) { item in
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
	
	func qualifiedItem(_ item: Item, today: Bool) -> Bool {
		if !searchText.appearsIn(item.name) {
			return false
		} else if today {
			return item.dateLastPurchased >= Calendar.current.startOfDay(for: Date())
		} else {
			return item.dateLastPurchased < Calendar.current.startOfDay(for: Date())
		}
	}
	
	func todaySectionTitle() -> String {
		let count = purchasedItems.filter({ qualifiedItem($0, today: true) }).count
		if searchText.isEmpty {
		 return "Items Purchased Today: \(count)"
		}
		return "Items Purchased Today containing \"\(searchText)\": \(count)"
	}
	
	func otherPurchasesSectionTitle() -> String {
		let count = purchasedItems.filter({ qualifiedItem($0, today: false) }).count
		if searchText.isEmpty {
			return "Items Purchased Earlier: \(count)"
		}
		return "Items Purchased Earlier containing \"\(searchText)\": \(count)"
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
			// queue the actual removal to allow animation to run
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.40) {
				item.toggleOnListStatus()
				itemsChecked.removeAll(where: { $0 == item })
			}
		}
	}

}

