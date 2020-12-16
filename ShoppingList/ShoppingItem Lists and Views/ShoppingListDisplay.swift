//
//  ShoppingListDisplay.swift
//  ShoppingList
//
//  Created by Jerry on 11/30/20.
//  Copyright © 2020 Jerry. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - A Generic SectionData struct

// in a sectioned data display, one consisting of sections and with each section being
// itself a list, you usually work with a structure that looks like this:
//
// List {
//   ForEach(sections) { section in
//     Section(header: Text("title for this section")) {
//	     ForEach(section.items) { item in
//         // display the item for this row in this section
//       }
//     }
//   }
// }
//
// so the notion of this struct is that we use it to say what to draw in each
// section: its title and an array of items to show in the section.  then, just
// rearrange your data as a [SectionData] and "plug it in" to the structure
// above.

struct SectionData: Identifiable, Hashable {
	var id: Int { hashValue }
	let title: String
	let items: [Item]
}

// MARK: - ShoppingListView

// this is a subview of the ShoppingListTabView and shows itemsToBePurchased
// as either a single section or as multiple sections, one section for each Location.
// it uses a somewhat intricate, but standard,Form/ForEach/Section/ForEach construct
// to present the list in sections and requires some preliminary work to perform the
// sectioning.
//
// each item that appears has a NavigationLink to a detail view and a contextMenu
// associated with it; actions from the contextMenu may require bringing up an alert,
// but we will not do that here in this view.  we will simply set @Binding variables
// from the parent view appropriately and let the parent deal with it (e.g., because
// the parent uses the same structure to present an alert already to move all items
// of the list).
struct ShoppingListView: View {
	
	// this is the @FetchRequest that ties this view to CoreData Items.
	// comment: this is a subview of the parent ShoppingListTabView, which
	// already has its own @FetchRequest to drive that view.  we could "pass"
	// that into this subview, but there are some syntax subtleties; plus, it's
	// easier to just think of this as a view that takes care of itself, except for
	// having the two @Binding hooks back to the main view.
	@FetchRequest(fetchRequest: Item.fetchAllItems(onList: true))
	private var itemsToBePurchased: FetchedResults<Item>

	// display format: one big section of Items, or sectioned by Location?
	// (not sure we need a Binding here ... we only read the value)
	@Binding var multiSectionDisplay: Bool
	
	// state variables to control showing confirmation of a delete, which is
	// one of three context menu actions that can be applied to an item
//	@Binding var isConfirmationAlertShowing: Bool
//	@Binding var itemToDelete: Item?
	
	// state variable to control triggering confirmation of a delete, which is
	// one of three context menu actions that can be applied to an item
	@Binding var confirmationTrigger: ConfirmationTrigger
	
	// this is a temporary holding array for items being moved to the other list.  it's a
	// @State variable, so if any SelectableItemRowView or a context menu adds an Item
	// to this array, we will get some redrawing + animation; and we'll also have queued
	// the actual execution of the move to the purchased list to follow after the animation
	// completes -- and that deletion will again change this array and redraw.
	@State private var itemsChecked = [Item]()
	
	var body: some View {
		Form {
			ForEach(sectionData()) { section in
				Section(header: Text(section.title).sectionHeader()) {
					// display items in this location
					ForEach(section.items) { item in
						// display a single row here for 'item'
						NavigationLink(destination: AddorModifyItemView(editableItem: item)) {
							SelectableItemRowView(rowData: SelectableItemRowData(item: item),
																		selected: itemsChecked.contains(item),
																		sfSymbolName: "purchased",
																		respondToTapOnSelector:  { handleItemTapped(item) })
								.contextMenu {
									itemContextMenu(item: item, deletionTrigger: {
										confirmationTrigger.trigger(type: .deleteItem(item))
									})
								} // end of contextMenu
						} // end of NavigationLink
					} // end of ForEach
				} // end of Section
			} // end of ForEach
		}  // end of Form
	} // end of body: some View
	
	// the purpose of this function is to break out the itemsToBePurchased by section,
	// according to whether the list is displayed as a single section or in multiple
	// sections (one for each Location that contains shopping items on the list)
	func sectionData() -> [SectionData] {
		
		// the easy case first: one section with a title and all the items.
		if !multiSectionDisplay {
			return [SectionData(title: "Items Remaining: \(itemsToBePurchased.count)",
													items: itemsToBePurchased.sorted(by: { $0.visitationOrder < $1.visitationOrder }))
			]
		}
		
		// for a multi-section list, break out all the items into a dictionary
		// with Locations as the keys.
		let dict = Dictionary(grouping: itemsToBePurchased, by: { $0.location })
		// now assemble the data by location visitationOrder
		var completedSectionData = [SectionData]()
		for key in dict.keys.sorted() { // sorted by Location is, of course, by visitationOrder
			completedSectionData.append(SectionData(title: key.name, items: dict[key]!))
		}
		return completedSectionData
	}
	
	func handleItemTapped(_ item: Item) {
		if !itemsChecked.contains(item) {
			// put the item into our list of what's about to be removed, and because
			// itemsChecked is a @State variable, we will see a momentary
			// animation showing the change.
			itemsChecked.append(item)
			// and we queue the actual removal long enough to allow animation to finish
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.40) {
				item.toggleOnListStatus()
				itemsChecked.removeAll(where: { $0 == item })
			}
		}
	}
	
}
