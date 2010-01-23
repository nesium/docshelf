#include <Cocoa/Cocoa.h>

@class Filterbar;

@interface FilterbarGroup : NSObject {
	NSMutableArray *_visibleItems;
	NSMutableArray *_items;

	BOOL _hasMultiSelect;

	Filterbar *_filterBar;
	NSString *_groupId;
}

@property (readonly) NSString *identifier;

- (id)initWithId:(NSString *)groupId filterbar:(Filterbar *)filterBar;

- (NSRect)frame;
- (NSRect)frameWider;

- (BOOL)canShrink;
- (BOOL)canGrow:(CGFloat)widthToAdd;

- (void)clearData;
- (void)reloadData;

- (void)selectItem:(NSString *)itemId selected:(BOOL)selected;

- (CGFloat)grow:(CGFloat)widthToAdd;
- (CGFloat)shrink:(CGFloat)widthToRemove;

- (CGFloat)adjustSubviewsWithX:(CGFloat)x andY:(CGFloat)y widthHeight:(CGFloat)h;

- (IBAction)filterButtonClicked:(id)sender;

@end

