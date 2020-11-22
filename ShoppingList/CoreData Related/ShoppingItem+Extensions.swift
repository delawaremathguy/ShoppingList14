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
	
	// MARK: - Convenience Properties
	
	// the color associated with a ShoppingItem is the same as that of its location's color
	var backgroundColor: UIColor {
		return location?.uiColor() ?? UIColor(displayP3Red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
	}
	
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

	static func delete(item: ShoppingItem, saveChanges: Bool = false) {
		// let anyone who is interested we're about to kill this ShoppingItem
		NotificationCenter.default.post(name: .shoppingItemWillBeDeleted, object: item, userInfo: nil)
		// remove reference to this item from its associated location first
		let location = item.location
		location?.removeFromItems(item)
		// now delete and save (default)
		item.managedObjectContext?.delete(item)
		if saveChanges {
			Self.saveChanges()
		}
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

	
}

