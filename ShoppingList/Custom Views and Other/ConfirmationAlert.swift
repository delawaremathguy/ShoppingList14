//
//  ConfirmationAlert.swift
//  ShoppingList
//
//  Created by Jerry on 12/16/20.
//  Copyright © 2020 Jerry. All rights reserved.
//


import SwiftUI

// this is a struct to centralize the data needed to run the confirmation alerts
// that i use whenever the user want to perform a destructive action, in these cases:
//
// (1) move all items off the list in the ShoppingListTabView (a user might touch
// this button accidentally and lose the whole shopping list)
//
// (2) delete an item (in either the ShoppingListTabView or the PurchasedItemsTabView)
//
// (3) delete a location (in the LocationsTabView)
//
// on this case-by-case basis, we provide an appropriate Alert struct with the
// proper messages and execute the apporpriate destructive action when the user
// confirms the action.

struct ConfirmationAlert {
	
	enum ConfirmationAlertType {
		// an appropriate default, but it should never trigger
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
	var type: ConfirmationAlertType
	
	// whether the Alert we provide is showing, i.e., its boolean-valued trigger.
	// .alert always uses such a boolean
	var isShowing: Bool = false
	
	// and a completion handler for after we do what we do. the AddOrModify views
	// need this so they can run the alert, delete an Item or Location, and then
	// follow that by dismissing themselves after executing the deletion
	var completion: (() -> ())?
	
	// once the user wants to perform a destructive action, just call the trigger function,
	// setting its type (and any necessary associated data) and perhaps tacking on an
	// optional completion handler, depending on the call site
	mutating func trigger(type: ConfirmationAlertType, completion: (() -> ())? = nil) {
		self.type = type
		self.completion = completion
		isShowing = true // this starts the SwiftUI chain of events to show the alert
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
				return "Are you sure you want to delete the Item named \'\(item.name)\'? This action cannot be undone"
			case .deleteLocation(let location):
				return "Are you sure you want to delete the Location named \'\(location.name)\'? This action cannot be undone"
		}
	}
	
	// what to do after the user confirms the destructive action should be performed
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

