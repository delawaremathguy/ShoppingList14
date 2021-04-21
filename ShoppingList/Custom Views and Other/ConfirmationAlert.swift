//
//  ConfirmationAlert.swift
//  ShoppingList
//
//  Created by Jerry on 12/16/20.
//  Copyright © 2020 Jerry. All rights reserved.
//


import SwiftUI

// this is a struct to centralize the data needed to run the confirmation alerts
// that i use whenever the user want to perform a destructive action, for these cases:
//
// (1) move all items off the list in the ShoppingListTabView (a user might touch
// this button accidentally and lose the whole shopping list)
//
// (2) delete an item (in the ShoppingListTabView, PurchasedItemsTabView, or AddorModifyItemView)
//
// (3) delete a location (in the LocationsTabView or AddOrModifyLocationView)
//
// on this case-by-case basis, we provide an appropriate Alert struct with the
// proper messages and execute the appropriate destructive action when the user
// confirms the action.
//
// as to why i do this, throwing an Alert into a View takes up a lot of space for what should
// be boiler-plate code that can easily overwhelm your reading of the code and balancing of
// { and }.  a typical alert modifier on a View could look like this and run several lines
//
//			.alert(isPresented: $isShowing) {
//				Alert(title: Text("Delete \'\(item.name)\'?"),
//							message: Text("This could be a really long message ...."),
//							primaryButton: .cancel(Text("No")) {
//									/* this closure could do a lot of work (although in this app, No means No) */
//								},
//							secondaryButton: .destructive(Text("Yes")) {
//									/* this closure could do a lot of work */
//								}
//        )
//			}
//
// now, with the right definitions added below for messages and the destructive action, it could look like this
//
//		.alert(isPresented: $confirmationAlert.isShowing) { confirmationAlert.alert() }
//
// where you just define a state variable @State private var confirmationAlert = ConfirmationAlert(type: .none)
// and when you're ready to kick it off, you write
//
//		confirmationAlert.trigger(type: .deleteItem(item))


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
			case .none: return ""
			case .moveAllOffShoppingList: return "Move All Items Off-List"
			case .deleteItem(let item): return "Delete \'\(item.name)\'?"
			case .deleteLocation(let location): return "Delete \'\(location.name)\'?"
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
			case .none: break // should never really be called (!)
			case .moveAllOffShoppingList: Item.moveAllItemsOffShoppingList()
			case .deleteItem(let item): Item.delete(item)
			case .deleteLocation(let location): Location.delete(location)
		}
		// perform any completion once the destructive action is performed that would
		// make sense at the call site, such as dismissing a view (see AddOrModify views)
		completion?()
	}
	
	// this provides the Alert struct for the .alert() modifier.
	func alert() -> Alert {
		Alert(title: Text(title()),
					message: Text(message()),
					// to be more general, you might want to set the button names differently and allow
					// for an action on the primary button
					primaryButton: .cancel(Text("No")),
					secondaryButton: .destructive(Text("Yes"), action: destructiveAction)
		)
	}
	
}

