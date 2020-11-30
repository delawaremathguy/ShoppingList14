//
//  Location+Extensions.swift
//  ShoppingList
//
//  Created by Jerry on 5/6/20.
//  Copyright © 2020 Jerry. All rights reserved.
//

import UIKit
import CoreData

// constants
let kUnknownLocationName = "Unknown Location"
let kUnknownLocationVisitationOrder: Int32 = INT32_MAX

extension Location: Comparable {
	
	// add Comparable conformance: sort by visitation order
	public static func < (lhs: Location, rhs: Location) -> Bool {
		lhs.visitationOrder_ < rhs.visitationOrder_
	}
	
	// MARK: - Computed properties
	
	// name: fronts Core Data attribute name_ that is optional
	var name: String {
		get { name_ ?? "Unknown Name" }
		set { name_ = newValue }
	}
	
	// visitationOrder: fronts Core Data attribute visitationOrder_ that is Int32
	var visitationOrder: Int {
		get { Int(visitationOrder_) }
		set { visitationOrder_ = Int32(newValue) }
	}
	
	// items: fronts Core Data attribute items_ that is an NSSet
	var items: [Item] {
		if let items = items_ as? Set<Item> {
			return items.sorted(by: { $0.name < $1.name })
		}
		return []
	}
	
	// simplified test of "is the unknown location"
	var isUnknownLocation: Bool { visitationOrder_ == kUnknownLocationVisitationOrder }
	
	// this coalesces the four uiColor components into a single uiColor
	var uiColor: UIColor {
		UIColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(opacity))
	}

	
	// MARK: - Useful Fetch Request
	
	class func fetchAllLocations() -> NSFetchRequest<Location> {
		let request: NSFetchRequest<Location> = Location.fetchRequest()
		request.sortDescriptors = [NSSortDescriptor(key: "visitationOrder_", ascending: true)]
		return request
	}

	// MARK: - Class Functions
	
	static func count() -> Int {
		let fetchRequest: NSFetchRequest<Location> = Location.fetchRequest()
		do {
			let itemCount = try PersistentStore.shared.context.count(for: fetchRequest)
			return itemCount
		}
		catch let error as NSError {
			print("Error counting User Locations: \(error.localizedDescription), \(error.userInfo)")
		}
		return 0
	}

	// return a list of all locations, optionally returning only user-defined location
	// (i.e., excluding the unknown location)
	static func allLocations(userLocationsOnly: Bool) -> [Location] {
		let fetchRequest: NSFetchRequest<Location> = Location.fetchRequest()
		if userLocationsOnly {
			fetchRequest.predicate = NSPredicate(format: "visitationOrder_ != %d", kUnknownLocationVisitationOrder)
		}
		do {
			let items = try PersistentStore.shared.context.fetch(fetchRequest)
			return items
		}
		catch let error as NSError {
			print("Error getting User Locations: \(error.localizedDescription), \(error.userInfo)")
		}
		return [Location]()
	}

	// creates a new Location having an id, but then it's the user's responsibility
	// to fill in the field values (and eventually save)
	static func addNewLocation() -> Location {
		let newLocation = Location(context: PersistentStore.shared.context)
		newLocation.id = UUID()
		return newLocation
	}
	
	// parameters for the Unknown Location.  call this only upon startup if
	// the Core Data database has not yet been initialized
	static func createUnknownLocation() {
		let unknownLocation = Location(context: PersistentStore.shared.context)
		unknownLocation.id = UUID()
		unknownLocation.name_ = kUnknownLocationName
		unknownLocation.red = 0.5
		unknownLocation.green = 0.5
		unknownLocation.blue = 0.5
		unknownLocation.opacity = 0.5
		unknownLocation.visitationOrder_ = kUnknownLocationVisitationOrder
	}

	static func unknownLocation() -> Location? {
		// we only keep one "UnknownLocation" in the data store.  you can
		// find it because its visitationOrder is the largest 32-bit integer.
		// return nil if no such thing exists, which means that the data store
		// is empty (since all Items have an assigned Location).
		let fetchRequest: NSFetchRequest<Location> = Location.fetchRequest()
		fetchRequest.predicate = NSPredicate(format: "visitationOrder_ == %d", kUnknownLocationVisitationOrder)
		do {
			let locations = try PersistentStore.shared.context.fetch(fetchRequest)
			if locations.count == 1 {
				return locations[0]
			}
		} catch let error as NSError {
			print("Error fetching unknown location: \(error.localizedDescription), \(error.userInfo)")
		}
		return nil
	}
	
	// the default status on a delete is to always save changes out to disk
	// the only time not to do this (saveChanges = false) is if you delete a bunch
	// of locations all at the same time.
	//
	// one note here: we'll assume you want to save this change by default.
	static func delete(_ location: Location, saveChanges: Bool = true) {
		// you cannot delete the unknownLocation
		guard location.visitationOrder_ != kUnknownLocationVisitationOrder else { return }

		// retrieve the context of this Location and get a list of
		// all items for this location so we can work with them
		let context = location.managedObjectContext
		let itemsAtThisLocation = location.items
		
		// reset location associated with all of these to the unknownLocation
		// (which in turn, removes the current association with location)
		let theUnknownLocation = Location.unknownLocation()!
		for item in itemsAtThisLocation {
			item.location = theUnknownLocation
		}
		// and finish the deletion and make sure the context has gets cleaned up
		// right now in memory.  then save if requested
		context?.delete(location)
		context?.processPendingChanges()
		// save to disk if requested
		if saveChanges {
			PersistentStore.shared.saveContext()
		}
	}
	
	static func updateData(for location: Location?, using editableData: EditableLocationData) {
		// if the incoming item is not nil, then this is just a straight update.
		// otherwise, we must create the new Location here and add it to
		// our list of locations
		
		// if location is nil, it's a signal to add a new item with the packaged data
		if let location = location {
			location.updateValues(from: editableData)
		} else {
			let newLocation = Location.addNewLocation()
			newLocation.updateValues(from: editableData)
		}
		
		saveChanges()
	}
	
	// MARK: - Object Methods
	
	func updateValues(from editableData: EditableLocationData) {
		name_ = editableData.locationName
		visitationOrder_ = Int32(editableData.visitationOrder)
		red = editableData.red
		green = editableData.green
		blue = editableData.blue
		opacity = editableData.opacity
	}

	static func saveChanges() {
		PersistentStore.shared.saveContext()
	}
	
	
}

