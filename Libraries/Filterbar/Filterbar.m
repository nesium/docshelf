#include "FilterbarGroup.h"
#include "Filterbar.h"

#define FILTERBAR_XPADDING			8.0
#define FILTERBAR_HEIGHT			25.0

#define FILTERBAR_ITEM_SPACE		4.0

/* ======================================================================
 *  PRIVATE Methods of Filterbar
 */
@interface Filterbar (FilterbarPrivate)
- (CGFloat) widerWidth;
- (CGFloat) currentWidth;

- (void)adjustSubviews;

- (void)grow:(CGFloat)widthToAdd;
- (void)shrink:(CGFloat)widthToRemove;

- (void)moveItem:(NSView *)view space:(CGFloat)space;
- (void)moveItemsFromIndex:(NSUInteger)index space:(CGFloat)space;

- (NSUInteger)indexOfGroup:(NSString *)groupId;
- (FilterbarGroup *)findGroup:(NSString *)groupId;
@end

@implementation Filterbar

@synthesize startingColor;
@synthesize endingColor;
@synthesize borderColor;
@synthesize delegate;
@synthesize angle;

#pragma mark -
#pragma mark Initializing Filterbar

- (id)initWithFrame:(NSRect)frameRect {
	if ((self = [super initWithFrame:frameRect])) {
		[self setStartingColor:[NSColor colorWithCalibratedWhite:0.75 alpha:1.0]];
		[self setEndingColor:[NSColor colorWithCalibratedWhite:0.90 alpha:1.0]];
		[self setBorderColor:[NSColor colorWithCalibratedWhite:0.69 alpha:1.0]];
		angle = 90;
		
		_items = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)dealloc {
	delegate = nil;

	[startingColor release];
	[endingColor release];
	[borderColor release];

	[self clearItems];
	[_items release];

	[super dealloc];
}

#pragma mark - 
#pragma mark - Removing Objects

- (void)clearItems {
	NSUInteger subviewCount = [_items count];

	while (subviewCount-- > 0) {
		id obj = [_items lastObject];
		[_items removeLastObject];
		
		if ([obj isKindOfClass:[NSView class]]) {
			/* This Object is a NSView */
			NSView *view = obj;
			[view removeFromSuperview];
			[view release];
		} else {
			/* This Object Is a Group */
			FilterbarGroup *group = obj;
			[group clearData];
			[group release];
		}
	}
	
	[self setNeedsDisplay:YES];
}

- (void)removeItem:(NSView *)view {
	[_items removeObject:view];
	[view removeFromSuperview];
	[view release];

	[self adjustSubviews];
	[self setNeedsDisplay:YES];
}

- (void)removeGroup:(NSString *)groupId {
	FilterbarGroup *group = [self findGroup:groupId];
	[_items removeObject:group];
	[group clearData];
	[group release];

	[self adjustSubviews];
	[self setNeedsDisplay:YES];
}

- (void)removeItemAtIndex:(NSUInteger)index {
	id obj = [_items objectAtIndex:index];
	[_items removeObjectAtIndex:index];

	if ([obj isKindOfClass:[NSView class]]) {
		/* This Object is a NSView */
		NSView *view = obj;	
		[view removeFromSuperview];
		[view release];

		[self adjustSubviews];
	} else {
		/* This Object Is a Group */
		FilterbarGroup *group = obj;
		[group clearData];
		[group release];
	}

	[self setNeedsDisplay:YES];
}

#pragma mark - 
#pragma mark - Adding Items

- (void)addItem:(NSView *)view {
	if ([view isKindOfClass:[NSControl class]] && ![view isKindOfClass:[NSImageView class]])
		[((NSControl *) view) sizeToFit];

	NSRect viewFrame = [view frame];
	id lastView = [_items lastObject];
	if (lastView != nil) {
		NSRect lastViewRect = [lastView frame];
		viewFrame.origin.x = lastViewRect.origin.x +
							 lastViewRect.size.width +
							 FILTERBAR_ITEM_SPACE;
	} else {
		viewFrame.origin.x = [self bounds].origin.x + 
							 FILTERBAR_XPADDING +
							 FILTERBAR_ITEM_SPACE ;
	}
	viewFrame.origin.y = round(([self bounds].size.height - viewFrame.size.height) / 2.0);
	[view setFrame:viewFrame];

	[_items addObject:view];
	[self addSubview:view];

	[self setNeedsDisplay:YES];
}

- (void)insertItem:(NSView *)view atIndex:(NSUInteger)index {
	if ([view isKindOfClass:[NSControl class]] && ![view isKindOfClass:[NSImageView class]])
		[((NSControl *) view) sizeToFit];

	[_items insertObject:view atIndex:index];
	[self addSubview:view];
	[self adjustSubviews];

	[self setNeedsDisplay:YES];
}

- (void)insertItems:(NSArray *)views atIndexes:(NSIndexSet *)indexes {
	NSUInteger currentIndex = [indexes firstIndex];
	NSUInteger i, count = [indexes count];

	for (i = 0; i < count; ++i) {
		[self insertItem:[views objectAtIndex:i] atIndex:currentIndex];
		currentIndex = [indexes indexGreaterThanIndex:currentIndex];
	}
}

- (void)addLabel:(NSString *)caption {
	NSTextField *field = [[NSTextField alloc] init];
	[field setStringValue:caption];
	[field setDrawsBackground:NO];
	[field setBordered:NO];
	[field setEditable:NO];
	
	[self addItem:field];
}

- (void)insertLabel:(NSString *)caption atIndex:(NSUInteger)index {
	NSTextField *field = [[NSTextField alloc] init];
	[field setStringValue:caption];
	[field setDrawsBackground:NO];
	[field setBordered:NO];
	[field setEditable:NO];
	
	[self insertItem:field atIndex:index];
}

- (void)addImage:(NSImage *)image {
	NSImageView *imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, 16.0, 16.0)];
	[imageView setImageScaling:NSScaleNone];
	[image setSize:NSMakeSize(16.0, 16.0)];
	[imageView setImage:image];
	
	[self addItem:imageView];
}

- (void)insertImage:(NSImage *)image atIndex:(NSUInteger)index {
	NSImageView *imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, 16.0, 16.0)];
	[imageView setImageScaling:NSScaleNone];
	[image setSize:NSMakeSize(16.0, 16.0)];
	[imageView setImage:image];
	
	[self insertItem:imageView atIndex:index];
}

- (void)addSeparator {
	NSBox *box = [[NSBox alloc] initWithFrame:NSMakeRect(0, 0, 1.0, 16.0)];
	[box setBoxType:NSBoxSeparator];
	
	[self addItem:box];
}

- (void)insertSeparator:(NSUInteger)index {
	NSBox *box = [[NSBox alloc] initWithFrame:NSMakeRect(0, 0, 1.0, 16.0)];
	[box setBoxType:NSBoxSeparator];	
	
	[self insertItem:box atIndex:index];
}

- (void)selectItem:(NSString *)itemId inGroup:(NSString *)groupId selected:(BOOL)selected {
	FilterbarGroup *group = [self findGroup:groupId];
	[group selectItem:itemId selected:selected];
}

- (void)selectItems:(NSArray *)itemsId inGroup:(NSString *)groupId selected:(BOOL)selected {
	FilterbarGroup *group = [self findGroup:groupId];
	for (NSString *itemId in itemsId)
		[group selectItem:itemId selected:selected];
}

#pragma mark -
#pragma mark - Adding Groups

- (void)addGroup:(NSString *)groupId {
	FilterbarGroup *group = [[FilterbarGroup alloc] initWithId:groupId
													filterbar:self];
	[_items addObject:group];
	[group reloadData];

	[self adjustSubviews];
	[self setNeedsDisplay:YES];
}

- (void)insertGroup:(NSString *)groupId atIndex:(NSUInteger)index {
	FilterbarGroup *group = [[FilterbarGroup alloc] initWithId:groupId
													filterbar:self];
	[_items insertObject:group atIndex:index];
	[group reloadData];

	[self adjustSubviews];
	[self setNeedsDisplay:YES];	
}

- (void)insertGroups:(NSArray *)groups atIndexes:(NSIndexSet *)indexes {
	NSUInteger currentIndex = [indexes firstIndex];
	NSUInteger i, count = [indexes count];

	for (i = 0; i < count; ++i) {
		FilterbarGroup *group = [[FilterbarGroup alloc] initWithId:[groups objectAtIndex:currentIndex]
													filterbar:self];
		[_items insertObject:group atIndex:currentIndex];
		[group reloadData];

		currentIndex = [indexes indexGreaterThanIndex:currentIndex];
	}

	[self adjustSubviews];
	[self setNeedsDisplay:YES];	
}

#pragma mark -
#pragma mark Resizing Subviews

- (void)resizeSubviewsWithOldSize:(NSSize)oldBoundsSize {
	[super resizeSubviewsWithOldSize:oldBoundsSize];
	
	NSUInteger currentWidth = [self currentWidth];
	NSUInteger widerWidth = [self widerWidth];
	NSSize newBoundSize = [self bounds].size;
	if (currentWidth == widerWidth && newBoundSize.width >= widerWidth)
		return;
	
	if (newBoundSize.width < oldBoundsSize.width) {
		CGFloat widthDiff = (currentWidth - newBoundSize.width);
		if (widthDiff > 0.0) [self shrink:widthDiff];
	} else {
		CGFloat widthDiff = (newBoundSize.width - currentWidth);
		if (widthDiff > 1.0) [self grow:widthDiff];
	}
}

- (void)drawRect:(NSRect)rect {
	if (endingColor == nil || [startingColor isEqual:endingColor]) {
		// Fill view with a standard background color
		[startingColor set];
		NSRectFill(rect);
	} else {
		// Fill view with a top-down gradient
		// from startingColor to endingColor
		NSGradient *gradient = [[[NSGradient alloc] initWithStartingColor:startingColor endingColor:endingColor] autorelease];
		[gradient drawInRect:[self bounds] angle:angle];
	}
	
	// Draw Border
	NSRect lineRect = [self bounds];
	lineRect.size.height = 1.0;
	[borderColor set];
	NSRectFill(lineRect);
}

/* ======================================================================
 *  Implementation of PRIVATE Methods
 */

#pragma mark -
#pragma mark Size Properties

- (CGFloat) widerWidth {
	CGFloat width = FILTERBAR_XPADDING;
	for (id obj in _items) {
		if ([obj isKindOfClass:[NSView class]])
			width += [obj frame].size.width + FILTERBAR_ITEM_SPACE;
		else
			width += [obj frameWider].size.width + FILTERBAR_ITEM_SPACE;
	}

	return(width > 0.0 ? (width - FILTERBAR_ITEM_SPACE) : 0.0);
}

- (CGFloat) currentWidth {
	if ([_items count] == 0)
		return(0.0);

	NSRect frameRect = [[_items lastObject] frame];
	return(frameRect.origin.x + frameRect.size.width);
}

- (CGFloat) availableWidth {
	[self adjustSubviews];
	return([self bounds].size.width - [self currentWidth]);
}

- (void)sizeToFit {
	NSRect frame = [self frame];
	if (frame.size.height != FILTERBAR_HEIGHT) {
		float delta = FILTERBAR_HEIGHT - frame.size.height;
		frame.size.height += delta;
		frame.origin.x -= delta;
		[self setFrame:frame];
	}
}

#pragma mark -
#pragma mark Adjusting Subviews

- (void)adjustSubviews {
	CGFloat h = [self bounds].size.height;
	CGFloat x = [self bounds].origin.x + FILTERBAR_XPADDING;
	CGFloat y = [self bounds].origin.y;

	for (id obj in _items) {
		if ([obj isKindOfClass:[NSView class]]) {
			NSView *view = obj;

			/* Update View Position */
			NSRect viewFrame = [view frame];
			viewFrame.origin.x = x;
			viewFrame.origin.y = round((h - viewFrame.size.height) / 2.0);
			[view setFrame:viewFrame];

			/* Next Position is view.x + view.width + space */
			x += viewFrame.size.width + FILTERBAR_ITEM_SPACE;
		} else {
			FilterbarGroup *group = obj;
			x += [group adjustSubviewsWithX:x andY:y widthHeight:h];
		}
	}
}

- (void)moveItem:(NSView *)view space:(CGFloat)space {
	NSRect viewRect = [view frame];
	viewRect.origin.x += space;
	[view setFrame:viewRect];
}

- (void)moveItemsFromIndex:(NSUInteger)index space:(CGFloat)space {
	NSArray *subviewArray = [self subviews];
	NSUInteger subviewCount = [subviewArray count];

	for (; index < subviewCount; ++index)
		[self moveItem:[subviewArray objectAtIndex:index] space:space];
}

#pragma mark -
#pragma mark Resizing Groups

- (void)grow:(CGFloat)widthToAdd {
	NSUInteger i, itemsCount = [_items count];
	BOOL wasModified = NO;

	for (i = 0; i < itemsCount; ++i) {
		id obj = [_items objectAtIndex:i];
		if (![obj isKindOfClass:[FilterbarGroup class]])
			continue;

		FilterbarGroup *group = obj;
		while ([group canGrow:widthToAdd]) {
			wasModified = YES;
			widthToAdd -= [group grow:widthToAdd];
			if (widthToAdd == 0)
				break;
		}
	}

	if (wasModified) {
		[self adjustSubviews];
		[self setNeedsDisplay:YES];
	}
}

- (void)shrink:(CGFloat)widthToRemove {
	NSUInteger itemsCount = [_items count];
	NSInteger i;
	BOOL wasModified = NO;

	for (i = (itemsCount - 1); i >= 0; --i) {
		id obj = [_items objectAtIndex:i];
		if (![obj isKindOfClass:[FilterbarGroup class]])
			continue;

		FilterbarGroup *group = obj;
		while ([group canShrink]) {
			wasModified = YES;
			widthToRemove -= [group shrink:widthToRemove];
			if (widthToRemove <= 0)
				break;
		}
		
		if (widthToRemove <= 0)
			break;
	}

	if (wasModified) {
		[self adjustSubviews];
		[self setNeedsDisplay:YES];
	}
}

#pragma mark -
#pragma mark Querying a Group

- (NSUInteger)indexOfGroup:(NSString *)groupId {
	NSUInteger index, itemsCount = [_items count];

	for (index = 0; index < itemsCount; ++index) {
		id obj = [_items objectAtIndex:index];
		if ([obj isKindOfClass:[FilterbarGroup class]]) {
			FilterbarGroup *group = obj;
			if ([group.identifier isEqualToString:groupId])
				return(index);
		}
	}

	return(NSNotFound);
}

- (FilterbarGroup *)findGroup:(NSString *)groupId {
	NSUInteger index, itemsCount = [_items count];

	for (index = 0; index < itemsCount; ++index) {
		id obj = [_items objectAtIndex:index];
		if ([obj isKindOfClass:[FilterbarGroup class]]) {
			FilterbarGroup *group = obj;
			if ([group.identifier isEqualToString:groupId])
				return(group);
		}
	}

	return(nil);
}

@end

