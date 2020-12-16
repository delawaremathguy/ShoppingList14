//
//  ConfirmationTrigger.swift
//  ShoppingList
//
//  Created by Jerry on 12/16/20.
//  Copyright © 2020 Jerry. All rights reserved.
//


import SwiftUI

// this is a struct to centralize the data needed to run the confirmation alert
// that we use to confirm that the user intends to
//
// (1) move all items off the list in the ShoppingListTabView (they might hit
// this button accidentally and lose the whole shopping list) or
//
// (2) delete an item (in either the ShoppingListTabView or the PurchasedItemsTabView) or
//
// (3) delete a location (in the LocationsTabView)
//
// on this case-by-case basis, we provide an appropriate Alert struct with the
// proper messages and execute the apporpriate destructive action when the user
// confirms the action.

struct ConfirmationTrigger {
	
	enum AlertType {
		// an appropriate default that does nothing
		case none
		// the ShoppingListTabView needs this type
		case moveAllOffShoppingList
		// the ShoppingListTabView, PurchasedItemsTabView, and AddOrModifyItemView
		// need this type, along with the item to delete
		case deleteItem(Item)
		// the LocationsTabView and AddOrModifyLocationView
		// need this type, along with the location to delete
		case deleteLocation(Location)
	}
	
	// the type of this confirmation alert
	var type: AlertType
	// its boolean-valued trigger, since .alert wants such a boolean
	var isAlertShowing: Bool = false
	// and completion handler once we do what we do; the AddOrModify views want
	// this so they can run the alert, delete an Item or Location, and then
	// dismiss themseles after the deletion
	var completion: (() -> ())?
	
	// once the user says "delete this Item," just call the trigger function, setting
	// its type (and any necessary associated data) and adding an optional completion
	// handler, depending on the call site
	mutating func trigger(type: AlertType, completion: (() -> ())? = nil) {
		self.type = type
		self.completion = completion
		isAlertShowing = true // this starts the SwiftUI chain of events to show the alert
	}
	
	// strings to pass along to an alert when it comes up, depending on type
	func title() -> String {
		switch type {
			case .none:
				return ""
			case .moveAllOffShoppingList:
				return "Move All Items Off-List"
			case .deleteItem(let item):
				return "Delete \'\(item.name)\'?"
			case .deleteLocation(let location):
				return "Delete \'\(location.name)\'?"
		}
	}
	
	func message() -> String {
		switch type {
			case .none, .moveAllOffShoppingList:
				return ""
			case .deleteItem(let item):
				return "Are you sure you want to delete \'\(item.name)\'? This action cannot be undone"
			case .deleteLocation(let location):
				return "Are you sure you want to delete \'\(location.name)\'? This action cannot be undone"
		}
	}
	
	// what to do after the user confirms the destructive action
	func destructiveAction() {
		switch type {
			case .none: // should never really be called
				break
			case .moveAllOffShoppingList:
				Item.moveAllItemsOffShoppingList()
			case .deleteItem(let item):
				Item.delete(item)
			case .deleteLocation(let location):
				Location.delete(location)
		}
		// perform any completion once the destructive action is performed that would
		// make sense at the call site, such as dismissing a view (see AddOrModify views)
		completion?()
	}
	
	// this provides the Alert struct for the .alert() modifier.
	func alert() -> Alert {
		Alert(title: Text(title()),
					message: Text(message()),
					primaryButton: .cancel(Text("No")),
					secondaryButton: .destructive(Text("Yes"), action: destructiveAction)
		)
	}
}

