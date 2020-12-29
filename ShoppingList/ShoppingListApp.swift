//
//  ShoppingListApp.swift
//  ShoppingList
//
//  Created by Jerry on 11/19/20.
//  Copyright © 2020 Jerry. All rights reserved.
//

import Foundation
import SwiftUI

// the app will hold a variable of type Today, which keeps track of the "start of
// today."  the PurchasedItemsTabView needs to know what "today" means to properly
// section out its data, and it would seem to make sense that the PurchasedItemsTabView
// should handle that by itself.  however, if you push the app into the background
// when the PurchasedItemsTabView is showing and then bring it back a few days later,
// the PurchasedItemsTabView will show the same display as when it went into the background
// and not know about the change; so its view will need to be updated.  that's why
// this is here: the app certainly knows when it becomes active, and so can update what
// "today" means, and the PurchasedItemsTabView will pick up on that in its environment
class Today: ObservableObject {
	@Published var start: Date = Calendar.current.startOfDay(for: Date())
	func update() {
		let newStart = Calendar.current.startOfDay(for: Date())
		if newStart != start {
			start = newStart
		}
	}
}

// this is (approximately) the new App structure for iOS 14 that's been
// cobbled together based on comments on the Apple Developer Forums
// see https://developer.apple.com/forums/thread/650876
// and although i have left the old AppDelegate and SceneDelegate
// files in the project, i have removed them from the project.

@main
struct ShoppingListApp: App {
	
	@Environment(\.scenePhase) private var scenePhase
	@StateObject var persistentStore = PersistentStore.shared
	@StateObject var today = Today()
	
	var body: some Scene {
		// always be sure to have an unknown location; if not, then this will
		// initialize the persistent store
		if Location.unknownLocation() == nil {
			Location.createUnknownLocation()
			Location.saveChanges()
		}

		return WindowGroup {
			MainView()
				.environment(\.managedObjectContext, persistentStore.context)
				.environmentObject(today)
		}
		.onChange(of: scenePhase) { phase in
			switch phase {
				
				case .active:
					today.update() // we might become active on a different day ...
					if gInStoreTimer.isSuspended {
						gInStoreTimer.start()
					}
					
				case .inactive:
					break
					
				case .background:
					if kDisableTimerWhenAppIsNotActive {
						gInStoreTimer.suspend()
					}
					persistentStore.saveContext()
					
				@unknown default:
					fatalError("fatal error for .onChange modifier")
			}
		}
		
	}
}
