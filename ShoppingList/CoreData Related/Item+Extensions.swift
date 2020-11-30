//
//  Item+Extensions.swift
//  ShoppingList
//
//  Created by Jerry on 4/23/20.
//  Copyright © 2020 Jerry. All rights reserved.
//

import Foundation
import CoreData
import UIKit

extension Item {
	
	// MARK: - Computed Properties
	
	// the date last purchased.  this fronts a Core Data optional attribute
	var dateLastPurchased: Date {
		get { dateLastPurchased_ ?? Date() }
		set { dateLastPurchased_ = newValue }
	}
	
	// the name.  this fronts a Core Data optional attribute
	var name: String {
		get { name_ ?? "Not Available" }
		set { name_ = newValue }
	}
	
	// whether the item is on the list.  this fronts a Core Data boolean,
	// but when changed from true to false, it signals a purchase, so update
	// the lastDatePurchased
	var onList: Bool { 
		get { onList_ }
		set {
			onList_ = newValue
			if !onList_ { // just moved off list, so record date
				dateLastPurchased_ = Date()
			}
		}
	}
	
	// quantity of the item.   this fronts a Core Data optional attribute
	// but we need to do an Int <--> Int32 conversion
	var quantity: Int {
		get { Int(quantity_) }
		set { quantity_ = Int32(newValue) }
	}
	
	// an item's associated location.  this fronts a Core Data optional attribute
	var location: Location {
		get { location_! }
		set { location_ = newValue }
	}
	
	// the name of its associated location
	var locationName: String { location_?.name_ ?? "Not Available" }
	
	// the visitation order (of its associated location)
	var visitationOrder: Int { Int(location_?.visitationOrder_ ?? 0) }
	
	// the color = the color of its associated location
	var uiColor: UIColor {
		location_?.uiColor ?? UIColor(displayP3Red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
	}
	
	// MARK: - Useful Fetch Requests
	
	class func fetchAllItems(at location: Location) -> NSFetchRequest<Item> {
		let request: NSFetchRequest<Item> = Item.fetchRequest()
		request.sortDescriptors = [NSSortDescriptor(key: "name_", ascending: true)]
		request.predicate = NSPredicate(format: "location_ == %@", location)
		return request
	}
	
	class func fetchAllItems(onList: Bool) -> NSFetchRequest<Item> {
		let request: NSFetchRequest<Item> = Item.fetchRequest()
		request.predicate = NSPredicate(format: "onList_ == %d", onList)
		request.sortDescriptors = [NSSortDescriptor(key: "name_", ascending: true)]
		return request
	}

	// MARK: - Class functions for CRUD operations
	
	// this whole bunch of static functions lets me do a simple fetch and
	// CRUD operations through the AppDelegate, including one called saveChanges(),
	// so that i don't have to litter a whole bunch of try? moc.save() statements
	// out in the Views.
	
	static func count() -> Int {
		let context = PersistentStore.shared.context
		let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
		do {
			let itemCount = try context.count(for: fetchRequest)
			return itemCount
		}
		catch let error as NSError {
			print("Error counting items: \(error.localizedDescription), \(error.userInfo)")
		}
		return 0
	}

	static func allItems() -> [Item] {
		let context = PersistentStore.shared.context
		let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
		do {
			let items = try context.fetch(fetchRequest)
			return items
		}
		catch let error as NSError {
			print("Error getting items: \(error.localizedDescription), \(error.userInfo)")
		}
		return [Item]()
	}
	
	// addNewItem is the user-facing add of a new entity.  since these are
	// Identifiable objects, this makes sure we give the entity a unique id, then
	// hand it back so the user can fill in what's important to them.
	static func addNewItem() -> Item {
		let context = PersistentStore.shared.context
		let newItem = Item(context: context)
		newItem.id = UUID()
		return newItem
	}

	// saveChanges calls back through the PersistentStore
	static func saveChanges() {
		PersistentStore.shared.saveContext()
	}

	
	// this sequence of deletion is a little tricky to understand !
	// deleting an item in Core Data doesn't really delete it ... it sort of hangs around
	// a little bit, eventually getting removed (likely in the next available event loop, if
	// that's what they still call it).  what you can find, in some cases, is a zombine reference
	// to a deleted object for which .isDeleted is false and .isFault is true -- but it will
	// shortly go away from the CD memory graph when CD gets caught up with all changes.
	//
	// this is a real problem for SwiftUI.  if any view is holding a reference to a
	// deleted CD object, and its body property is called by SwiftUI, you have problems,
	// so its particularly helpful if you always nil-coalesce CD optionals in your view code
	// (asking for item.name_! when item has been deleted will cause a force-unwrap, because
	// the item's in-memory representation has been zeroed out and name_ is nil).
	//
	// the typical problem is this: View A is driven by a @FetchRequest for Items; it
	// draws a list of those items, with each item appearing in its own subview, View B, for which
	// the item is marked as an @ObservedObject.  an item is deleted here; View A detects the change,
	// but apparently doesn't yet know about the deletion until CD tidies itself up. View A redraws,
	// causing View B to be re-evaluated with a now, non-existent object.
	//
	// so i now make a call to processPendingChanges() to sync up the object graph in memory
	// right away.  this, apparently, is enough to avoid most problems.  unfortunately,
	// there may still be a little work to do in the future on this, so using nil-coalescing
	// code is highly recommended.
	//
	// one note here: we'll assume you want to save this change by default.
	static func delete(_ item: Item, saveChanges: Bool = true) {
		// remove the reference to this item from its associated location
		// by resetting its (real, Core Data) location to nil
		item.location_ = nil
		// now delete and save
		let context = item.managedObjectContext
		context?.delete(item)
		context?.processPendingChanges()
		if saveChanges {
			Self.saveChanges()
		}
	}
	
	// toggles the availability flag for an item
	func toggleAvailableStatus() {
		isAvailable = !isAvailable
		Item.saveChanges()
	}

	// changes onList flag for an item
	func toggleOnListStatus() {
		onList = !onList
		Item.saveChanges()
	}

	func markAvailable() {
		isAvailable = true
		Item.saveChanges()
	}

	
	func updateValues(from editableData: EditableItemData) {
		name = editableData.name
		quantity = editableData.quantity
		onList = editableData.onList
		isAvailable = editableData.isAvailable
		// if we are currently associated with a Location, then set new location
		// (which breaks the previous association with a location
		location = editableData.location
		// last thing: the associated Location may want to know about this
		//location?.objectWillChange.send()
	}

	// updates data for an Item that the user has directed from an Add or Modify View.
	// if the incoming data is not assoicated with an item, we need to create it first
	static func update(using editableData: EditableItemData) {
		
		// if we can find an Item with the right id, use it, else create one
		if let item = allItems().first(where: { $0.id == editableData.id }) {
			item.updateValues(from: editableData)
		} else {
			let newItem = Item.addNewItem()
			newItem.updateValues(from: editableData)
		}
		
		Item.saveChanges()
	}

	
}

