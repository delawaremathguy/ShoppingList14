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
	
	Notice that all except one of the Core Data attributes on an Item that
	appear in the CD model with an underscore (_) at the end of their name.
	(the only exception is "id" because tweaking that name is a problem because
	of conformance to Identifiable.)
	
	my general theory of the case is that no one outside of this class should really
	be touching these attributes directly, especially SwiftUI views.  apart from
	smoothing out the awkwardness of nil-coalescing in some cases, these are some
	attributes of an Item which, when changed, not only generate a reactive effect
	out there in SwiftUI views that watch for Item changes (e.g., via a @FetchRequest
	of as an @Observed object) -- but also should trigger a reactive effect on
	some SwiftUI views that involve the item's associated location.
	
	the same is true for Locations.  changing an attribute of a Location directly may at
	times require triggering a SwiftUI reaction involving the items associated with the Location.
	
	example: the ShoppingListTabView creates SelectableItemRowView structs for SwiftUI, and
	each displays information about an item, including the associated location's name.  we
	get the location's name using a computed property on Item that cleanly nil-coalesces the value.
	
	importantly, these SelectableItemRowView views are routinely created and destroyed, and they
	will (only) get redrawn if the @FetchRequest that drives the ShoppingListTabView gets an
	objectWillChange.send() from an Item.
	
	here, then, is the problem: if you change a Location's name, the locationName computed
	property of each associated Item now has been updated and those SelectableItemRowViews
	must get redrawn.  so each item associated with the location must generate an
	objectWillChange.send() message.  (in fact, i think only one item need to do this ...)
	
	also, think what happens when you change a location's visitationOrder.  potentially, that
	causes the entire ShoppingListTabView to restructure itself; that won't happen unless
	changing a location's visitationOrder also generates some item.objectWillChange.send().
	
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
	// know that some of their computed properties might be invalidated
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
		// if we are currently associated with a Location, then set new location
		// (which breaks the previous association of this Item with a location)
		// note: the associated Location(s) may want to know about a change
		// in one of its items, since there are computed properties on Location
		// such as the number of items that will be invalidated
		location_?.objectWillChange.send()
		location_ = editableData.location
		location_?.objectWillChange.send()
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

