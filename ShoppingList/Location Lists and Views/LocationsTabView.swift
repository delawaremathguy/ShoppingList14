//
//  LocationsView.swift
//  ShoppingList
//
//  Created by Jerry on 5/6/20.
//  Copyright © 2020 Jerry. All rights reserved.
//

import SwiftUI

struct LocationsTabView: View {
	
	// this is the @FetchRequest that ties this view to CoreData Locatiopns
	@FetchRequest(fetchRequest: Location.fetchAllLocations())
	private var locations: FetchedResults<Location>
		
	// local state to trigger showing a sheet to add a new location
	@State private var isAddNewLocationSheetShowing = false
	
	// support for context menu deletion: a boolean to control showing an
	// alert, and the location to delete after confirmation
	@State private var locationToDelete: Location?
	@State private var showDeleteConfirmation = false
	
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
					Section(header: Text("Locations Listed: \(locations.count)").textCase(.none)) {
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
			.toolbar { toolbarButton() }
			.alert(isPresented: $showDeleteConfirmation) {
				Alert(title: Text("Delete \'\(locationToDelete!.name)\'?"),
							message: Text("Are you sure you want to delete this location?"),
							primaryButton: .cancel(Text("No")),
							secondaryButton: .destructive(Text("Yes"), action: { Location.delete(locationToDelete!) })
				)}
			.onAppear { print("LocationsTabView appear") }
			.onDisappear { print("LocationsTabView disappear") }

		} // end of NavigationView
		.navigationViewStyle(StackNavigationViewStyle())
	} // end of var body: some View
	
	func toolbarButton() -> some View {
		Button(action: { isAddNewLocationSheetShowing = true }) {
			Image(systemName: "plus")
				.resizable()
				.frame(width: 20, height: 20)
		}
	}
	
	// a convenient way to build this context menu without having it in-line
	// in the view code above
	@ViewBuilder
	func contextMenuButton(for location: Location) -> some View {
		Button(action: {
			if !location.isUnknownLocation {
				locationToDelete = location
				showDeleteConfirmation = true
			}
		}) {
			Text(location.isUnknownLocation ? "(Cannot be deleted)" : "Delete This Location")
			Image(systemName: location.isUnknownLocation ? "trash.slash" : "trash")
		}
	}
		
}
