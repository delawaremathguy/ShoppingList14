#  About "ShoppingList14"

This is a simple, iOS project to process a shopping list that you can take to the grocery store with you, and move items off the list as you pick them up.  It persists data in CoreData.  The project should be compiled with XCode 12.2 or later to run on iOS14.2 or later.

* An [earlier version of this project](https://github.com/delawaremathguy/ShoppingList) is available that works with **XCode 11.7/iOS 13.7**.  If you have not yet made the move to XCode 12.2 and iOS 14.2, you should use this earlier project instead.

Feel free to use this as is, to develop further,  to completely ignore, or even just to inspect and then send me a note to tell me I am doing this all wrong.  


## First Public Update for iOS 14: November, 2020


Now that XCode 12 has finally stabilized, I feel it safe to make some refinements and possibly use features of iOS 14 in this project.  This repository has been put together using XCode 12.2 (release version) and is intended to run under iOS 14.2 

Please be sure to read the What's New in ShoppingList14 section below, primarily for implementation and code-level changes.




## General App Structure

 ![](Screenshot1.jpg)  ![](Screenshot2.jpg) 


 ![](Screenshot3.jpg)  ![](Screenshot4.jpg) 

The main screen is a TabView, to show 
* a current shopping list, 
* a (searchable) list of previously purchased items, 
* a list of "locations" in a store, such as "Dairy," "Fruits & Vegetables," "Deli," and so forth, 
* an in-store timer, to track how long it takes you to complete shopping, and
* optionally, for purposes of demonstration, a "Dev Tools" tab to make wholesale adjustments to the data and the shopping list display.

The CoreData model has only two entities named "ShoppingItem" and "Location," with every ShoppingItem having a to-one relationship to a Location (the inverse is to-many).

* `ShoppingItem`s have an id (UUID), a name, a quantity, a boolean "onList" that indicates whether the item is on the list for today's shopping exercise, or not on the list (and so available in the purchased list for future promotion to the shopping list), and also an "isAvailable" boolean that provides a strike-through appearance for the item when false (sometimes an item is on the list, but not available today, and I want to remember that when planning the future shopping list).  New to this project is the addition of a dateLastPurchsed for a ShoppingItem.

* `Location`s have an id (UUID), a name, a visitationOrder (an integer, as in, go to the dairy first, then the deli, then the canned vegetables, etc), and then values red, green, blue, opacity to define a color that is used to color every item listed in the shopping list. 

For the first two tabs, tapping on the circular button on the leading edge moves a shopping item from one list to the other list (from "on the list" to "purchased" and vice-versa).  

Tapping on any item (*not the leading circular button*) in either list lets you edit it for name, quantity, assign/edit the store location in which it is found, or even delete the item.  Long pressing on an item gives you a contextMenu to let you move items between lists, toggle between the item being available and not available, or directly delete the item.

The shopping list is sorted by the visitation order of the location in which it is found (and then alphabetically within each Location).  Items in the shopping list cannot be otherwise re-ordered, although all items in the same Location have the same color as a form of grouping.  Tapping on the leading icon in the navigation bar will toggle the display from a simple, one-section list, to a multi-section list.


The third tab shows a list of all locations, listed in visitationOrder (an integer from 1...100).  One special Location is the "Unknown Location," which serves as the default location for all new items.  I use this special location to mean that "I don't really know where this item is yet, but I'll figure it out at the store." In programming terms, this location has the highest of all visitationOrder values, so that it comes last in the list of Locations, and shopping items with this unassigned/unknown location will come at the bottom of the shopping list. 

Tapping on a Location in the list lets you edit location information, including reassigning the visitation order, change its color, or delete it.  (Individually adjusting RGB and Alpha may not the best UI in this app, but it will have to do for now.  Also, using color to distinguish different Locations may not even be a good UI, since a significant portion of users either cannot distinguish color or cannot choose visually compatible colors very well.)  You will also see a list of the ShoppingItems that are associated with this Location. A long press on a location (other than the "unknown location") will allow you to delete the location directly.

* What happens to ShoppingItems in a Location when the Location is deleted?  The ShoppingItems are not deleted, but are moved to the Unknown Location.

The fourth tab is an in-store timer, with three simple button controls: "Start," "Stop," and "Reset."  This timer can be (optionally) paused when the app goes inactive (e.g., if you get a phone call while you're shopping), although the default is to *not* pause it when going inactive. (*See Development.swift to change this behaviour*.)

Finally, there is a  tab for "development-only" purposes, that allows wholesale loading of sample data, removal of all data, and offloading data for later use. This tab should not appear in any production version of the app (*see Development.swift to hide this*).

So, 

* **If you plan to use this app**, the app will start with an empty shopping list and an almost-empty location list (it will contain the special "Unknown Location"); from there you can create your own shopping items and locations associated with those items.  

* **If you plan to play with or just test out this app**, go straight to the Dev Tools tab and tap the "Load Sample Data" button.  Now you can play with the app, and eventually delete the data (also from the Dev Tools tab) when you're finished.

## What's New in ShoppingList14

Things have changed [since the previous release of this project](https://github.com/delawaremathguy/ShoppingList) for XCode 11 that was titled, simply, **ShoppingList**.  Although this project is called "ShoppingList14," it retains the same signature as the previous project; and despite some changes to the Core Data model, *should* properly migrate data from the earlier project to the new model of this project -- however, I *cannot guarantee this based on my own experience*.

Here are some of those code-level changes:

* The AppDelegate-SceneDelegate application structure has been replaced by the more simplified App-Scene-WindowGroup structure introduced for XCode 12/iOS 14.
* The three primary tabs (Shopping List, Purchased, and Locations) now use a Form presentation, rather than a List presentation.
* Each ShoppingItem now has a "dateLastPurchased" property which is reset to "today" whenever you move an item off the shopping list.
* The Purchased items tab has been slightly re-worked so that shopping items that were purchased "today" appear in the first section of the list.  This makes it easy to review the list of today's purchases, and to quickly locate any item that you may have accidentally tapped off the Shopping List so you can put it back on the list.
* Many code changes have been made or simplified and comments throughout the code. 
* The basic architecture of the app has been simplified.  What started out as more of an MVVM-style architecture has morphed into a hybrid style:

- Views can effect changes to ShoppingItems by calling ShoppingItem functions directly ("user intents"), which then are handled appropriately in the ShoppingItem class, and for which notifications are then posted as to what happened. 
- There is no longer a LocationsListViewModel.  The LocationsTabView is such a simple view that it is now driven by a @Fetchrequest.
- The ShoppingListViewModel has now become exclusively an array manager that serves only the functions that the @FetchRequest it replaces would handle, and does not carry out user-intent requests. 


## App Architecture Comment

Despite this app starting off with some simple @FetchRequest definitions and making some lists, this version makes no direct use of @FetchRequest or even Combine. I have *gone completely old-school*, just like I would have built this app using UIKit, before there was SwiftUI and Combine. 

* I post internal notifications through the NotificationCenter that a `ShoppingItem` or a `Location` has either been created, or edited, or is about to be deleted.  (Remember, notifications are essentially a form of using the more general Combine framework.) Every view model loads its data only once from Core Data and signs up for appropriate notifications to stay in-sync without additional fetches from Core Data.  Each view model can then react accordingly, alerting SwiftUI so that the associated View needs to be updated.  This design suits my needs, but may not be necessary for your own projects, for which straightforward use of @FetchRequest might well be sufficient.




## Future Work

Although this is the last, public release of the project, there are many directions to move with this code.

* I'd like to look at CloudKit support for the database for my own use, although such a development  could return to public view if I run into trouble and have to ask for help.  The general theory is that you just replace NSPersistentContainer with NSPersistentCloudkitContainer, flip a few switches in the project, add the right entitlements, and off you go. *I doubt that is truly the case*, and certainly there will be a collection of new issues that arise.

* I should invest a little time with iPadOS.  Unfortunately, my iPad 2 is stuck in iOS 9, so it's not important to me right now.  As a future option, though -- even though you probably don't want to drag an iPad around in the store with you -- you might want to use it to update the day's shopping list and then, via the cloud, have those changes show up on your phone to use in-store.

*  I still get console messages at runtime about tables laying out outside the view hierarchy, and one that's come up recently of "Trying to pop to a missing destination." I see fewer of these messages in XCode 11.7.  When using contextMenus, I get a plenty of "Unable to simultaneously satisfy constraints" messages.  I'm ignoring them for now, and I have already seen fewer or none of these in testing out XCode 12 (through beta 6). 


* I have thought about expanding the app and database to support multiple "Stores," each of which has "Locations," and having "ShoppingItems" being many-to-many with Locations so one item can be available in many Stores would be a nice exercise. But I have worked with Core Data several times, and I don't see that I gain anything more in the way of learning about SwiftUI by doing this, so I doubt that I'll pursue this any time soon.

* I could add a printing capability, or even a general sharing capability (e.g., email the shopping list to someone else).  I did something like this in another (*UI-Kit based*) project, so it should be easy, right?  (Fact: it is easy; there are several "mail views for SwiftUI" already on Github. [This is one from Mohammad Rahchamani](https://github.com/mohammad-rahchamani/MailView) that I have tested and it works quite easily for any SwiftUI app.)


Note that I am certainly not at all interested in creating the next, killer shopping list app or moving any of this to the App Store.  *The world really does not need a new list-making app*.  
But, if you want to take this code and run with it ... go right ahead.


##  View Updating Issues

I built this project in public only as an experiment, in order to simply get a lot of practice with SwiftUI, and to look more deeply and perhaps offer some suggested code to the folks who keep running into what I call SwiftUI's **generic problem**:

> An item appears in View A; it is edited in View B (a detail view that appears either by a NavigationLink or a .sheet presentation); but its appearance in View A does not get updated properly upon return.  

SwiftUI does a lot of the updating for you automatically, but the situation is more tricky when using Core Data because the model data consists of objects (classes), not structs.  SwiftUI does provide @FetchRequest and @ObservedObject and @EnvironmentObject (and Combine if you go deeper), but the updating problem is not completely solved just by sprinkling @ObservedObject property wrappers around in your code. It also matters in SwiftUI whether you pass around structs or classes between SwiftUI Views, and exactly how you pass them.  


Indeed, the biggest issue that I found in the early days of this app involved updates following a **deletion** of a Core Data object.  My conclusion is that @FetchRequest and SwiftUI don't always interact that well with respect to deletions, and that is what drove me to the architecture and my reliance on using the NotificationCenter that you will find in the app. (*I have extensive comments in the code about the problems I faced*).


* I think that my current use of notifications and "view models" in place of @FetchRequest provides a solution to much of the **generic problem** in the distributed SwiftUI situation that occurs in *this* app.  It works for me; you must decide if any of this is something that might work for you.



## Closing

The project is what it is -- a project that began trying to learn how to use SwiftUI with a Core Data store. On a basic level, understanding the SwiftUI lifecycle of how Views come and go turned out to be a major undertaking.  On the Core Data side, using @FetchRequest was the obvious, right thing -- until it wasn't.  Then adding a few sprinkles of Combine looked like the right thing -- until it wasn't.  I learned a lot ... and that was the point of this project.


Feel free to contact me about questions and comments.


## License

* The SearchBarView in the Purchased items view was created by Simon Ng.  It appeared in [an article in AppCoda](https://www.appcoda.com/swiftui-search-bar/) and is copyright ©2020 by AppCoda. You can find it on GitHub under AppCoda/SwiftUISearchBar. 
* The app icon was created by Wes Breazell from [the Noun Project](https://thenounproject.com). 
* The extension I use on Bundle to load JSON files is due to Paul Hudson (@twostraws, [hackingwithswift.com](https://hackingwithswift.com)) 

Otherwise, almost all of the code is original,  and it's yours if you want it -- please see LICENSE for the usual details and disclaimers.

