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

extension ShoppingItem {
	
	// MARK: - Computed Properties

	
	// the date last purchased.  this fronts a Core Data optional attribute
	var dateLastPurchased: Date {
		get { dateLastPurchasedOpt ?? Date() }
		set { dateLastPurchasedOpt = newValue }
	}
	
	// the name.  this fronts a Core Data optional attribute
	var name: String {
		get { nameOpt ?? "Not Available" }
		set { nameOpt = newValue }
	}
	
	// the visitation order (of its associated location)
	var visitationOrder: Int { Int(location?.visitationOrder ?? 0) }
	
	// the name of its associated location
	var locationName: String { location?.name ?? "Not Available" }
	
	// the color = the color of its associated location
	var backgroundColor: UIColor {
		location?.uiColor() ?? UIColor(displayP3Red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
	}
	
	// MARK: - Useful Fetch Requests
	
	class func fetchAllItems(at location: Location) -> NSFetchRequest<ShoppingItem> {
		let request: NSFetchRequest<ShoppingItem> = ShoppingItem.fetchRequest()
		request.sortDescriptors = [NSSortDescriptor(key: "nameOpt", ascending: true)]
		request.predicate = NSPredicate(format: "location == %@", location)
		return request
	}
	
	class func fetchAllItems(onList: Bool) -> NSFetchRequest<ShoppingItem> {
		let request: NSFetchRequest<ShoppingItem> = ShoppingItem.fetchRequest()
		request.predicate = NSPredicate(format: "onList == %d", onList)
		request.sortDescriptors = [NSSortDescriptor(key: "nameOpt", ascending: true)]
		return request
	}

	// MARK: - Class functions for CRUD operations
	
	// this whole bunch of static functions lets me do a simple fetch and
	// CRUD operations through the AppDelegate, including one called saveChanges(),
	// so that i don't have to litter a whole bunch of try? moc.save() statements
	// out in the Views.
	
	static func count() -> Int {
		let context = PersistentStore.shared.context
		let fetchRequest: NSFetchRequest<ShoppingItem> = ShoppingItem.fetchRequest()
		do {
			let itemCount = try context.count(for: fetchRequest)
			return itemCount
		}
		catch let error as NSError {
			print("Error counting ShoppingItems: \(error.localizedDescription), \(error.userInfo)")
		}
		return 0
	}

	static func allShoppingItems() -> [ShoppingItem] {
		let context = PersistentStore.shared.context
		let fetchRequest: NSFetchRequest<ShoppingItem> = ShoppingItem.fetchRequest()
		do {
			let items = try context.fetch(fetchRequest)
			return items
		}
		catch let error as NSError {
			print("Error getting ShoppingItems: \(error.localizedDescription), \(error.userInfo)")
		}
		return [ShoppingItem]()
	}
	
	static func purchasedItemsFetchRequest() -> [ShoppingItem] {
		let context = PersistentStore.shared.context
		let fetchRequest: NSFetchRequest<ShoppingItem> = ShoppingItem.fetchRequest()
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: "nameOpt", ascending: true)]
		fetchRequest.predicate = NSPredicate(format: "onList == %d", false, Calendar.current.startOfDay(for: Date()) as CVarArg)
		do {
			let items = try context.fetch(fetchRequest)
			return items
		}
		catch let error as NSError {
			print("Error getting items purchased today : \(error.localizedDescription), \(error.userInfo)")
		}
		return [ShoppingItem]()
	}
	
	static func currentShoppingList(onList: Bool) -> [ShoppingItem] {
		let context = PersistentStore.shared.context
		let fetchRequest: NSFetchRequest<ShoppingItem> = ShoppingItem.fetchRequest()
		fetchRequest.predicate = NSPredicate(format: "onList == %d", onList)
		do {
			let items = try context.fetch(fetchRequest)
			return items
		}
		catch let error as NSError {
			print("Error getting ShoppingItems on the list: \(error.localizedDescription), \(error.userInfo)")
		}
		return [ShoppingItem]()
	}
	
	// addNewItem is the user-facing add of a new entity.  since these are
	// Identifiable objects, this makes sure we give the entity a unique id, then
	// hand it back so the user can fill in what's important to them.
	static func addNewItem() -> ShoppingItem {
		let context = PersistentStore.shared.context
		let newItem = ShoppingItem(context: context)
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
	
	static func delete(item: ShoppingItem, saveChanges: Bool = false) {
		// remove reference to this item from its associated location first
		let location = item.location
		location?.removeFromItems(item)
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
		ShoppingItem.saveChanges()
	}

	// changes onList flag for an item
	func toggleOnListStatus() {
		onList.toggle()
		if !onList { // just moved off list, so record date
			dateLastPurchased = Date()
		}
		ShoppingItem.saveChanges()
	}

	func markAvailable() {
		isAvailable = true
		ShoppingItem.saveChanges()
	}

	
	func updateValues(from editableData: EditableShoppingItemData) {
		name = editableData.itemName
		quantity = Int32(editableData.itemQuantity)
		onList = editableData.onList
		isAvailable = editableData.isAvailable
		// if we are currently associated with a Location, break that association
		// and then set new location
		location?.removeFromItems(self)
		location = editableData.location
		// last thing: the associated Location may want to know about this
		//location?.objectWillChange.send()
	}

	// updates data for a ShoppingItem that the user has directed from an Add or Modify View.
	// if the incoming data is not assoicated with an item, we need to create it first
	static func update(using editableData: EditableShoppingItemData) {
		
		// if we can find a ShoppingItem with the right id, use it, else create one
		if let item = allShoppingItems().first(where: { $0.id == editableData.shoppingItemID }) {
			item.updateValues(from: editableData)
		} else {
			let newItem = ShoppingItem.addNewItem()
			newItem.updateValues(from: editableData)
		}
		
		ShoppingItem.saveChanges()
	}

	
}

