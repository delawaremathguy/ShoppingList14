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
----------*/
				
				Button(action: { isAddNewItemSheetShowing = true }) {
					Text("Add New Item")
						.foregroundColor(Color.blue)
						.padding(10)
				}
				.sheet(isPresented: $isAddNewItemSheetShowing) {
					NavigationView { AddorModifyItemView(addItemToShoppingList: true) }
				}
				
/* ---------
2. we display either a "List is Empty" view, a single-section shopping list view
or multi-section shopping list view.
----------*/

				if itemsToBePurchased.count == 0 {
					EmptyListView(listName: "Shopping")
				} else {
					shoppingListView(itemsToBePurchased: itemsToBePurchased,
																	multiSectionDisplay: multiSectionDisplay,
																	isConfirmationAlertShowing: $isConfirmationAlertShowing,
																	itemToDelete: $itemToDelete)
				}
				
/* ---------
3. for non-empty lists, we have a few buttons at the end for bulk operations
----------*/

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

// MARK: - A Generic SectionData struct

// the notion of this struct is that we use it to tell us what to draw for a single
// section: its title and the items in the section
struct SectionData<T: Hashable>: Identifiable, Hashable {
	var id: Int { hashValue }
	let title: String
	let items: [T]
}

// MARK: - Shopping List Display

// this shows itemsToBePurchased as either a single section or as multiple
// sections, one section for each Location.  it uses a somewhat complicated
// Form/ForEach/Section/ForEach construct to draw out the list and requires
// some preliminary work to perform the sectioning.  each item that appears
// has a NavigationLink and a contextMenu on it.

struct shoppingListView: View {
	
	// all items on the shopping list
	var itemsToBePurchased: FetchedResults<Item>
	// display format: one big section, or sectioned by Location
	var multiSectionDisplay: Bool
	// hooks back to the ShoppingListTabView enclosing view to
	// support deletion from a context menu
	@Binding var isConfirmationAlertShowing: Bool
	@Binding var itemToDelete: Item?
	
	// this is a temporary holding array for items being moved to the other list
	// this is how we tell whether an item is currently in the process of being "checked"
	@State private var itemsChecked = [Item]()
	
	var body: some View {
		Form {
			ForEach(sectionData(multiSectionDisplay: multiSectionDisplay)) { section in
				Section(header: Text(section.title).textCase(.none)) {
					// display items in this location
					ForEach(section.items) { item in
						// display a single row here for 'item'
						NavigationLink(destination: AddorModifyItemView(editableItem: item)) {
							SelectableItemRowView(item: item, selected: itemsChecked.contains(item),
																		sfSymbolName: "purchased",
																		respondToTapOnSelector:  { handleItemTapped(item) })
								.contextMenu {
									itemContextMenu(item: item, deletionTrigger: {
										itemToDelete = item
										isConfirmationAlertShowing = true
									})
								} // end of contextMenu
						} // end of NavigationLink
					} // end of ForEach
				} // end of Section
			} // end of ForEach
		}  // end of Form
	} // end of body: some View
	
	// the idea of this function is to break out the itemsToBePurchased by section,
	// according to whether the list is displayed as a single section or in multiple
	// sections (one for each Location that contains shopping items on the list)
	func sectionData(multiSectionDisplay: Bool) -> [SectionData<Item>] {
		
		// the easy case first: one section with a title and all the items.
		if !multiSectionDisplay {
			return [SectionData(title: "Items Remaining: \(itemsToBePurchased.count)",
													items: itemsToBePurchased.sorted(by: { $0.visitationOrder < $1.visitationOrder }))
			]
		}
		
		// for a multi-section list, break out all the items into a dictionary
		// with Locations as the keys.
		let dict = Dictionary(grouping: itemsToBePurchased.compactMap({$0}), by: { $0.location })
		// now assemble the data by location visitationOrder
		var completedSectionData = [SectionData<Item>]()
		for key in dict.keys.sorted() {
			completedSectionData.append(SectionData(title: key.name, items: dict[key]!))
		}
		return completedSectionData
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
