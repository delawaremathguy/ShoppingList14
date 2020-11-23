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

struct PurchasedTabView: View {
	
	// the usual @State variables to handle the Search field and control
	// the action of the confirmation alert that you really do want to
	// delete an item
	@State private var searchText: String = ""
	@State private var isDeleteItemAlertShowing: Bool = false
	@State private var itemToDelete: ShoppingItem?
	@State private var isAddNewItemSheetShowing = false
	@StateObject var viewModel = ShoppingListViewModel(type: .purchasedItemShoppingList)
	
	@State private var itemsChecked = [ShoppingItem]()
	
	
	var body: some View {
		NavigationView {
			VStack(spacing: 0) {
				SearchBarView(text: $searchText)
				
				// 1. add new item "button" is at top.  note that this will put up the AddorModifyShoppingItemView
				// inside its own NavigationView (so the Picker will work!)
				Button(action: { self.isAddNewItemSheetShowing = true }) {
					Text("Add New Item")
						.foregroundColor(Color.blue)
						.padding(10)
				}
				.sheet(isPresented: $isAddNewItemSheetShowing) {
					NavigationView {
						AddorModifyShoppingItemView(addItemToShoppingList: false)
					}
				}
				
				if viewModel.itemCount == 0 {
					EmptyListView(listName: "Purchased")
				} else {
					
					// Report purchased item count, or the number of items matching the
					// current search text, essentially as a section header for just the one section
					SLSimpleHeaderView(label: sectionHeaderTitle())
					Form {
						
						// 1. Items purchased today
						if viewModel.hasItemsForToday(containing: searchText) {
							Section(header: Text("Purchased Today").textCase(.none)) {
								ForEach(viewModel.itemsForToday(containing: searchText)) { item in
									NavigationLink(destination: AddorModifyShoppingItemView(editableItem: item)) {
										SelectableShoppingItemRowView(item: item, viewModel: viewModel, selected: itemsChecked.contains(item), respondToTapOnSelector: handleItemTapped)
												.contextMenu {
													shoppingItemContextMenu(item: item, deletionTrigger: {
																										itemToDelete = item
																										isDeleteItemAlertShowing = true
																									})
												} // end of contextMenu
										} // end of NavigationLink
								} // end of ForEach
							} // end of Section
						}
						
						// 2. all items purchased earlier
						Section(header: Text("Purchased Yesterday or Earlier").textCase(.none)) {
							ForEach(viewModel.itemsEarlierThanToday(containing: searchText)) { item in
								NavigationLink(destination: AddorModifyShoppingItemView(editableItem: item)) {
									SelectableShoppingItemRowView(item: item, viewModel: viewModel, selected: itemsChecked.contains(item), respondToTapOnSelector: handleItemTapped)
										.contextMenu {
											shoppingItemContextMenu(item: item,
																							deletionTrigger: {
																								self.itemToDelete = item
																								self.isDeleteItemAlertShowing = true
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
									secondaryButton: .destructive(Text("Yes"), action: deleteSelectedItem)
						)}
					
					//.listStyle(PlainListStyle())
					
				} // end of if-else
			} // end of VStack
			.navigationBarTitle("Purchased List")
			.toolbar { toolbarButton() }
			//					)
			
		} // end of NavigationView
		.navigationViewStyle(StackNavigationViewStyle())
		.onAppear {
			print("PurchasedTabView appear")
			self.searchText = ""
			self.viewModel.loadItems()
		}
		.onDisappear { print("PurchasedTabView disappear") }
	}
	
	func toolbarButton() -> some View {
		Button(action: { self.isAddNewItemSheetShowing = true }) {
			Image(systemName: "plus")
				.resizable()
				.frame(width: 20, height: 20)
		}
	}
	
	func handleItemTapped(_ item: ShoppingItem) {
		if !itemsChecked.contains(item) {
			itemsChecked.append(item)
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
				item.toggleOnListStatus()
				self.itemsChecked.removeAll(where: { $0 == item })
			}
		}
	}
	
	func deleteSelectedItem() {
		if let item = itemToDelete {
			ShoppingItem.delete(item: item, saveChanges: true)
		}
	}
	
	
	func sectionHeaderTitle() -> String {
		if searchText.isEmpty {
			return "Items Listed: \(viewModel.itemCount)"
		}
		let itemsShowing = viewModel.items.filter({ searchText.appearsIn($0.name) })
		return "Items Matching \"\(searchText)\": \(itemsShowing.count)"
	}
	
}

