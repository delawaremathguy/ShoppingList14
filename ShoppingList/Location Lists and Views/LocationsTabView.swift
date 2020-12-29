//
//  LocationsView.swift
//  ShoppingList
//
//  Created by Jerry on 5/6/20.
//  Copyright © 2020 Jerry. All rights reserved.
//

import SwiftUI

struct LocationsTabView: View {
	
	// this is the @FetchRequest that ties this view to CoreData Locations
	@FetchRequest(fetchRequest: Location.fetchAllLocations())
	private var locations: FetchedResults<Location>
		
	// local state to trigger a sheet to appear to add a new location
	@State private var isAddNewLocationSheetShowing = false
	
	// parameters to control triggering an Alert and defining what action
	// to take upon confirmation
	@State private var confirmationAlert = ConfirmationAlert(type: .none)
	
	var body: some View {
		NavigationView {
			VStack(spacing: 0) {
				
				// 1. add new location "button" is at top.  note that this will put up the
				// AddorModifyLocationView inside its own NaviagtionView (so the Picker will work!)
				Button(action: { isAddNewLocationSheetShowing = true }) {
					Text("Add New Location")
						.foregroundColor(Color.blue)
						.padding(10)
				}
				.sheet(isPresented: $isAddNewLocationSheetShowing) {
					NavigationView { AddorModifyLocationView() }
				}
				
				Rectangle()
					.frame(minWidth: 0, maxWidth: .infinity, minHeight: 1, idealHeight: 1, maxHeight: 1)

				
				// 2. then the list of locations
				Form {
					Section(header: Text("Locations Listed: \(locations.count)").sectionHeader()) {
						ForEach(locations) { location in
							NavigationLink(destination: AddorModifyLocationView(editableLocation: location)) {
								LocationRowView(rowData: LocationRowData(location: location))
									.contextMenu { contextMenuButton(for: location) }
							} // end of NavigationLink
						} // end of ForEach
					} // end of Section
				} // end of Form
				
			} // end of VStack
			.navigationBarTitle("Locations")
			.toolbar { ToolbarItem(placement: .navigationBarTrailing, content: addNewButton) }
			.alert(isPresented: $confirmationAlert.isShowing) { confirmationAlert.alert() }
			.onAppear() { print("LocationsTabView appear") }
			.onDisappear() { print("LocationsTabView disappear") }

		} // end of NavigationView
		.navigationViewStyle(StackNavigationViewStyle())
	} // end of var body: some View
	
	// defines the usual "+" button to add a Location
	func addNewButton() -> some View {
		Button(action: { isAddNewLocationSheetShowing = true }) {
			Image(systemName: "plus")
				.font(.title2)
		}
	}
	
	// a convenient way to build this context menu without having it in-line
	// in the view code above
	@ViewBuilder
	func contextMenuButton(for location: Location) -> some View {
		Button(action: {
			if !location.isUnknownLocation {
				confirmationAlert.trigger(type: .deleteLocation(location))
			}
		}) {
			Text(location.isUnknownLocation ? "(Cannot be deleted)" : "Delete This Location")
			Image(systemName: location.isUnknownLocation ? "trash.slash" : "trash")
		}
	}
		
}
