#include <Cocoa/Cocoa.h>

#import "FilterbarDelegate.h"

@interface Filterbar : NSView {
	@private
		IBOutlet id<FilterbarDelegate, NSObject> delegate;
		
		NSColor *startingColor;
		NSColor *endingColor;
		NSColor *borderColor;
		int angle;
  
		NSMutableArray *_items;
}

@property (nonatomic, retain) NSColor *startingColor;
@property (nonatomic, retain) NSColor *endingColor;
@property (nonatomic, retain) NSColor *borderColor;
@property (assign) id delegate;
@property (assign) int angle;

- (void)clearItems;
- (void)removeItem:(NSView *)view;
- (void)removeGroup:(NSString *)groupId;
- (void)removeItemAtIndex:(NSUInteger)index;

- (void)addItem:(NSView *)view;
- (void)insertItem:(NSView *)view atIndex:(NSUInteger)index;
- (void)insertItems:(NSArray *)views atIndexes:(NSIndexSet *)indexes;

- (void)addLabel:(NSString *)caption;
- (void)insertLabel:(NSString *)caption atIndex:(NSUInteger)index;

- (void)addImage:(NSImage *)image;
- (void)insertImage:(NSImage *)image atIndex:(NSUInteger)index;

- (void)addSeparator;
- (void)insertSeparator:(NSUInteger)index;

- (void)addGroup:(NSString *)groupId;
- (void)insertGroup:(NSString *)groupId atIndex:(NSUInteger)index;
- (void)insertGroups:(NSArray *)groups atIndexes:(NSIndexSet *)indexes;

- (void)selectItem:(NSString *)itemId inGroup:(NSString *)groupId selected:(BOOL)selected;
- (void)selectItems:(NSArray *)itemsId inGroup:(NSString *)groupId selected:(BOOL)selected;

- (CGFloat) availableWidth;

@end

