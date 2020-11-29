//
//  ShoppingItem+Extensions.swift
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
	
	// whether the item is on the list.  this fronts a Core Data optional attribute
	var onList: Bool {
		get { onList_ }
		set { onList_ = newValue }
	}
	
	// whether the item is available.  this fronts a Core Data optional attribute
	var isAvailable: Bool {
		get { isAvailable_ }
		set { isAvailable_ = newValue }
	}
	
	// quantity of the item.   this fronts a Core Data optional attribute
	var quantity: Int {
		get { Int(quantity_) }
		set { quantity_ = Int32(newValue) }
	}
	
	// item's associated location.  this fronts a Core Data optional attribute
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
			print("Error counting ShoppingItems: \(error.localizedDescription), \(error.userInfo)")
		}
		return 0
	}

	static func allShoppingItems() -> [Item] {
		let context = PersistentStore.shared.context
		let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
		do {
			let items = try context.fetch(fetchRequest)
			return items
		}
		catch let error as NSError {
			print("Error getting ShoppingItems: \(error.localizedDescription), \(error.userInfo)")
		}
		return [Item]()
	}
	
//	static func purchasedItemsFetchRequest() -> [Item] {
//		let context = PersistentStore.shared.context
//		let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
//		fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name_", ascending: true)]
//		fetchRequest.predicate = NSPredicate(format: "onList_ == %d", false, Calendar.current.startOfDay(for: Date()) as CVarArg)
//		do {
//			let items = try context.fetch(fetchRequest)
//			return items
//		}
//		catch let error as NSError {
//			print("Error getting items purchased today : \(error.localizedDescription), \(error.userInfo)")
//		}
//		return [Item]()
//	}
	
//	static func currentShoppingList(onList: Bool) -> [Item] {
//		let context = PersistentStore.shared.context
//		let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
//		fetchRequest.predicate = NSPredicate(format: "onList == %d", onList)
//		do {
//			let items = try context.fetch(fetchRequest)
//			return items
//		}
//		catch let error as NSError {
//			print("Error getting ShoppingItems on the list: \(error.localizedDescription), \(error.userInfo)")
//		}
//		return [Item]()
//	}
	
	// addNewItem is the user-facing add of a new entity.  since these are
	// Identifiable objects, this makes sure we give the entity a unique id, then
	// hand it back so the user can fill in what's important to them.
	static func addNewItem() -> Item {
		let context = PersistentStore.shared.context
		let newItem = Item(context: context)
		newItem.id = UUID()
		return newItem
	}

	static func saveChanges() {
		PersistentStore.shared.saveContext()
	}

	
	// this is a little tricky to understand:
	// deleting an item in Core Data doesn't really delete it ... it sort of hangs around
	// a little bit, eventually getting removed (likely once the actual save goes out
	// to disk).  this confuses the hell out of a @FetchRequest, which doesn't seem to
	// get the message right away, and so handling an objectWillChange message can
	// make it try to use what is really a non-existent shopping item.
	//
	// so this new code, which seems to work (he says, confidently) is to call
	// processPendingChanges() which syncs up the object graph in memory right away and this,
	// apparently, is enough to to get the message out to everyone.
	
	static func delete(item: Item, saveChanges: Bool = false) {
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
	
	// changes availability flag for an item
	func toggleAvailableStatus() {
		isAvailable.toggle()
		Item.saveChanges()
	}

	// changes onList flag for an item
	func toggleOnListStatus() {
		onList.toggle()
		if !onList { // just moved off list, so record date
			dateLastPurchased = Date()
		}
		Item.saveChanges()
	}

	func markAvailable() {
		isAvailable = true
		Item.saveChanges()
	}

	
	func updateValues(from editableData: EditableShoppingItemData) {
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

	// updates data for a ShoppingItem that the user has directed from an Add or Modify View.
	// if the incoming data is not assoicated with an item, we need to create it first
	static func update(using editableData: EditableShoppingItemData) {
		
		// if we can find a ShoppingItem with the right id, use it, else create one
		if let item = allShoppingItems().first(where: { $0.id == editableData.id }) {
			item.updateValues(from: editableData)
		} else {
			let newItem = Item.addNewItem()
			newItem.updateValues(from: editableData)
		}
		
		Item.saveChanges()
	}

	
}

