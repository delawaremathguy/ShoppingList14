//
//  AddorModifyItemView.swift
//  ShoppingList
//
//  Created by Jerry on 5/3/20.
//  Copyright © 2020 Jerry. All rights reserved.
//

import SwiftUI

struct AddorModifyItemView: View {
	// we use this so we can dismiss ourself (sometimes we're in a Sheet, sometimes
	// in a NavigationLink)
	@Environment(\.presentationMode) var presentationMode

	// editableItem is either an Item to edit, or nil to signify
	// that we're creating a new Item in this View.
	var editableItem: Item? = nil
		
	// addItemToShoppingList just means that by default, a new item will be added to
	// the shopping list, and so this is true.
	// however, if inserting a new item from the Purchased item list,
	// you might want the new item to go to the Purchased item list (?)
	var addItemToShoppingList: Bool = true
	
	// this editableData struct contains all of the fields of an Item that
	// can be edited here, so that we're not doing a "live edit" on the Item
	// it is defaulted properly for a new Item
	@State var editableData = EditableItemData()

	// this indicates whether the editableData has been initialized from an incoming
	// editableItem and it will be flipped to true once .onAppear() has been called
	// and the editableData is appropriately set
	@State private var editableDataInitialized = false
	
	// parameters to control triggering an Alert and defining what action
	// to take upon confirmation
	@State private var confirmationAlert = ConfirmationAlert(type: .none)

	// we need all locations so we can populate the Picker
	let locations = Location.allLocations(userLocationsOnly: false).sorted(by: <)

	
	var body: some View {
		Form {
			// Section 1. Basic Information Fields
			Section(header: Text("Basic Information").sectionHeader()) {
				
				HStack(alignment: .firstTextBaseline) {
					SLFormLabelText(labelText: "Name: ")
					TextField("Item name", text: $editableData.name)
				}
				
				Stepper(value: $editableData.quantity, in: 1...10) {
					HStack {
						SLFormLabelText(labelText: "Quantity: ")
						Text("\(editableData.quantity)")
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
				
				if !editableData.dateText.isEmpty {
					HStack(alignment: .firstTextBaseline) {
						SLFormLabelText(labelText: "Last Purchased: ")
						Text("\(editableData.dateText)")
					}
				}

			} // end of Section 1
			
			// Section 2. Item Management (Delete), if present
			if editableItem != nil {
				Section(header: Text("Shopping Item Management").sectionHeader()) {
					SLCenteredButton(title: "Delete This Shopping Item",
													 action: { confirmationAlert.trigger(
														          type: .deleteItem(editableItem!),
																			completion: { presentationMode.wrappedValue.dismiss() })
													 }
					)
						.foregroundColor(Color.red)
				} // end of Section 2
			} // end of if ...
			
		} // end of Form
			
		.navigationBarTitle(barTitle(), displayMode: .inline)
		.navigationBarBackButtonHidden(true)
		.toolbar {
			ToolbarItem(placement: .cancellationAction, content: cancelButton)
			ToolbarItem(placement: .confirmationAction, content: saveButton)
		}
		.onAppear(perform: loadData)
		.alert(isPresented: $confirmationAlert.isShowing) { confirmationAlert.alert() }
	}
		
	func barTitle() -> Text {
		return editableItem == nil ? Text("Add New Item") : Text("Modify Item")
	}
	
	func loadData() {
		// called on every .onAppear().  if dataLoaded is true, then we have
		// already taken care of setting up the local state editable data.  otherwise,
		// we offload all the data from the editableItem (if there is one) to the
		// local state editable data that control this view
		print("AddOrModifyItemView appears")
		if !editableDataInitialized {
			if let item = editableItem {
				editableData = EditableItemData(item: item)
			} else {
				// by default, a new item will go to the shopping list
				editableData = EditableItemData()
			}
			// and be sure we don't do this again (!)
			editableDataInitialized = true
		}
		
		// and here is a kludge for a very special case:
		// -- we were in the ShoppingListTabView
		// -- we navigate to this Add/ModifyItem view for an Item X at Location Y
		// -- we use the tab bar to move to the Locations tab
		// -- we select Location Y and navigate to its Add/ModifyLocation view
		// -- we tap Item X listed for Location Y, and navigate to a second Add/ModifyItem view for Item X
		// -- we delete Item X in this second Add/ModifyItem view
		// -- we use the tab bar to come back to the shopping list tab, and this
		//    view is now what's on-screen, showing us an item that was deleted underneath us (!)
		//
		// the only thing that makes sense is to dismiss ourself in the case that we were created with
		// a real item (editableData.id != nil) but that item does not exist now
		
		if editableData.id != nil {
			if Item.object(withID: editableData.id!) == nil {
				presentationMode.wrappedValue.dismiss()
			}
		}
		
		// by the way, this applies symmetrically to opening an Add/ModifyItem view from the
		// Add/ModifyLocation view, then tabbing over to the shopping list, looking at a second
		// Add/ModifyItem view there and deleting.  the first Add/ModifyItem view will get the
		// same treatment in this code, effectively being closed.
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
	
}

