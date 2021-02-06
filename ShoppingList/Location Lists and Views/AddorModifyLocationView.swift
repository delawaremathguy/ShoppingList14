//
//  ModifyLocationView.swift
//  ShoppingList
//
//  Created by Jerry on 5/7/20.
//  Copyright © 2020 Jerry. All rights reserved.
//

import SwiftUI

// MARK: - View Definition

struct AddorModifyLocationView: View {
	@Environment(\.presentationMode) var presentationMode
	
	// all editableData is packaged here. its initial values are set using
	// a custom init.  there's also an associated editableColor used here
	// to mirror values in the editableData, because the ColorPicker wanta
	// to use a Color variable.
	@State private var editableData: EditableLocationData
	@State private var editableColor: Color
	
	// parameter to control triggering an Alert and defining what action
	// to take upon confirmation
	@State private var confirmationAlert = ConfirmationAlert(type: .none)
	
	// custom init to set up editable data
	init(editableLocation: Location? = nil) {
		// initialize the editableData struct for the incoming location, if any.
		if let location = editableLocation {
			_editableData = State(initialValue: EditableLocationData(location: location))
			_editableColor = State(initialValue: Color(location.uiColor))
		} else {
			_editableData = State(initialValue: EditableLocationData())
			_editableColor = State(initialValue: .green)
		}
	}

	var body: some View {
		Form {
			// 1: Name, Visitation Order, Colors
			Section(header: Text("Basic Information").sectionHeader()) {
				HStack {
					SLFormLabelText(labelText: "Name: ")
					TextField("Location name", text: $editableData.locationName)
				}
				
				if editableData.visitationOrder != kUnknownLocationVisitationOrder {
					Stepper(value: $editableData.visitationOrder, in: 1...100) {
						HStack {
							SLFormLabelText(labelText: "Visitation Order: ")
							Text("\(editableData.visitationOrder)")
						}
					}
				}
				
				ColorPicker("Location Color", selection: $editableColor)
			} // end of Section 1
			
			// Section 2: Delete button, if present (must be editing a user location)
			if editableData.representsExistingLocation && !editableData.associatedLocation.isUnknownLocation {
				Section(header: Text("Location Management").sectionHeader()) {
					SLCenteredButton(title: "Delete This Location",
													 action: { confirmationAlert.trigger(
														type: .deleteLocation(editableData.associatedLocation),
														completion: { presentationMode.wrappedValue.dismiss() })
													 }
					).foregroundColor(Color.red)
				}
			} // end of Section 2
			
			// Section 3: Items assigned to this Location, if we are editing a Location
			if editableData.representsExistingLocation {
				SimpleItemsList(location: editableData.associatedLocation)
			}
			
		} // end of Form
		.onDisappear { PersistentStore.shared.saveContext() }
		.navigationBarTitle(barTitle(), displayMode: .inline)
		.navigationBarBackButtonHidden(true)
		.toolbar {
			ToolbarItem(placement: .cancellationAction, content: cancelButton)
			ToolbarItem(placement: .confirmationAction) { saveButton().disabled(!editableData.canBeSaved) }
		}
		.alert(isPresented: $confirmationAlert.isShowing) { confirmationAlert.alert() }
	}
	
	func barTitle() -> Text {
		return editableData.representsExistingLocation ? Text("Modify Location") : Text("Add New Location")
	}
	
	func deleteAndDismiss(_ location: Location) {
		Location.delete(location)
		presentationMode.wrappedValue.dismiss()
	}

	// the cancel button
	func cancelButton() -> some View {
		Button(action: { presentationMode.wrappedValue.dismiss() }){
			Text("Cancel")
		}
	}
	
	// the save button
	func saveButton() -> some View {
		Button(action: commitData){
			Text("Save")
		}
	}

	func commitData() {
		// copies the SwiftUI Color to the editableData (which has RGB-A components)
		editableData.updateColor(from: editableColor)
		// and update Location (includes case of creating a new Location if necessary)
		presentationMode.wrappedValue.dismiss()
		Location.updateData(using: editableData)
	}
	
}


struct SimpleItemsList: View {
	
	@FetchRequest	private var items: FetchedResults<Item>
	
	init(location: Location) {
		//self.location = location
		let request = Item.fetchAllItems(at: location)
		_items = FetchRequest(fetchRequest: request)
	}
	
	var body: some View {
		Section(header: Text("At this Location: \(items.count) items").sectionHeader()) {
			ForEach(items) { item in
				NavigationLink(destination: AddorModifyItemView(editableItem: item)) {
					Text(item.name)
				}
			}
		}
	}
}
