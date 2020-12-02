//
//  ContentView.swift
//  ShoppingList
//
//  Created by Jerry on 4/22/20.
//  Copyright © 2020 Jerry. All rights reserved.
//

import SwiftUI

struct ShoppingListTabView: View {
	
	// this is the @FetchRequest that ties this view to CoreData Items
	@FetchRequest(fetchRequest: Item.fetchAllItems(onList: true))
	private var itemsToBePurchased: FetchedResults<Item>

	// local state to trigger showing a sheet to add a new item
	@State private var isAddNewItemSheetShowing = false
	// local state to trigger an Alert to confirm either deleting
	// an item, or moving all items off the list
	@State private var isConfirmationAlertShowing = false
	// which of these we do: move all off-list (true) or delete (false)
	@State private var operationIsMoveToOtherList = false
	// and in the case of a delete, which item we are deleting
	@State private var itemToDelete: Item?
	
	// local state for are we a multisection display or not.  the default here is false,
	// but an eager developer could easily store this default value in UserDefaults (?)
	@State var multiSectionDisplay: Bool = false
	
	var body: some View {
		NavigationView {
			VStack(spacing: 0) {
				
/* ---------
1. add new item "button" is at top.  note that this will put up the
AddorModifyItemView inside its own NavigationView (so the Picker will work!)
---------- */
				
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
2. we display either a "List is Empty" view, a single-section shopping list view
or multi-section shopping list view.  the display has some complexity to it because
of the sectioning, so we push it off to a specialized View.
---------- */

				if itemsToBePurchased.count == 0 {
					EmptyListView(listName: "Shopping")
				} else {
					ShoppingListView(multiSectionDisplay: multiSectionDisplay,
													 isConfirmationAlertShowing: $isConfirmationAlertShowing,
													 itemToDelete: $itemToDelete)
				}
				
/* ---------
3. for non-empty lists, we have a few buttons at the end for bulk operations
---------- */

				if itemsToBePurchased.count > 0 {
					Rectangle()
						.frame(minWidth: 0, maxWidth: .infinity, minHeight: 1, idealHeight: 1, maxHeight: 1)
					
					SLCenteredButton(title: "Move All Items Off-list", action: {
						// setting these allow the Alert to come up with the right messages and actions
						operationIsMoveToOtherList = true
						isConfirmationAlertShowing = true
						})
						.padding([.bottom, .top], 6)
					
					if !itemsToBePurchased.allSatisfy({ $0.isAvailable }) {
						SLCenteredButton(title: "Mark All Items Available",
														 action: { itemsToBePurchased.forEach({ $0.markAvailable() }) })
							.padding([.bottom], 6)
						
					}
				} //end of if itemsToBePurchased.count > 0

			} // end of VStack
			.navigationBarTitle("Shopping List")
			.navigationBarItems(leading: leadingButton())
			.toolbar { toolBarButton() }
			.alert(isPresented: $isConfirmationAlertShowing) {
				Alert(title: Text(confirmationAlertTitle()),
							message: Text(confirmationAlertMessage()),
							primaryButton: .cancel(Text("No"), action: destructiveAlertCancel),
							secondaryButton: .destructive(Text("Yes"), action: destructiveAlertAction)
				)
			}

		} // end of NavigationView
		.navigationViewStyle(StackNavigationViewStyle())
			.onAppear {
				print("ShoppingListTabView appear")
				//viewModel.loadItems()
			}
			.onDisappear { print("ShoppingListTabView disappear") }
		
	} // end of body: some View
	
	// MARK: - NavigationBarItems
	
	// a "+" symbol to support adding a new item
	func toolBarButton() -> some View {
		Button(action: { isAddNewItemSheetShowing = true })
			{ Image(systemName: "plus") }
	}
	
	// a toggle button to change section display mechanisms
	func leadingButton() -> some View {
		Button(action: {
			multiSectionDisplay.toggle()
		}) {
			Image(systemName: multiSectionDisplay ? "tray.2" : "tray")
				.font(.title2)
		}
	}
	
	// MARK: - Confirmation Alert Setup
	
	// these functions data to pass along to the confirmation alert that either deletes
	// an item or moves all items off the list, based on the boolean "operationIsMoveToOtherList"
	func confirmationAlertTitle() -> String {
		if operationIsMoveToOtherList {
			return "Move All Items Off-List"
		} else {
			return "Delete \'\(itemToDelete!.name)\'?"
		}
	}
	
	func confirmationAlertMessage() -> String {
		if operationIsMoveToOtherList {
			return ""
		} else {
			return "Are you sure you want to delete this item?"
		}
	}
	
	func destructiveAlertCancel() {
		operationIsMoveToOtherList = false
	}
	
	func destructiveAlertAction() {
		if operationIsMoveToOtherList {
			itemsToBePurchased.forEach({ $0.toggleOnListStatus() })
			operationIsMoveToOtherList = false
		} else if let item = itemToDelete {
			Item.delete(item)
		}
	}

} // end of ShoppingListTabView


