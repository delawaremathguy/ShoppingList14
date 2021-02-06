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
	
	// editableLocation is either a Location to edit, or nil to signify
	// that we're creating a new Location in for the viewModel.
	var editableLocation: Location? = nil
		
	// all editableData is packaged here. its initial values are set to be
	// the defaults for a new Location that is added (editableLocation == nil)
	// and this will be updated in .onAppear() in the case that we are
	// editing an existing, non-nil Location.
	@State private var editableData = EditableLocationData()
	// this state variable translates RGB-A values to a Color -- used by the ColorPicker
	@State private var editableColor: Color = .green

	// this indicates dataHasBeenLoaded from an incoming editableLocation
	// it will be flipped to true the first time .onAppear() is called so
	// we wont be reloading the editableData and the editableColor
	@State private var dataHasBeenLoaded = false
	
	// parameters to control triggering an Alert and definig what action
	// to take upon confirmation
	@State private var confirmationAlert = ConfirmationAlert(type: .none)

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
			if editableLocation != nil && editableData.visitationOrder != kUnknownLocationVisitationOrder  {
				Section(header: Text("Location Management").sectionHeader()) {
					SLCenteredButton(title: "Delete This Location",
													 action: { confirmationAlert.trigger(
														type: .deleteLocation(editableLocation!),
														completion: { presentationMode.wrappedValue.dismiss() })
													 }
					).foregroundColor(Color.red)
				}
			} // end of Section 2
			
			// Section 3: Items assigned to this Location, if we are editing a Location
			if editableLocation != nil {
				SimpleItemsList(location: editableLocation!)
			}
			
		} // end of Form
		.onAppear(perform: loadData)
		.onDisappear { PersistentStore.shared.saveContext() }
		.navigationBarTitle(barTitle(), displayMode: .inline)
		.navigationBarBackButtonHidden(true)
		.toolbar {
			ToolbarItem(placement: .cancellationAction, content: cancelButton)
			ToolbarItem(placement: .confirmationAction, content: saveButton)
		}
		.alert(isPresented: $confirmationAlert.isShowing) { confirmationAlert.alert() }
	}
	
	func barTitle() -> Text {
		return editableLocation == nil ? Text("Add New Location") : Text("Modify Location")
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
		Location.updateData(for: editableLocation, using: editableData)
	}

	func loadData() {
		// called on every .onAppear().  if dataHasBeenLoaded is true, then we have
		// already taken care of setting up the local state variables.
		if !dataHasBeenLoaded {
			if let location = editableLocation {
				editableData = EditableLocationData(location: location)
				editableColor = Color(location.uiColor)
			} // else we already have default values, editable data is set up right
			dataHasBeenLoaded = true
		}
		
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
