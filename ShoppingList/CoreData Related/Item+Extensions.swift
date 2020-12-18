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
	
	/* Discussion
	
	update 17 December: the misconception presented previously has been removed!
	
	Notice that all except one of the Core Data attributes on an Item in the
	CD model appear with an underscore (_) at the end of their name.
	(the only exception is "id" because tweaking that name is a problem due to
	conformance to Identifiable.)
	
	my general theory of the case is that no one outside of this class (and its Core
	Data based brethren, like Location+Extensions.swift and PersistentStore.swift) should really
	be touching these attributes directly -- and certainly no SwiftUI views should
	ever touch these attributes directly.
	
	therefore, i choose to "front" each of them in this file, as well as perhaps provide
	other computed properties of interest.
	
	doing do helps smooth out the awkwardness of nil-coalescing (we don't want SwiftUI views
	continually writing item.name ?? "Unknown" all over the place); and in the case of an
	item's quantity, "fronting" its quantity_ attribute smooths the transtion from
	Int32 to Int.
	
	we do allow SwiftUI views to write to these fronted properties; and because we front them,
	we can appropriately act on the Core Data side, sometimes performing only simple Int --> Int32
	conversion.  similarly, it we move an item off the shopping list, we can take the opportunity
	then to timestamp the item as purchased.
	
	but there are also more cases to consider.  if you change an item's location, that
	location will want to know about it, in case there are any SwiftUI views out there holding
	that location as an @ObservedObject and that depend on any of its computed properties based
	on its items.  indeed, without receiving an objectWillChange.send() message,
	such a view would not redraw on its own.
	
	the same is true for a Location.  changing an attribute of a Location may at times require
	triggering a SwiftUI reaction involving the items associated with the Location, should any
	views be holding those items as @ObservedObjects (because an Item has computed properties that
	depend on its associated Location).
	
	as a result, you may see some code below (and also in Location+Extensions.swift) where, when
	a SwiftUI view writes to one of the fronted properties of the Item, we also execute
	location_?.objectWillChange.send().
	
  now, i wish that were all that was going on in this app; but i have no views in this app
	having an @ObservedObject.  that might surprise you, and you'll see plenty of discussion
	scattered throughout the project on this, but the generic problem remains in mixing Core Data
	objects and @ObservedObject:
	
		if a SwiftUI view holds an item as an @ObservedObject and that object is deleted
		while the view is still alive, the view is holding on to a zombie object and, depending
		on how the view code accesses that object, your program may crash.

	at least when you front all your Core Data attributes as i do below, the problem above
	appears to not matter much (although it's still there, really).  that's something to think about.
	
	*/
	
	// MARK: - Computed Properties
	
	// the date last purchased.  this fronts a Core Data optional attribute
	// when no date is available, we'll set the date to ReferenceDate, for purposes of
	// always having one for comparisons ("today" versus "earlier")
	var dateLastPurchased: Date { dateLastPurchased_ ?? Date(timeIntervalSinceReferenceDate: 1) }
	var hasBeenPurchased: Bool { dateLastPurchased_ != nil }
	
	// the name.  this fronts a Core Data optional attribute
	var name: String {
		get { name_ ?? "Not Available" }
		set { name_ = newValue }
	}
	
	// whether the item is available.  this fronts a Core Data boolean
	var isAvailable: Bool { isAvailable_ }
	
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
	// if you change an item's location, the old and the new Location may want to
	// know that some of their computed properties could be invalidated
	var location: Location {
		get { location_! }
		set {
			location_?.objectWillChange.send()
			location_ = newValue
			location_?.objectWillChange.send()
		}
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
	// deleted CD object, and its body property is called by SwiftUI using that reference,
	// you have problems, so its particularly helpful if you always nil-coalesce CD optionals
	// (asking for item.name_! when item has been deleted will cause a force-unwrap, because
	// the item's in-memory representation has been zeroed out and name_ is nil).
	// ... see the Discussion above!
	//
	// the typical problem is this: View A is driven by a @FetchRequest for Items; it
	// draws a list of those items, with each item appearing in its own subview, View B, for which
	// the item is marked as an @ObservedObject.  an item is deleted here; View A detects the change,
	// but apparently doesn't yet know about the deletion until CD tidies itself up. View A redraws,
	// causing View B to be re-evaluated with a now, non-existent object.
	//
	// so i now make a call to processPendingChanges() to sync up the object graph in memory
	// right away.  this, apparently, is enough to avoid most problems, however, it
	// is not a magic bullet, so no SwiftUI view should make a reference to an @ObservedObject's
	// property directly unless it's been fronted by nil-coalescing code as you see above.
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
	
	static func moveAllItemsOffShoppingList() {
		for item in allItems() where item.onList {
			item.onList_ = false
		}
		Item.saveChanges()
	}
	
	// MARK: - Object Methods
	
	// toggles the availability flag for an item
	func toggleAvailableStatus() {
		isAvailable_ = !isAvailable_
		Item.saveChanges()
	}

	// changes onList flag for an item
	func toggleOnListStatus() {
		onList = !onList
		Item.saveChanges()
	}

	func markAvailable() {
		isAvailable_ = true
		Item.saveChanges()
	}
	
	private func updateValues(from editableData: EditableItemData) {
		name_ = editableData.name
		quantity_ = Int32(editableData.quantity)
		onList_ = editableData.onList
		isAvailable_ = editableData.isAvailable
		location = editableData.location
	}
	
}

