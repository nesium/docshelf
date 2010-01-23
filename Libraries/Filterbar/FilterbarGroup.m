#include "FilterbarGroupItem.h"
#include "FilterbarGroup.h"
#include "Filterbar.h"

#define	FILTERBAR_ITEM_SPACE	4.0

/* ======================================================================
 *  PRIVATE Methods of Filterbar
 */
@interface FilterbarGroup (FilterbarGroupPrivate)
- (void)setupDataItems:(id)delegate;
- (void)setupMultipleSelection:(id)delegate;

- (void)removeVisibleItem:(NSView *)view;
- (void)removeVisibleItemAtIndex:(NSUInteger)index;

- (void)addVisibleItem:(NSView *)view;
- (void)insertVisibleItem:(NSView *)view atIndex:(NSUInteger)index;

- (NSPopUpButton *)createPopUpButton;
- (NSPopUpButton *)getPopUpButton;
@end

@implementation FilterbarGroup

@synthesize identifier = _groupId;

#pragma mark -
#pragma mark Initializing Filterbar Group

- (id)initWithId:(NSString *)groupId filterbar:(Filterbar *)filterBar {
	if ((self = [super init])) {
		_visibleItems = [[NSMutableArray alloc] init];
		_items = [[NSMutableArray alloc] init];
		_filterBar = filterBar;
		_hasMultiSelect = NO;
		_groupId = groupId;
	}

	return self;
}

- (void)dealloc {
	[self clearData];

	[_visibleItems release];	
	[_groupId release];	
	[_items release];

	[super dealloc];
}

#pragma mark -
#pragma mark Can Resize Properties

- (BOOL)canShrink {
	return([_items count] > 1 && ([_visibleItems count] - 1) > 0);
}

- (BOOL)canGrow:(CGFloat)widthToAdd {
	NSUInteger numOfVisibleItems = [_visibleItems count];
	if (numOfVisibleItems == [_items count])
		return NO;

	CGFloat itemWidth = [[_items objectAtIndex:numOfVisibleItems] width];
	return((itemWidth + FILTERBAR_ITEM_SPACE) <= widthToAdd);
}

#pragma mark -
#pragma mark Load/Unload Group Data

- (void)clearData {
	NSUInteger subviewCount = [_visibleItems count];

	while (subviewCount-- > 0) {
		NSView *view = [_visibleItems lastObject];
		[_visibleItems removeLastObject];
		
		[view removeFromSuperview];
		[view release];
	}

	[_items removeAllObjects];
}

- (void)reloadData {
	[self clearData];

	/* Setup Group */
	id delegate = [_filterBar delegate];
	if (delegate == nil) return;
	
	[self setupMultipleSelection:delegate];
	[self setupDataItems:delegate];

	/* Setup Items (Wider) */
	CGFloat currentWidth = 0.0;
	for (FilterbarGroupItem *groupItem in _items) {
		NSButton *button = [groupItem createButton:NSOffState group:self];
		currentWidth += groupItem.width;

		[self addVisibleItem:button];
	}

	/* If we exceed the available width shrink the component */
	CGFloat availableWidth = [_filterBar availableWidth];
	while (availableWidth < currentWidth && [self canShrink])
		currentWidth -= [self shrink:(currentWidth - availableWidth)];
}

- (void)selectItem:(NSString *)itemId selected:(BOOL)selected {
	NSString *viewItemId;
	
	BOOL unselectAll = ((!_hasMultiSelect) && selected);
	
	for (id view in _visibleItems) {
		if ([view isKindOfClass:[NSPopUpButton class]]) {
			NSArray *itemsArray = [view itemArray];
			for (NSMenuItem *menuItem in itemsArray) {
				viewItemId = [menuItem representedObject];
				
				if ([viewItemId isEqualToString:itemId]) {
					[menuItem setState:(selected ? NSOnState : NSOffState)];
					if (!unselectAll) return;
				} else if (unselectAll) {
					[menuItem setState:NSOffState];
				}
			}
		} else {
			viewItemId = [[view cell] representedObject];
			if ([viewItemId isEqualToString:itemId]) {
				[view setState:(selected ? NSOnState : NSOffState)];
				if (!unselectAll) return;				
			} else if (unselectAll) {
				[view setState:NSOffState];
			}
		}
	}
}

#pragma mark -
#pragma mark Group Size

- (NSRect)frame {
	NSRect frameRect = NSMakeRect(0, 0, 0, 0);
	NSUInteger i, itemCount = [_visibleItems count];

	if (itemCount > 0) {
		NSView *item = [_visibleItems objectAtIndex:0];
		NSRect itemFrame = [item frame];
		frameRect.origin.x = itemFrame.origin.x;
		frameRect.origin.y = itemFrame.origin.y;
		frameRect.size.width = itemFrame.size.width;
		frameRect.size.height = itemFrame.size.height;

		for (i = 1; i < itemCount; ++i) {
			item = [_visibleItems objectAtIndex:i];
			itemFrame = [item frame];

			frameRect.size.width += itemFrame.size.width + FILTERBAR_ITEM_SPACE;
			if (frameRect.size.height < itemFrame.size.height)
				frameRect.size.height = itemFrame.size.height;
		}
	}

	return frameRect;
}

- (NSRect)frameWider {
	NSRect frameRect = NSMakeRect(0, 0, 0, 0);
	NSUInteger i, itemCount = [_items count];

	if (itemCount > 0) {
		NSView *item = [_visibleItems objectAtIndex:0];
		NSRect itemFrame = [item frame];
		frameRect.origin.x = itemFrame.origin.x;
		frameRect.origin.y = itemFrame.origin.y;
		frameRect.size.width = itemFrame.size.width;
		frameRect.size.height = itemFrame.size.height;

		for (i = 1; i < itemCount; ++i) {
			FilterbarGroupItem *item = [_items objectAtIndex:i];
			frameRect.size.width += item.width + FILTERBAR_ITEM_SPACE;
		}
	}

	return frameRect;
}

#pragma mark -
#pragma mark Resizing Subviews

- (CGFloat)grow:(CGFloat)widthToAdd {
	NSUInteger visibleCount = [_visibleItems count];
	NSPopUpButton *popUp = [self getPopUpButton];
	NSArray *itemArray = [popUp itemArray];
	CGFloat width = 0.0;

	if ((visibleCount + 1) == [_items count]) {
		FilterbarGroupItem *item1 = [_items objectAtIndex:(visibleCount - 1)];
		FilterbarGroupItem *item2 = [_items objectAtIndex:visibleCount];
		NSMenuItem *menu1 = [itemArray objectAtIndex:0];
		NSMenuItem *menu2 = [itemArray objectAtIndex:1];

		width = (item1.width + item2.width) - [popUp frame].size.width;

		/* Remove PopUp and Add Buttons */
		[self removeVisibleItem:popUp];
		[self insertVisibleItem:[item1 createButton:[menu1 state] group:self]
                        atIndex:(visibleCount - 1)];
		[self insertVisibleItem:[item2 createButton:[menu2 state] group:self]
                        atIndex:visibleCount];
	} else {
		FilterbarGroupItem *item = [_items objectAtIndex:(visibleCount - 1)];
		NSMenuItem *menu = [itemArray objectAtIndex:0];

		CGFloat popUpWidth = [popUp frame].size.width;

		[self insertVisibleItem:[item createButton:[menu state] group:self]
                        atIndex:(visibleCount - 1)];
		[popUp removeItemAtIndex:0];
		[popUp sizeToFit];
		[menu release];
		
		width = item.width - (popUpWidth - [popUp frame].size.width);
	}

	return(width);
}

- (CGFloat)shrink:(CGFloat)widthToRemove {
	NSUInteger visibleCount = [_visibleItems count];
	NSPopUpButton *popUp = nil;
	CGFloat width = 0.0;

	if (visibleCount == [_items count]) {
		/* Get the Two Objects */
		FilterbarGroupItem *item1 = [_items objectAtIndex:(visibleCount - 2)];
		FilterbarGroupItem *item2 = [_items objectAtIndex:(visibleCount - 1)];
		NSButton *button1 = [_visibleItems objectAtIndex:(visibleCount - 2)];
		NSButton *button2 = [_visibleItems objectAtIndex:(visibleCount - 1)];

		/* I Need to Create PopUp Button and remove two Items */
		popUp = [self createPopUpButton];
		[[popUp menu] addItem:[item1 createMenuItem:[button1 state] group:self]];
		[[popUp menu] addItem:[item2 createMenuItem:[button2 state] group:self]];
		[popUp sizeToFit];

		width = (item1.width + item2.width) - [popUp frame].size.width;

		/* Remove Buttons and Add PopUp */
		[self removeVisibleItem:button1];
		[self removeVisibleItem:button2];
		[self addVisibleItem:popUp];
	} else {
		/* I Need to Remove One Item and add to PopUp */
		FilterbarGroupItem *item = [_items objectAtIndex:(visibleCount - 2)];
		NSButton *button = [_visibleItems objectAtIndex:(visibleCount - 2)];

		/* Get PopUp take old Size and add new Item */		
		popUp = [self getPopUpButton];
		CGFloat popUpWidth = [popUp frame].size.width;
		[[popUp menu] insertItem:[item createMenuItem:[button state] group:self] atIndex:0];
		[popUp sizeToFit];

		width = item.width - (popUpWidth - [popUp frame].size.width);

		/* Remove Button */
		[self removeVisibleItem:button];
	}

	return(width);
}

#pragma mark -
#pragma mark Adjusting Subviews

- (CGFloat)adjustSubviewsWithX:(CGFloat)x andY:(CGFloat)y widthHeight:(CGFloat)h {
	CGFloat originX = x;

	for (NSView *view in _visibleItems) {
		/* Update View Position */
		NSRect viewFrame = [view frame];
		viewFrame.origin.x = x;
		viewFrame.origin.y = round((h - viewFrame.size.height) / 2.0);
		[view setFrame:viewFrame];

		/* Next Position is view.x + view.width + space */
		x += viewFrame.size.width + FILTERBAR_ITEM_SPACE;
	}

	return(x - originX);
}

- (IBAction)filterButtonClicked:(id)sender {
	BOOL selected = ([sender state] != NSOffState);
	
	/* Fix Menu Item State */
	if ([sender isKindOfClass:[NSMenuItem class]]) {
		selected = !selected;
		[sender setState:(selected ? NSOnState : NSOffState)];
	}
	
	/* If hasn't MultiSelect unset all the others. */
	if (!_hasMultiSelect && selected) {
		for (id view in _visibleItems) {
			if (view == sender) continue;
			
			if ([view isKindOfClass:[NSPopUpButton class]]) {
				NSArray *itemsArray = [view itemArray];
				for (NSMenuItem *menuItem in itemsArray) {
					if (menuItem != sender)
						[menuItem setState:NSOffState];
				}
			}
			[view setState:NSOffState];
		}
	}
	
	// Extract ItemId from sender component.
	NSString *itemId = nil;
	if ([sender isKindOfClass:[NSMenuItem class]])
		itemId = [sender representedObject];
	else
		itemId = [[sender cell] representedObject];
	
	// Call Delegate, if there's one.
	id delegate = [_filterBar delegate];
	if ([delegate respondsToSelector:@selector(filterbar:selectedStateChanged:fromItem:groupIdentifier:)])
		[delegate filterbar:_filterBar selectedStateChanged:selected fromItem:itemId groupIdentifier:_groupId];
}

/* ======================================================================
 *  Implementation of PRIVATE Methods
 */

#pragma mark -
#pragma mark Setup Group and Data

- (void)setupMultipleSelection:(id)delegate {
	_hasMultiSelect = NO;

	/* Check for Multiple Selection Selector */
	if ([delegate respondsToSelector:@selector(filterbar:hasMultipleSelection:)])
		_hasMultiSelect = [delegate filterbar:_filterBar hasMultipleSelection:_groupId];
}

- (void)setupDataItems:(id)delegate {
	NSArray *itemsIdArray = [delegate filterbar:_filterBar
								itemIdentifiersForGroup:_groupId];
	if (itemsIdArray == nil || [itemsIdArray count] == 0)
		return;

	BOOL providesImages = [delegate respondsToSelector:@selector(filterbar:imageForItemIdentifier:groupIdentifier:)];

	for (NSString *itemId in itemsIdArray) {
		NSString *caption = [delegate filterbar:_filterBar
									labelForItemIdentifier:itemId
									groupIdentifier:_groupId];

		NSImage *image = nil;
		if (providesImages) {
			image = [delegate filterbar:_filterBar
							imageForItemIdentifier:itemId
							groupIdentifier:_groupId];
		}

		FilterbarGroupItem *item = [[FilterbarGroupItem alloc] initWithId:itemId 
																caption:caption
																icon:image];
		[_items addObject:item];
		[item release];
	}
}

#pragma mark -
#pragma mark Add/Remove Subviews Utils

- (void)removeVisibleItem:(NSView *)view {
	[_visibleItems removeObject:view];
	[view removeFromSuperview];
	[view release];
}

- (void)removeVisibleItemAtIndex:(NSUInteger)index {
	NSView *view = [_visibleItems objectAtIndex:index];
	[_visibleItems removeObjectAtIndex:index];
	[view removeFromSuperview];
	[view release];
}

- (void)addVisibleItem:(NSView *)view {
	[_visibleItems addObject:view];
	[_filterBar addSubview:view];
}

- (void)insertVisibleItem:(NSView *)view atIndex:(NSUInteger)index {
	[_visibleItems insertObject:view atIndex:index];
	[_filterBar addSubview:view];
}

#pragma mark -
#pragma mark PopUp Button Related

- (NSPopUpButton *)createPopUpButton {
	NSPopUpButton *popUp = [[NSPopUpButton alloc] init];

	[[popUp cell] setHighlightsBy:(NSCellIsBordered | NSCellIsInsetButton)];
	[[popUp cell] setArrowPosition:NSPopUpArrowAtBottom];
	[[popUp cell] setAltersStateOfSelectedItem:NO];
	
	[popUp setShowsBorderOnlyWhileMouseInside:NO];
	[popUp setButtonType:NSPushOnPushOffButton];
	[popUp setBezelStyle:NSRecessedBezelStyle];
	[popUp setPreferredEdge:NSMaxXEdge];
	[popUp setPullsDown:NO];

	return [popUp retain];
}

- (NSPopUpButton *)getPopUpButton {
	id obj = [_visibleItems lastObject];
	if ([obj isKindOfClass:[NSPopUpButton class]])
		return(obj);
	return nil;
}

@end

