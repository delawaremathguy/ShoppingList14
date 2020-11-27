//
//  LocationsView.swift
//  ShoppingList
//
//  Created by Jerry on 5/6/20.
//  Copyright © 2020 Jerry. All rights reserved.
//

import SwiftUI

struct LocationsTabView: View {
	
	// this View is a simple list view, so we'll drive it with a simple
	// @FetchRequest rather than a view model to manage the list of Locations
	@FetchRequest(entity: Location.entity(),
								sortDescriptors: [NSSortDescriptor(keyPath: \Location.visitationOrder, ascending: true)])
	private var locations: FetchedResults<Location>
	
	// controls appearance of the Add/ModifyLocation view, presented as a sheet
	@State private var isAddNewLocationSheetShowing = false
	
	// support for context menu deletion
	@State private var locationToDelete: Location?
	@State private var showDeleteConfirmation = false
	
	var body: some View {
		NavigationView {
			VStack(spacing: 0) {
				
				// 1. add new location "button" is at top.  note that this will put up the AddorModifyLocationView
				// inside its own NaviagtionView (so the Picker will work!) and we must pass along the
				// viewModel to really accomplish any change
				Button(action: { isAddNewLocationSheetShowing = true }) {
					Text("Add New Location")
						.foregroundColor(Color.blue)
						.padding(10)
				}
					
				.sheet(isPresented: $isAddNewLocationSheetShowing) {
					NavigationView { AddorModifyLocationView() }
				}
				
				// 1a. Report location count, essentially as a section header for just the one section
				//SLSimpleHeaderView(label: "Locations Listed: \(viewModel.locationCount)")
				Rectangle()
					.frame(minWidth: 0, maxWidth: .infinity, minHeight: 1, idealHeight: 1, maxHeight: 1)

				
				// 2. then the list of locations
				Form {
					Section(header: Text("Locations Listed: \(Location.count())").textCase(.none)) {
						ForEach(locations) { location in
							NavigationLink(destination: AddorModifyLocationView(editableLocation: location)) {
								LocationRowView(rowData: LocationRowData(location: location))
									.contextMenu {
										Button(action: {
											if !location.isUnknownLocation() {
												locationToDelete = location
												showDeleteConfirmation = true
											}
										}) {
											Text(location.isUnknownLocation() ? "(Cannot be deleted)" : "Delete This Location")
											Image(systemName: location.isUnknownLocation() ? "trash.slash" : "trash")
										}
									}
							}
							//.listRowBackground(Color(location.uiColor()))
						} // end of ForEach
					} // end of Section
						.alert(isPresented: $showDeleteConfirmation) {
							Alert(title: Text("Delete \'\(locationToDelete!.name!)\'?"),
										message: Text("Are you sure you want to delete this location?"),
										primaryButton: .cancel(Text("No")),
										secondaryButton: .destructive(Text("Yes"), action: deleteSelectedLocation)
							)}
				} // end of List
				//.listStyle(PlainListStyle())

			} // end of VStack
			.navigationBarTitle("Locations")
			.toolbar { toolbarButton() }
				.onAppear {
					print("LocationsTabView appear")
					//viewModel.loadLocations()
				}
			
		} // end of NavigationView
		.navigationViewStyle(StackNavigationViewStyle())
			.onDisappear { print("LocationsTabView disappear") }
	} // end of var body: some View
	
	func toolbarButton() -> some View {
		Button(action: { isAddNewLocationSheetShowing = true }) {
			Image(systemName: "plus")
				.resizable()
				.frame(width: 20, height: 20)
		}
	}
	func deleteSelectedLocation() {
		if let location = locationToDelete {
			Location.delete(location)
		}
	}
		
}
