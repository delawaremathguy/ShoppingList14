//
//  ShoppingItemRowView.swift
//  ShoppingList
//
//  Created by Jerry on 5/14/20.
//  Copyright © 2020 Jerry. All rights reserved.
//

import SwiftUI

// DEVELOPMENT COMMENT

// this is a display-only view.  yet this one small View was the source of repeated
// problems for some time. my natural tendency was to "pass in" the ShoppingItem
// whose data was displayed in one row of a List, and then read the fields of the
// ShoppingItem directly when drawing out the text fields.

// however, this introduced a problem: if a ShoppingItem was edited somewhere
// else in the code, these changes were not really being propagated back here by the
// List/ForEach.  that seemed counter-intuitive: the List obviously set up this View with
// a dependency on a ShoppingItem, didn't it?  wouldn't that force this
// to be redrawn when the parent view was redrawn? apparently, it did not.
// i think the reason is that SwiftUI only noticed that the list of items still
// looked to be the same ... it was driven by ForEach(shoppingItems) and did not
// really see changes to the fields of the item.

// so to make this "work," i next passed in a ShoppingItem as an @ObservedObject.
// updates will be handled correctly.  but then we have other problems.
// if this ShoppingItem is deleted elsewhere in the app, this View was still
// holding a reference to the ShoppingItem and, depending upon certain timing conditions
// that i think are related to having used @FetchRequest, would cause a crash: because the
// shopping item reference became meaningless (it was still a Core Data reference
// to something that was deleted in Core Data terms, but not yet saved out to disk
// -- i.e., a fault for which .isDeleted is/maybe true and .isFault is true).
// so you could no longer refer to the shopping item's name (which was a forced-unwrap,
// which would try to load that data and go BOOM) or even reliably refer to the item's quantity
// (a non-optional Int32).

// so some re-thinking forced me into this little trickery below, to pass in the values
// of an item from the List/ForEach construct for this View for display, using a custon struct.
// and now this works fine, although even here, i'm not convinced it should. apparently this
// syntax is enough for the List/ForEach to do the right thing for updates.

// finally, one curiosity is that if you make `var itemData: ShoppingItemRowData` into
// `@State var itemData: ShoppingItemRowData`, this view will NOT update correctly, for
// the simple reason that by setting @State, this SwiftUI view takes full ownership.  nothing outside
// can reset it (e.g., running the body property that makes the list won't reset the
// property, even though it looks like it should), and nothing inside the view changes it,
// so you're stuck with this view until the view finally disappears.

struct ShoppingItemRowData {
	var isAvailable: Bool = true
	var name: String = ""
	var locationName: String = ""
	var quantity: Int32 = 0
	var showLocation: Bool = true	// whether this is a two-line display, with location as secondary line
	var uiColor = UIColor()
	
	init(item: ShoppingItem, showLocation: Bool = true) {
		// note on init: because objects come out of Core Data, there have been times in development
		// where the List code seems to say that a Core Data item that's been/is being deleted is still
		// sort of there: it shows up as an item with item.isDeleted = false, but item.isFault = true
		// and that means that it cannot find its optional name string, or its location.  so the
		// code below just protects against that in case it ever shows up again -- although i have not
		// seen this with XCode 11.6/iOS 13.6 anytime recently.
		
		// nevertheless, even if it's not happening anymore, you should know that the funny thing is,
		// it almost never happened except for when the very last item remaining in the ShoppingList
		// is deleted; and in some cases, because of the nil-coalescing code below, you could actually
		// see the name of the item being changed to "Item being deleted" before it disappeared.
		// again, in XCode 11.6, i have not seen this; but the underlying problem seems to remain
		// in XCode 12 beta4, despite the fact that i have removed all use of @FetchRequest coding
		// and implemented my own viewModels as a replacement.  i think it's all about timing of
		// when SwiftUI and Core Data do their things; and it's clear that XCode 12 beta4 and
		// SwiftUI 2 handles the timing correctly
		// of when Views are created and destroyed much differently than XCode 11.6 and SwiftUI 1 did.
		
		// so the nil-coalescing below is built-in protection for any such case.  it appears you
		// really do need this protection in XCode 12 beta 4.  bottom line: i am not going to
		// fight with this anymore -- i'll just go with the flow for now.
		isAvailable = item.isAvailable
		name = item.name
		locationName = item.location?.name ?? "Some Location"
		quantity = item.quantity
		self.showLocation = showLocation
		uiColor = item.backgroundColor
	}
	
	init() { } // syntax necessity, although all values are reasonable setd
	
}

// shows one line in a list for a shopping item.  pass in the data to be shown.
struct ShoppingItemRowView: View {
	
	var itemData: ShoppingItemRowData
	
	var body: some View {
		HStack {
			// color bar at left (new in this code)
			Color(itemData.uiColor)
				.frame(width: 10, height: 36)
			
			VStack(alignment: .leading) {
				
				if itemData.isAvailable {
					Text(itemData.name)
				} else {
					Text(itemData.name)
						.font(.body)
						.overlay(Rectangle().frame(height: 1.0))
				}
				
				if itemData.showLocation {
					Text(itemData.locationName)
						.font(.caption)
						.foregroundColor(.secondary)
				}
			}
			
			Spacer()
			
			Text("\(itemData.quantity)")
				.font(.headline)
				.foregroundColor(Color.blue)
			
		} // end of HStack
	}

}

