//
//  ModifyLocationView.swift
//  ShoppingList
//
//  Created by Jerry on 5/7/20.
//  Copyright © 2020 Jerry. All rights reserved.
//

import SwiftUI
import CoreData

// MARK: - View Definition

struct AddorModifyLocationView: View {
	@Environment(\.presentationMode) var presentationMode
	
	// editableLocation is either a Location to edit, or nil to signify
	// that we're creating a new Location in for the viewModel.
	var editableLocation: Location? = nil
	
	// we use a specialized form of a ShoppingListViewModel in this View to
	// drive the list of items at this location.  it must be an observed object
	// so that if move over to the AddorModifyShoppingItemView, we can track
	// edits back here, especially if we either change the object's location
	// or delete the object.
	//@ObservedObject var shoppingItemsViewModel: ShoppingListViewModel //(type: .locationSpecificShoppingList)
	
	// testing possible replacement of view model by simple list
	//@State private var itemsAtThisLocation = [ShoppingItem]()
	
	// all editableData is packaged here.  its initial values are set to be
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
	
	// showDeleteConfirmation controls whether an Alert will appear
	// to confirm deletion of a Location
	@State private var showDeleteConfirmation: Bool = false
	
	var body: some View {
		Form {
			// 1: Name, Visitation Order, Colors
			Section(header: Text("Basic Information").textCase(.none)) {
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
				Section(header: Text("Location Management").textCase(.none)) {
					SLCenteredButton(title: "Delete This Location", action: { showDeleteConfirmation = true })
						.foregroundColor(Color.red)
				}
			}  // end of Section 2
			
			// Section 3: Items assigned to this Location, if we are editing a Location
			if editableLocation != nil {
				SimpleItemsList(location: editableLocation!)
			}
			
		} // end of Form
			.onAppear(perform: loadData)
			.navigationBarTitle(barTitle(), displayMode: .inline)
			.navigationBarBackButtonHidden(true)
			.navigationBarItems(
				leading: Button(action: { presentationMode.wrappedValue.dismiss() }){
					Text("Cancel")
				},
				trailing: Button(action: { commitData() }){
					Text("Save")
			})
			.alert(isPresented: $showDeleteConfirmation) {
				Alert(title: Text("Delete \'\(editableLocation!.name!)\'?"),
							message: Text("Are you sure you want to delete this location?"),
							primaryButton: .cancel(Text("No")),
							secondaryButton: .destructive(Text("Yes"), action: deleteLocation)
				)}
	}
	
	func barTitle() -> Text {
		return editableLocation == nil ? Text("Add New Location") : Text("Modify Location")
	}
	
	func deleteLocation() {
		if let location = editableLocation {
			Location.delete(location)
			presentationMode.wrappedValue.dismiss()
//			DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) { // seems to want more time in simulator
//				Location.delete(location)
//			}
		}
	}

	func commitData() {
		presentationMode.wrappedValue.dismiss()
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
			editableData.updateColor(from: editableColor)
			Location.updateData(for: editableLocation, using: editableData)
		}
	}

	func loadData() {
		// called on every .onAppear().  if dataHasBeenLoaded is true, then we have
		// already taken care of setting up the local state variables.
		if !dataHasBeenLoaded {
			if let location = editableLocation {
				editableData = EditableLocationData(location: location)
				editableColor = Color(.sRGB, red: location.red, green: location.green, blue: location.blue, opacity: location.opacity)
			} // else we already have default, editable data set up right
			dataHasBeenLoaded = true
		}
	}
	
}


struct SimpleItemsList: View {
	
	// the location we're associated with
	var location: Location
	@FetchRequest	private var items: FetchedResults<ShoppingItem>
	
	init(location: Location) {
		self.location = location
		let request = ShoppingItem.allShoppingItems(at: location)
		_items = FetchRequest(fetchRequest: request)
	}
	
	var body: some View {
		Section(header: Text("At this Location: \(items.count) items").textCase(.none)) {
			ForEach(items) { item in
				NavigationLink(destination: AddorModifyShoppingItemView(editableItem: item)) {
					Text(item.name)
				}
			}
		}
	}
}
