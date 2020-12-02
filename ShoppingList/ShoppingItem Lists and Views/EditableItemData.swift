//
//  EditableItemData.swift
//  ShoppingList
//
//  Created by Jerry on 6/28/20.
//  Copyright © 2020 Jerry. All rights reserved.
//

import Foundation

// this gives me a way to collect all the data for an Item that i might want
// to edit.  it defaults to having values appropriate for a new item upon
// creation, or can be initialized from a Item.  this is something
// i can then hand off to an edit view.  at some point, that edit view will
// want to update an Item with this data, so we also provide an extension
// on Item to copy this data back to a Item.

struct EditableItemData {
	// the id of the Item, if any, associated with this data collection
	// (nil if data for a new item that does not yet exist)
	var id: UUID? = nil
	// all of the values here provide suitable defaults for a new item
	var name: String = ""
	var quantity: Int = 1
	var location = Location.unknownLocation()!
	var onList: Bool = true
	var isAvailable = true
	var dateText = "" // for display only, not actually editable
	
	// this copies all the editable data from an incoming Item.  this looks fairly
	// benign, but its in the lines below that crashes did/could occur in earlier versions
	// because of the main, underlying problem: if an item is deleted somewhere outside
	// a view showing a list of items, the list view may wind up calling this with an item
	// that's a zombie: the data behind it has been deleted, but it could still be present
	// as a fault in Core Data.  i still don't quite get this -- it's something to do
	// with how SwiftUI updates views and its interaction with a @FetchRequest.  this is the
	// one, remaining issue with SwiftUI i hope to understand real soon.
	init(item: Item) {
		id = item.id
		name = item.name
		quantity = Int(item.quantity)
		location = item.location
		onList = item.onList
		isAvailable = item.isAvailable
		if item.hasBeenPurchased {
			dateText = item.dateLastPurchased.dateText(style: .medium)
		}
	}
	
	// provides init for a new Item -- makes sure it will go to shopping list by default
	init() {
		self.onList = true
	}
	
	var canBeSaved: Bool { name.count > 0 }
}
