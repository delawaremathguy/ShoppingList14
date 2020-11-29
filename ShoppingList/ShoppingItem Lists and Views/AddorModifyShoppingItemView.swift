//
//  ModifyShoppingItemView.swift
//  ShoppingList
//
//  Created by Jerry on 5/3/20.
//  Copyright © 2020 Jerry. All rights reserved.
//

import SwiftUI

struct AddorModifyShoppingItemView: View {
	// we use this so we can dismiss ourself (sometimes we're in a Sheet, sometimes
	// in a NavigationLink)
	@Environment(\.presentationMode) var presentationMode

	// editableItem is either a ShoppingItem to edit, or nil to signify
	// that we're creating a new ShoppingItem in this View.
	var editableItem: Item? = nil
		
	// addItemToShoppingList just means that by default, a new item will be added to
	// the shopping list, and so this is true.
	// however, if inserting a new item from the Purchased item list,
	// this will be set to false. the user can override here if they wish.
	var addItemToShoppingList: Bool = true
	
	// this editableData stuct contains all of the fields of a ShoppingItem that
	// can be edited here, so that we're not doing a "live edit" on the ShoppingItem
	// it  this will be defaulted properly in .onAppear()
	@State var editableData = EditableShoppingItemData()

	// this indicates whether the editableData has been initialized from an incoming
	// editableItem and it will be flipped to true once .onAppear() has been called
	// and the editableData is appropriately set
	@State private var editableDataInitialized = false
	
	// showDeleteConfirmation controls whether a Delete This Shopping Item button appear
	// to confirm deletion of a ShoppingItem
	@State private var showDeleteConfirmation: Bool = false
	
	// we need all locations so we can populate the Picker
	let locations = Location.allLocations(userLocationsOnly: false).sorted(by: <)

	
	var body: some View {
		Form {
			// Section 1. Basic Information Fields
			Section(header: Text("Basic Information").textCase(.none)) {
				
				HStack(alignment: .firstTextBaseline) {
					SLFormLabelText(labelText: "Name: ")
					TextField("Item name", text: $editableData.itemName)
				}
				
				Stepper(value: $editableData.itemQuantity, in: 1...10) {
					HStack {
						SLFormLabelText(labelText: "Quantity: ")
						Text("\(editableData.itemQuantity)")
					}
				}
				
				Picker(selection: $editableData.location, label: SLFormLabelText(labelText: "Location: ")) {
					ForEach(locations) { location in
						Text(location.name).tag(location)
					}
				}
				
				HStack(alignment: .firstTextBaseline) {
					Toggle(isOn: $editableData.onList) {
						SLFormLabelText(labelText: "On Shopping List: ")
					}
				}
				
				HStack(alignment: .firstTextBaseline) {
					Toggle(isOn: $editableData.isAvailable) {
						SLFormLabelText(labelText: "Is Available: ")
					}
				}
				
			} // end of Section
			
			// Section 2. Item Management (Delete), if present
			if editableItem != nil {
				Section(header: Text("Shopping Item Management").textCase(.none)) {
					SLCenteredButton(title: "Delete This Shopping Item",
													 action: { showDeleteConfirmation = true })
						.foregroundColor(Color.red)
				}
			} // end of Section
			
		} // end of Form
			
			.navigationBarTitle(barTitle(), displayMode: .inline)
			.navigationBarBackButtonHidden(true)
			.navigationBarItems(leading: cancelButton(), trailing: saveButton())
			.onAppear(perform: loadData)
			.alert(isPresented: $showDeleteConfirmation) {
				Alert(title: Text("Delete \'\(editableItem!.name)\'?"),
							message: Text("Are you sure you want to delete this item?"),
							primaryButton: .cancel(Text("No")),
							secondaryButton: .destructive(Text("Yes"), action: deleteItem)
				)}
	}
		
	func barTitle() -> Text {
		return editableItem == nil ? Text("Add New Item") : Text("Modify Item")
	}
	
	func loadData() {
		// called on every .onAppear().  if dataLoaded is true, then we have
		// already taken care of setting up the local state editable data.  otherwise,
		// we offload all the data from the editableItem (if there is one) to the
		// local state editable data that control this view
		if !editableDataInitialized {
			if let item = editableItem {
				editableData = EditableShoppingItemData(shoppingItem: item)
			} else {
				// just be sure the default data is tweaked to place a new item on
				// the right list by default, depending on how this view was created
				editableData = EditableShoppingItemData(onList: addItemToShoppingList)
			}
			// and be sure we don't do this again (!)
			editableDataInitialized = true
		}
	}
	
	// the cancel button
	func cancelButton() -> some View {
		Button(action : { presentationMode.wrappedValue.dismiss() }){
			Text("Cancel")
		}
	}
	
	// the save button
	func saveButton() -> some View {
		Button(action : { commitDataEntry() }){
			Text("Save")
				.disabled(!editableData.canBeSaved)
		}
	}
	
	// called when you tap the Save button.
	func commitDataEntry() {
		guard editableData.canBeSaved else { return }
		presentationMode.wrappedValue.dismiss()
		Item.update(using: editableData)
	}
	
	// called after confirmation to delete an item.
	
	func deleteItem() {
		if let item = editableItem {
			Item.delete(item: item, saveChanges: true)
			presentationMode.wrappedValue.dismiss()
		}
	}
}

