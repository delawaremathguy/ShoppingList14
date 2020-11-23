//
//  ContentView.swift
//  ShoppingList
//
//  Created by Jerry on 4/22/20.
//  Copyright © 2020 Jerry. All rights reserved.
//

import SwiftUI

// this is a list display of items on the shopping list. we use a ShoppingListViewModel
// object to mediate for us between the data that's over in Core Data and the
// data we need to drive this View.  the view will display either as a single
// section list, or a multi-section list (initial display is single section), with
// these areas of the view handled by separate views, each of which has its own,
// specific List/ForEach constructs.

struct ShoppingListTabView: View {
	// our view model = a window into Core Data so we can use it and be
	// notified when changes are made via the ObservableObject protocol
	@StateObject var viewModel = ShoppingListViewModel(type: .shoppingList)

	// local state to trigger showing a sheet to add a new item
	@State private var isAddNewItemSheetShowing = false
	// local states to trigger a destructive Alert either to delete
	// an item, or to move all items off the list
	@State private var isDestructiveAlertShowing = false
	@State private var itemToDelete: ShoppingItem? // item to delete, if that's what we want to do
	@State private var destructiveMoveToOtherList = false  // set to true if moving to other list
	
	// local state for are we a multisection display or not.  this must remain in
	// sync with the global setting (in case this View is destroyed and later recreated)
	@State var multiSectionDisplay: Bool = gShowMultiSectionShoppingList
	
	
	var body: some View {
		NavigationView {
			VStack(spacing: 0) {
				
/* ---------
1. add new item "button" is at top.  note that this will put up the
AddorModifyShoppingItemView inside its own NavigationView (so the Picker will work!)
----------*/
				
				Button(action: { isAddNewItemSheetShowing = true }) {
					Text("Add New Item")
						.foregroundColor(Color.blue)
						.padding(10)
				}
				.sheet(isPresented: $isAddNewItemSheetShowing) {
					NavigationView {
						AddorModifyShoppingItemView(addItemToShoppingList: true)
					}
				}
				
/* ---------
2. we display either a "List is Empty" view, a single-section shopping list view
or multi-section shopping list view.  these call out to other views below, because
the looping construct is quite different, as is how the .onDelete() modifier is
invoked on an item in the list
----------*/

				if viewModel.itemCount == 0 {
					EmptyListView(listName: "Shopping")
				} else if multiSectionDisplay {
					SLSimpleHeaderView(label: "Items Remaining: \(viewModel.itemCount)")
					MultiSectionShoppingListView(viewModel: viewModel,
																			 isDeleteItemAlertShowing: $isDestructiveAlertShowing,
																			 itemToDelete: $itemToDelete)
				} else {
					//SLSimpleHeaderView(label: "Items Listed: \(viewModel.itemCount)")
					Rectangle()
						.frame(minWidth: 0, maxWidth: .infinity, minHeight: 1, idealHeight: 1, maxHeight: 1)
					SingleSectionShoppingListView(viewModel: viewModel,
																				isDeleteItemAlertShowing: $isDestructiveAlertShowing,
																				itemToDelete: $itemToDelete)
				}
				
/* ---------
3. for non-empty lists, we tack on a few buttons at the end.
----------*/

				// clear/ mark as unavailable shopping list buttons
				if viewModel.itemCount > 0 {
					Rectangle()
						.frame(minWidth: 0, maxWidth: .infinity, minHeight: 1, idealHeight: 1, maxHeight: 1)
					
					SLCenteredButton(title: "Move All Items Off-list", action: {
						// setting tese allow the Alert to come up with the right messages and actions
						destructiveMoveToOtherList = true
						isDestructiveAlertShowing = true
						})
						.padding([.bottom, .top], 6)
					
					if viewModel.hasUnavailableItems {
						SLCenteredButton(title: "Mark All Items Available",
														 action: { viewModel.items.forEach({ $0.markAvailable() }) })
							.padding([.bottom], 6)
						
					}
				} //end of if viewModel.itemCount > 0

			} // end of VStack
			.navigationBarTitle("Shopping List")
			.navigationBarItems(leading: leadingButton())
			.toolbar { toolBarButton() }
			.alert(isPresented: $isDestructiveAlertShowing) {
				Alert(title: Text(destructiveAlertTitle()),
							message: Text(destructiveAlertMessage()),
							primaryButton: .cancel(Text("No"), action: destructiveAlertCancel),
							secondaryButton: .destructive(Text("Yes"), action: destructiveAlertAction)
				)
			}

			
		} // end of NavigationView
		.navigationViewStyle(StackNavigationViewStyle())
			.onAppear {
				print("ShoppingListTabView appear")
				viewModel.loadItems()
			}
			.onDisappear { print("ShoppingListTabView disappear") }
		
	} // end of body: some View
	
	func toolBarButton() -> some View {
		Button(action: { isAddNewItemSheetShowing = true })
			{ Image(systemName: "plus") }
	}
	
	func leadingButton() -> some View {
		Button(action: {
			multiSectionDisplay.toggle()
			gShowMultiSectionShoppingList.toggle()
		}) {
			Image(systemName: multiSectionDisplay ? "tray.2" : "tray")
				.font(.title2)
		}
	}
	
	// data to pass along to the destructive alert that eithers deletes an item
	// or moves all items off the list.  which these do depend on the value of
	// the boolean destructiveMoveToOtherList
	func destructiveAlertTitle() -> String {
		if destructiveMoveToOtherList {
			return "Move All Items Off-List"
		} else {
			return "Delete \'\(itemToDelete!.name)\'?"
		}
	}
	
	func destructiveAlertMessage() -> String {
		if destructiveMoveToOtherList {
			return ""
		} else {
			return "Are you sure you want to delete this item?"
		}
	}
	
	func destructiveAlertCancel() {
		destructiveMoveToOtherList = false
	}
	
	func destructiveAlertAction() {
		if destructiveMoveToOtherList {
			viewModel.items.forEach({ $0.toggleOnListStatus() })
			destructiveMoveToOtherList = false
		} else if let item = itemToDelete {
			ShoppingItem.delete(item: item, saveChanges: true)
		}
	}

}


// this is the inner section of a single section list, which is just a List/ForEach
// construct with a NavigationLink and a contextMenu for each item
struct SingleSectionShoppingListView: View {
	
	@ObservedObject var viewModel: ShoppingListViewModel
	@Binding var isDeleteItemAlertShowing: Bool
	@Binding var itemToDelete: ShoppingItem?
	
	// this is a temporary holding array for items being moved to the other list
	// this is how we tell whether an item is currently in the process of being "checked"
	@State private var itemsChecked = [ShoppingItem]()
	
	var body: some View {
		
		Form {
			// one main section, showing all items
			Section(header: Text("Items Remaining: \(viewModel.itemCount)").textCase(.none)) {
				ForEach(viewModel.items) { item in
					// display a single row here for 'item'
					NavigationLink(destination: AddorModifyShoppingItemView(editableItem: item)) {
						SelectableShoppingItemRowView(item: item, viewModel: viewModel,
												selected: itemsChecked.contains(item),
												respondToTapOnSelector: handleItemTapped)
							.contextMenu {
								shoppingItemContextMenu(item: item, deletionTrigger: {
																					itemToDelete = item
																					isDeleteItemAlertShowing = true
																				})
							} // end of contextMenu
					} // end of NavigationLink
				} // end of ForEach
			} // end of Section
		}  // end of Form
		//.listStyle(PlainListStyle())
		
	}
	
	func handleItemTapped(_ item: ShoppingItem) {
		// add this item to the temporary holding array for items being
		// moved to the other list, and queue
		if !itemsChecked.contains(item) {
			itemsChecked.append(item)
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
				item.toggleOnListStatus()
				itemsChecked.removeAll(where: { $0 == item })
			}
		}
	}

}

// this is the inner section of a multi section list, which is a much more
// complicated List/ForEach/Section/ForEach construct to break the sections
// by the locations which have items on the shopping list.  as in the single section
// version, each item has a NavigationLink and a contextMenu on it

struct MultiSectionShoppingListView: View {
	
	@ObservedObject var viewModel: ShoppingListViewModel
	@Binding var isDeleteItemAlertShowing: Bool
	@Binding var itemToDelete: ShoppingItem?
	
	@State private var itemsChecked = [ShoppingItem]()

	var body: some View {
		Form {
			ForEach(viewModel.locationsForItems()) { location in
				Section(header: SLSectionHeaderView(title: location.name!)) {
					// display items in this location
					ForEach(viewModel.items(at: location)) { item in
						// display a single row here for 'item'
						NavigationLink(destination: AddorModifyShoppingItemView(editableItem: item)) {
							SelectableShoppingItemRowView(item: item, viewModel: viewModel,
													selected: itemsChecked.contains(item),
													respondToTapOnSelector: handleItemTapped)
									.contextMenu {
										shoppingItemContextMenu(item: item, deletionTrigger: {
																							itemToDelete = item
																							isDeleteItemAlertShowing = true
										})
								} // end of contextMenu
						} // end of NavigationLink
					} // end of ForEach
				} // end of Section
			} // end of ForEach
		}  // end of List
	}
	
	func handleItemTapped(_ item: ShoppingItem) {
		if !itemsChecked.contains(item) {
			itemsChecked.append(item)
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
				item.toggleOnListStatus()
				itemsChecked.removeAll(where: { $0 == item })
			}
		}
	}

}

