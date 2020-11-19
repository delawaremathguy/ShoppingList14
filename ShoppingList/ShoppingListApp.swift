//
//  ShoppingListApp.swift
//  ShoppingList
//
//  Created by Jerry on 11/19/20.
//  Copyright © 2020 Jerry. All rights reserved.
//

import Foundation
import SwiftUI

// this is (approximately) the new App structure for iOS 14 that's been
// cobbled together based on comments on the Apple Developer Forums
// see https://developer.apple.com/forums/thread/650876
// and although i have left the old AppDelegate and SceneDelegate
// files in the project, i have commented them out completely.

@main
struct ShoppingListApp: App {
	
	@Environment(\.scenePhase) private var scenePhase
	@StateObject var persistentStore = PersistentStore.shared
	
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
		}
		.onChange(of: scenePhase) { phase in
			switch phase {
				
				case .active:
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
