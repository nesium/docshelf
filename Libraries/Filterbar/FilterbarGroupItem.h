#include <Cocoa/Cocoa.h>

@class FilterbarGroup;

@interface FilterbarGroupItem : NSObject {
	@private
		CGFloat _itemWidth;
		NSString *_caption;
		NSString *_itemId;
		NSImage *_icon;
}

@property (readonly) NSString *itemId;
@property (readonly) CGFloat width;

- (id)initWithId:(NSString *)itemId
         caption:(NSString *)caption
            icon:(NSImage *)icon;

- (NSButton *)createButton:(NSInteger)state group:(FilterbarGroup *)group;
- (NSMenuItem *)createMenuItem:(NSInteger)state group:(FilterbarGroup *)group;

@end

