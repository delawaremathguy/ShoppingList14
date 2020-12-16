//
//  ContentView.swift
//  ShoppingList
//
//  Created by Jerry on 4/22/20.
//  Copyright © 2020 Jerry. All rights reserved.
//

import SwiftUI

// this is a struct to collect the data needed to run the confirmation alert
// that we use to confirm that the user either wants to move all items off the list
// (they might hit this button accidentally and lose the whole shopping list) or
// delete an item.

struct ConfirmationTrigger {
	
	enum AlertType {
		case none
		case moveAllOffShoppingList
		case deleteItem(Item)
	}
	
	var type: AlertType
	var isConfirmationAlertShowing: Bool = false

	mutating func trigger(type: AlertType) {
		self.type = type
		isConfirmationAlertShowing = true
	}
	
	// strings to pass along to an alert when it comes up, depending on type
	func title() -> String {
		switch type {
			case .none: return ""
			case .moveAllOffShoppingList: return "Move All Items Off-List"
			case .deleteItem(let item): return "Delete \'\(item.name)\'?"
		}
	}
	
	func message() -> String {
		switch type {
			case .none, .moveAllOffShoppingList: return ""
			case .deleteItem(let item):
				return "Are you sure you want to delete \'\(item.name)\'? This action cannot be undone"
		}
	}
	
	func cancelAction() {
		// nothing
	}
	
	func executeAction() {
		switch type {
			case .none:
				break
			case .moveAllOffShoppingList:
				Item.moveAllItemsOffShoppingList()
			case .deleteItem(let item):
				Item.delete(item)
		}
	}
}

struct ShoppingListTabView: View {
	
	// this is the @FetchRequest that ties this view to CoreData Items
	@FetchRequest(fetchRequest: Item.fetchAllItems(onList: true))
	private var itemsToBePurchased: FetchedResults<Item>

	// local state to trigger showing a sheet to add a new item
	@State private var isAddNewItemSheetShowing = false
	
	// parameters to control triggering an Alert
	@State private var confirmationTrigger = ConfirmationTrigger(type: .none)
	
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
or multi-section shopping list view.  the list display has some complexity to it because
of the sectioning, so we push it off to a specialized View.
---------- */

				if itemsToBePurchased.count == 0 {
					EmptyListView(listName: "Shopping")
				} else {
					ShoppingListView(multiSectionDisplay: $multiSectionDisplay,
//													 isConfirmationAlertShowing: $isConfirmationAlertShowing,
//													 itemToDelete: $itemToDelete,
													 confirmationTrigger: $confirmationTrigger)
				}
				
/* ---------
3. for non-empty lists, we have a few buttons at the end for bulk operations
---------- */

				if itemsToBePurchased.count > 0 {
					Rectangle()
						.frame(minWidth: 0, maxWidth: .infinity, minHeight: 1, idealHeight: 1, maxHeight: 1)
					
					SLCenteredButton(title: "Move All Items Off-list", action: {
						confirmationTrigger.trigger(type: .moveAllOffShoppingList)
						// setting these allow the Alert to come up with the right messages and actions
//						operationIsMoveToOtherList = true
//						isConfirmationAlertShowing = true
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
			.toolbar {
				ToolbarItem(placement: .navigationBarLeading, content: sectionDisplayButton)
				ToolbarItem(placement: .navigationBarTrailing, content: addNewButton)
			}
			.alert(isPresented: $confirmationTrigger.isConfirmationAlertShowing) {
				Alert(title: Text(confirmationTrigger.title()),
							message: Text(confirmationTrigger.message()),
							primaryButton: .cancel(Text("No")),
							secondaryButton: .destructive(Text("Yes"), action: confirmationTrigger.executeAction)
				)
			}

		} // end of NavigationView
		.navigationViewStyle(StackNavigationViewStyle())
		.onAppear() { print("ShoppingListTabView appear") }
		.onDisappear() { print("ShoppingListTabView disappear") }
		
	} // end of body: some View
	
	// MARK: - ToolbarItems
	
	// a "+" symbol to support adding a new item
	func addNewButton() -> some View {
		Button(action: { isAddNewItemSheetShowing = true })
			{ Image(systemName: "plus") }
	}
	
	// a toggle button to change section display mechanisms
	func sectionDisplayButton() -> some View {
		Button(action: {
			multiSectionDisplay.toggle()
		}) {
			Image(systemName: multiSectionDisplay ? "tray.2" : "tray")
				.font(.title2)
		}
	}
	
} // end of ShoppingListTabView


