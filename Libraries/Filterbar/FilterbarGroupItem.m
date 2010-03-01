#include "FilterbarGroupItem.h"
#import "FilterbarGroup.h"

@implementation FilterbarGroupItem

@synthesize itemId = _itemId;
@synthesize width = _itemWidth;

#pragma mark -
#pragma mark Initializing Filterbar Group

- (id)initWithId:(NSString *)itemId
         caption:(NSString *)caption
            icon:(NSImage *)icon
{
	if ((self = [super init])) {
		_caption = [caption retain];
		_itemWidth = 0.0;
		_itemId = [itemId retain];
		_icon = [icon retain];

		/* Setup Default Icon Size */
		if (_icon != nil) 
			[_icon setSize:NSMakeSize(16.0, 16.0)];
	}

	return self;
}

- (void)dealloc {
	[_caption release];
	[_itemId release];
	[_icon release];

	[super dealloc];
}

#pragma mark -
#pragma mark Create Button/MenuItem Utils

- (NSButton *)createButton:(NSInteger)state group:(FilterbarGroup *)group {
	NSButton *button = [[NSButton alloc] init];

	[[button cell] setHighlightsBy:(NSCellIsBordered | NSCellIsInsetButton)];
	[[button cell] setRepresentedObject:_itemId];

	[button setShowsBorderOnlyWhileMouseInside:YES];
	[button setButtonType:NSPushOnPushOffButton];
	[button setBezelStyle:NSRecessedBezelStyle];
	[button setImagePosition:NSImageLeft];
	[button setFont:[NSFont boldSystemFontOfSize:11.0]];
	[[button cell] setControlSize:NSSmallControlSize];
	[button setTitle:_caption];
	[button setImage:_icon];
	[button setState:state];

	[button setAction:@selector(filterButtonClicked:)];
	[button setTarget:group];

	[button sizeToFit];
	_itemWidth = [button frame].size.width;

	return button;
}

- (NSMenuItem *)createMenuItem:(NSInteger)state group:(FilterbarGroup *)group {
	NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:_caption
                                                      action:NULL
                                               keyEquivalent:@""];
	[menuItem setRepresentedObject:_itemId];
	[menuItem setImage:_icon];
	[menuItem setState:state];

	[menuItem setAction:@selector(filterButtonClicked:)];
	[menuItem setTarget:group];

	return menuItem;
}

@end

