//
//  Development.swift
//  ShoppingList
//
//  Created by Jerry on 5/14/20.
//  Copyright © 2020 Jerry. All rights reserved.
//

import Foundation
import CoreData
import UIKit

// i added what i call a "Dev Tools" tab so that if you want to use this
// as a real app (device or simulator), access to all the debugging stuff that
// i have can be "controlled," so to speak, on a separate tabview; and that tab
// view can be displayed or not by setting this global variable:

let kShowDevToolsTab = true

// i used these constants and functions below during development to import and
// export Items and Locations via JSON.
// these are the filenames for JSON output when dumped from the simulator
// and also the filenames in the bundle used to load sample data.
let kJSONDumpDirectory = "/Users/USE_YOUR_OWN_MAC_USERNAME_HERE_HERE/Desktop/"	// dumps to the Desktop: Adjust for your Username!
let kItemsFilename = "items.json"
let kLocationsFilename = "locations.json"

// to write stuff out -- a list of Items and a list of Locations --
// the code is essentially the same except for the typing of the objects
// in the list.  so we use the power of generics:  we introduce
// (1) a protocol that demands that something be able to produce a simple
// Codable (struct) representation of itself -- a proxy as it were.
protocol CodableStructRepresentable {
	associatedtype DataType: Codable
	var codableProxy: DataType { get }
}

// and (2), knowing that Item and Location are NSManagedObjects, and we
// don't want to write our own custom encoder (eventually we will), we extend each to
// be able to produce a simple, Codable struct proxy holding only what we want to write out
// (ItemCodable and LocationCodable structs, respectively)
func writeAsJSON<T>(items: [T], to filename: String) where T: CodableStructRepresentable {
	let codableItems = items.map() { $0.codableProxy }
	let encoder = JSONEncoder()
	encoder.outputFormatting = .prettyPrinted
	var data = Data()
	do {
		data = try encoder.encode(codableItems)
	} catch let error as NSError {
		print("Error converting items to JSON: \(error.localizedDescription), \(error.userInfo)")
		return
	}
	
	// if in simulator, dump to files somewhere on your Mac (check definition above)
	// and otherwise if on device (or if file dump doesn't work) simply print to the console.
	#if targetEnvironment(simulator)
		let filepath = kJSONDumpDirectory + filename
		do {
			try data.write(to: URL(fileURLWithPath: filepath))
			print("List of items dumped as JSON to " + filename)
		} catch let error as NSError {
			print("Could not write to desktop file: \(error.localizedDescription), \(error.userInfo)")
			print(String(data: data, encoding: .utf8)!)
		}
	#else
		print(String(data: data, encoding: .utf8)!)
	#endif
	
}

func populateDatabaseFromJSON() {
	// it sure is easy to do with HWS's Bundle extension (!)
	let codableLocations: [LocationCodableProxy] = Bundle.main.decode(from: kLocationsFilename)
	insertNewLocations(from: codableLocations)
	let codableItems: [ItemCodableProxy] = Bundle.main.decode(from: kItemsFilename)
	insertNewItems(from: codableItems)
	Item.saveChanges()
}

func insertNewItems(from codableItems: [ItemCodableProxy]) {
	
	// get all Locations that are not the unknown location
	// group by name for lookup below when adding an item to a location
	let locations = Location.allLocations(userLocationsOnly: true)
	let name2Location = Dictionary(grouping: locations, by: { $0.name })
	
	for codableItem in codableItems {
		let newItem = Item.addNewItem() // new UUID is created here
		newItem.name = codableItem.name
		newItem.quantity = codableItem.quantity
		newItem.onList = codableItem.onList
		newItem.isAvailable = codableItem.isAvailable
		newItem.dateLastPurchased = Date().addingTimeInterval(-600_000) // pushes time stamp back about a week
		
		// look up matching location by name
		// anything that doesn't match goes to the unknown location.
		if let location = name2Location[codableItem.locationName]?.first {
			newItem.location = location
		} else {
			newItem.location = Location.unknownLocation()!
		}
		
	}
}

// used to insert data from JSON files in the app bundle
func insertNewLocations(from codableLocations: [LocationCodableProxy]) {
	for codableLocation in codableLocations {
		let newLocation = Location.addNewLocation() // new UUID created here
		newLocation.name = codableLocation.name
		newLocation.visitationOrder = codableLocation.visitationOrder
		newLocation.red = codableLocation.red
		newLocation.green = codableLocation.green
		newLocation.blue = codableLocation.blue
		newLocation.opacity = codableLocation.opacity
	}
}

// useful only as an introductory tool.  if you want to try out the app, you can
// insert a full, working database of Items and Locations; play with it;
// then delete everything and start over.
func deleteAllData() {
	var context: NSManagedObjectContext? = nil // i'll want the context of at least one Item or Location below
	let items = Item.allItems()
	for item in items {
		context = item.managedObjectContext
		Item.delete(item, saveChanges: false)
	}
	
	let locations = Location.allLocations(userLocationsOnly: true)
	for location in locations {
		context = location.managedObjectContext
		Location.delete(location, saveChanges: false)
	}
	
	context?.processPendingChanges()
	Location.saveChanges()
}


// this is a cute way to find out where the CoreData database lives,
// primarily for use in the simulator
//func printCoreDataDBPath() {
//	let path = FileManager
//		.default
//		.urls(for: .applicationSupportDirectory, in: .userDomainMask)
//		.last?
//		.absoluteString
//		.replacingOccurrences(of: "file://", with: "")
//		.removingPercentEncoding
//
//	print("Core Data DB Path :: \(path ?? "Not found")")
//}

// MARK: - USeful Extensions re: CodableStructRepresentable

extension Location: CodableStructRepresentable {
	var codableProxy: some Encodable & Decodable {
		return LocationCodableProxy(from: self)
	}
}

extension Item: CodableStructRepresentable {
	var codableProxy: some Encodable & Decodable {
		return ItemCodableProxy(from: self)
	}
}



