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
	// you might want the new item to go to the Puchased item list
	var addItemToShoppingList: Bool = true
	
	// this editableData stuct contains all of the fields of an Item that
	// can be edited here, so that we're not doing a "live edit" on the Item
	// it  this will be defaulted properly in .onAppear()
	@State var editableData = EditableItemData()

	// this indicates whether the editableData has been initialized from an incoming
	// editableItem and it will be flipped to true once .onAppear() has been called
	// and the editableData is appropriately set
	@State private var editableDataInitialized = false
	
	// showDeleteConfirmation controls whether a Delete This Shopping Item button appear
	// to confirm deletion of an Item
	@State private var showDeleteConfirmation: Bool = false
	
	// we need all locations so we can populate the Picker
	let locations = Location.allLocations(userLocationsOnly: false).sorted(by: <)

	
	var body: some View {
		Form {
			// Section 1. Basic Information Fields
			Section(header: Text("Basic Information").textCase(.none)) {
				
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
							secondaryButton: .destructive(Text("Yes"), action: { deleteAndDismiss(editableItem!) })
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
				editableData = EditableItemData(item: item)
			} else {
				// just be sure the default data is tweaked to place a new item on
				// the right list by default, depending on how this view was created
				editableData = EditableItemData()
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
	
	func deleteAndDismiss(_ item: Item) {
		Item.delete(item)
		presentationMode.wrappedValue.dismiss()
	}
}

